-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/team_think" )
require( GetScriptDirectory().."/hero_think" )

local utils = require( GetScriptDirectory().."/utility" )

local noneMode      = dofile( GetScriptDirectory().."/modes/none" )
local wardMode      = dofile( GetScriptDirectory().."/modes/ward" )
local shopMode      = dofile( GetScriptDirectory().."/modes/shop" )
local roamMode      = dofile( GetScriptDirectory().."/modes/roam" )
local laningMode    = dofile( GetScriptDirectory().."/modes/laning" )
local runeMode      = dofile( GetScriptDirectory().."/modes/runes" )
local jungleMode    = dofile( GetScriptDirectory().."/modes/jungling" )
local retreatMode   = dofile( GetScriptDirectory().."/modes/retreat" )
local evasionMode   = dofile( GetScriptDirectory().."/modes/evasion" )
local roshanMode    = dofile( GetScriptDirectory().."/modes/roshan" )
local shrineMode    = dofile( GetScriptDirectory().."/modes/shrine" )
local fightMode     = dofile( GetScriptDirectory().."/modes/fight" )
local pushLaneMode  = dofile( GetScriptDirectory().."/modes/pushlane" )
local defendLaneMode= dofile( GetScriptDirectory().."/modes/defendlane" )
local defendAllyMode= dofile( GetScriptDirectory().."/modes/defendally" )

local freqTeamThink = 0.25
local lastTeamThink = -1000.0

local playerAssignment = {}
local playerActionQueues = {}

local X = {}

function X.UpdatePlayerAssignment(bot, var, value)
    if var == "UseShrine" then
        -- we need to remove our hero ID from other allies that still might be wanting to use the shrine
        -- so they know when to trigger it
        local listAllies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
        for _, ally in pairs(listAllies) do
            if ally:IsBot() and not ally:IsIllusion() and playerAssignment[ally:GetPlayerID()][var] ~= nil then
                local pos = utils.PosInTable(playerAssignment[ally:GetPlayerID()][var].allies, bot:GetPlayerID())
                table.remove(playerAssignment[ally:GetPlayerID()][var].allies, pos)
            end
        end
    end

    playerAssignment[bot:GetPlayerID()][var] = value
end

function X.MainThink()
    
    -- Exercise TeamThink() at coded frequency
    if GameTime() > lastTeamThink then
        X.TeamThink()
        lastTeamThink = GameTime() + freqTeamThink
    end
    
    -- Exercise individual Hero think at every frame (if possible).
    -- HeroThink() will check assignments from TeamThink()
    -- for that individual Hero that it should perform, if any.
    return X.HeroThink()
end

function X.TeamThink()
    --utils.myPrint("TeamThink()")
    local listAllies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    for _, ally in pairs(listAllies) do
        if ally:IsBot() and (playerAssignment[ally:GetPlayerID()] == nil or not ally:IsAlive()) then
            utils.myPrint("TeamThink() - clearing playerAssignment["..ally:GetPlayerID().."]")
            playerAssignment[ally:GetPlayerID()] = {}
        end
    end

    -- This is at top as all item purchases are Immediate actions,
    -- and therefore won't affect any other decision making.
    -- Intent is to smartly determine when we should use our Glyph
    -- to protect our towers.
    team_think.ConsiderGlyphUse()
    
    -- This is at top as all item purchases are Immediate actions,
    -- and therefore won't affect any other decision making.
    -- Intent is to smartly determine which heroes should purchases
    -- Team items like Tome of Knowledge, Wards, Dust/Sentry, and
    -- even stuff like picking up Gem, Aegis, Cheese, etc.
    team_think.ConsiderTeamWideItemAcquisition(playerAssignment)

    -- This is at top as all courier actions are Immediate actions,
    -- and therefore won't affect any other decision making.
    -- Intent is to make courier use more efficient by aligning
    -- the purchases of multiple localized heroes together.
    team_think.ConsiderTeamWideCourierUse()

    -- This is a fight orchestration evaluator. It will determine,
    -- based on the global picture and location of all enemy and
    -- friendly units, whether we should pick a fight, whether in
    -- the middle of nowhere, as part of a push/defense of a lane,
    -- or even as part of an ally defense. All Heroes involved will
    -- have their actionQueues filled out by this function and
    -- their only responsibility will be to do those actions. Note,
    -- heroes with Global skills (Invoker Sun Strike, Zeus Ult, etc.)
    -- can be part of this without actually being present in the area.
    team_think.ConsiderTeamFightAssignment(playerActionQueues)
    
    -- Determine which lanes should be pushed and which Heroes should
    -- be part of the push.
    team_think.ConsiderTeamLanePush()
    
    -- Determine which lanes should be defended and which Heroes should
    -- be part of the defense.
    team_think.ConsiderTeamLaneDefense()
    
    -- Determine which hero (based on their role) should farm where. By
    -- default it is best to probably leave their default lane assignment,
    -- but if they are getting killed repeatedly we could rotate them. This
    -- also considers jungling assignments and lane rotations.
    team_think.ConsiderTeamFarmDesignation()
    
    -- Determine if we should Roshan and which Heroes should be part of it.
    team_think.ConsiderTeamRoshan()
    
    -- Determine if we should seek out a specific enemy for a kill attempt
    -- and which Heroes should be part of the kill.
    team_think.ConsiderTeamRoam()
    
    -- If we see a rune, determine if any specific Heroes should get it 
    -- (to fill a bottle for example). If not, the hero that saw it will 
    -- pick it up. Also consider obtaining Rune vision if lacking.
    team_think.ConsiderTeamRune(playerAssignment)
    
    -- If any of our Heroes needs to heal up, Shrines are an option.
    -- However, we should be smart about the use and see if any other 
    -- friends could benefit as well rather than just being selfish.
    team_think.ConsiderTeamShrine(playerAssignment)
end

function X.HeroThink()
    local bot = GetBot()
    
    --utils.myPrint("HeroThink()")
    local highestDesireValue = 0.0
    local highestDesireMode = noneMode
    
    local evaluatedDesireValue = BOT_MODE_DESIRE_NONE 
    
    -- Consider incoming projectiles or nearby AOE and if we can evade.
    -- This is of highest importance b/c if we are stunned/disabled we 
    -- cannot do any of the other actions we might be asked to perform.
    evaluatedDesireValue = hero_think.ConsiderEvading(bot)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = evasionMode
    end
    
    -- If we really want to evade ( >= 0.9 ); short-circuit 
    -- consideration of other modes for better performance.
    if evaluatedDesireValue >= BOT_MODE_DESIRE_VERYHIGH then
        return highestDesireMode, highestDesireValue
    end
    
    local nearbyEnemies     = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    local nearbyAllies      = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
    local nearbyECreeps     = bot:GetNearbyCreeps(1200, true)
    local nearbyACreeps     = bot:GetNearbyCreeps(1200, false)
    local nearbyETowers     = bot:GetNearbyTowers(750, true)
    local nearbyATowers     = bot:GetNearbyTowers(650, false)
    
    -- Fight orchestration is done at a global Team level.
    -- This just checks if we are given a fight target and a specific
    -- action queue to execute as part of the fight.
    evaluatedDesireValue = hero_think.ConsiderAttacking(bot, nearbyEnemies, nearbyAllies, nearbyETowers, nearbyATowers, nearbyECreeps, nearbyACreeps)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = fightMode
    end
    
    -- Which Heroes should be present for Shrine heal is made at Team level.
    -- This just tells us if we should be part of this event.
    evaluatedDesireValue = hero_think.ConsiderShrine(bot, playerAssignment, nearbyAllies)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = shrineMode
    end
    
    -- Determine if we should retreat. Team Fight Assignements can 
    -- over-rule our desire though. It might be more important for us to die
    -- in a fight but win the over-all battle. If no Team Fight Assignment, 
    -- then it is up to the Hero to manage their safety from global and
    -- tower/creep damage.
    evaluatedDesireValue = hero_think.ConsiderRetreating(bot, nearbyEnemies, nearbyETowers, nearbyAllies)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = retreatMode
    end
    
    -- If we really want to Attack, Use Shrine or Retreat ( >= 0.75 ); 
    -- short-circuit consideration of other modes for better performance.
    if evaluatedDesireValue >= BOT_MODE_DESIRE_HIGH then
        return highestDesireMode, highestDesireValue
    end
    
    -- Courier usage is done at Team wide level. We can do our own 
    -- shopping at secret/side shop if we are informed that the courier
    -- will be unavailable to use for a certain period of time.
    evaluatedDesireValue = hero_think.ConsiderSecretAndSideShop(bot)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = shopMode
    end
    
    -- The decision is made at Team level. 
    -- This just checks if the Hero is part of the push, and if so, 
    -- what lane.
    evaluatedDesireValue = hero_think.ConsiderPushingLane(bot, nearbyEnemies, nearbyETowers, nearbyECreeps, nearbyACreeps)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = pushLaneMode
    end
    
    -- The decision is made at Team level.
    -- This just checks if the Hero is part of the defense, and 
    -- where to go to defend if so.
    evaluatedDesireValue = hero_think.ConsiderDefendingLane(bot)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = defendLaneMode
    end
    
    -- This is a localized lane decision. An ally defense can turn into an 
    -- orchestrated Team level fight, but that will be determined at the 
    -- Team level. If not a fight, then this is just a "buy my retreating
    -- friend some time to go heal up / retreat".
    evaluatedDesireValue = hero_think.ConsiderDefendingAlly(bot)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = defendAllyMode
    end
    
    -- Roaming decision are made at the Team level to keep all relevant
    -- heroes informed of the upcoming kill opportunity. 
    -- This just checks if this Hero is part of the Gank.
    evaluatedDesireValue = hero_think.ConsiderRoam(bot)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = roamMode
    end
    
    -- The decision if and who should get Rune is made Team wide.
    -- This just checks if this Hero should get it.
    evaluatedDesireValue = hero_think.ConsiderRune(bot, playerAssignment)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = runeMode
    end
    
    -- The decision to Roshan is done in TeamThink().
    -- This just checks if this Hero should be part of the effort.
    evaluatedDesireValue = hero_think.ConsiderRoshan(bot)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = roshanMode
    end
    
    -- Farming assignments are made Team Wide.
    -- This just tells the Hero where he should go to Jungle.
    evaluatedDesireValue = hero_think.ConsiderJungle(bot, playerAssignment)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = jungleMode
    end
    
    -- Laning assignments are made Team Wide for Pushing & Defending.
    -- Laning assignments are initially determined at start of game/hero-selection.
    -- This just tells the Hero which Lane he is supposed to be in.
    evaluatedDesireValue = hero_think.ConsiderLaning(bot, playerAssignment)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = laningMode
    end
    
    -- Warding is done on a per-lane basis. This evaluates if this Hero
    -- should ward, and where. (might be a team wide thing later)
    evaluatedDesireValue = hero_think.ConsiderWarding(bot, playerAssignment)
    if evaluatedDesireValue > highestDesireValue then
        highestDesireValue = evaluatedDesireValue
        highestDesireMode = wardMode
    end
    
    return highestDesireMode, highestDesireValue
end

return X
