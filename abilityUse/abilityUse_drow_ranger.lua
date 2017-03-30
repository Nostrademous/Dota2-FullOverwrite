-------------------------------------------------------------------------------
--- AUTHOR: pbenologa, Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local drAbility = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/fight_simul" )
require( GetScriptDirectory().."/modifiers" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

local Abilities ={
    "drow_ranger_frost_arrows",
    "drow_ranger_wave_of_silence",
    "drow_ranger_trueshot",
    "drow_ranger_marksmanship"
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

local AttackRange   = 0
local ManaPerc      = 0
local modeName      = nil

function drAbility:nukeDamage( bot, enemy )
    if not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = bot:GetAttackRange() + bot:GetBoundingRadius()

    local magicImmune = utils.IsTargetMagicImmune(enemy)

    -- Check Frost Arrows
    if abilityQ:IsFullyCastable() then
        if not magicImmune then
            local manaCostQ = abilityQ:GetManaCost()
            local speedReduction = abilityQ:GetSpecialValueInt("frost_arrows_movement_speed")
            local numCasts = 1

            local dist = GetUnitToUnitDistance(bot, enemy)
            if dist < (bot:GetAttackRange() + bot:GetBoundingRadius() + enemy:GetBoundingRadius()) then
                if bot:GetCurrentMovementSpeed() > (enemy:GetCurrentMovementSpeed() + speedReduction) then
                    numCasts = Min(Min(bot:GetLevel(), 6), math.floor(manaAvailable/12))
                else
                    local distToEscape = (bot:GetAttackRange() + bot:GetBoundingRadius() + enemy:GetBoundingRadius()) - dist
                    local timeToEscape = distToEscape/(enemy:GetCurrentMovementSpeed() + speedReduction - bot:GetCurrentMovementSpeed())
                    numCasts = Min(math.floor(timeToEscape/bot:GetSecondsPerAttack()), math.floor(manaAvailable/12))
                end
            end

            for i = 1, numCasts, 1 do
                if manaCostQ <= manaAvailable then
                    manaAvailable = manaAvailable - manaCostQ
                    dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
                    castTime = castTime + bot:GetAttackPoint()
                    slowTime = slowTime + 1.5
                    table.insert(comboQueue, abilityQ)
                end
            end
        else
            dmgTotal = dmgTotal + Min(bot:GetLevel(),4)*enemy:GetActualIncomingDamage(bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
            castTime = castTime + bot:GetAttackPoint()
        end
    end

    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function drAbility:queueNuke(bot, enemy, castQueue, engageDist)
    if not utils.ValidTarget(enemy) then return false end
    
    local dist = GetUnitToUnitDistance(bot, enemy)

    -- if out of range, attack move for one hit to get in range
    if dist < engageDist then
        bot:Action_ClearActions(false)
        utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
        utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
        for i = #castQueue, 1, -1 do
            local skill = castQueue[i]

            if skill:GetName() == Abilities[1] then
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            elseif skill:GetName() == Abilities[2] then
                gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
            end
        end
        return true
    end
    return false
end

function ComboDmg(bot, target)
    if not utils.ValidTarget(target) then return 0 end
    local dmg, castQueue, castTime, stunTime, slowTime, engageDist = drAbility:nukeDamage( bot, target )
    return dmg
end

function ConsiderQ()
    local bot = GetBot()

    if not abilityQ:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
        local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, AttackRange + 100)
        if utils.ValidTarget(WeakestEnemy) then
            if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
                if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(ComboDmg(bot, WeakestEnemy), DAMAGE_TYPE_PHYSICAL) then
                    return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
                end
            end
        end
    end

    -- If we're going after someone
    if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
        local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

        if utils.ValidTarget(npcEnemy) then
            if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) and
                GetUnitToUnitDistance(bot, npcEnemy) < (AttackRange + 75*#gHeroVar.GetNearbyAllies(bot,1200)) then
                return BOT_ACTION_DESIRE_MODERATE, npcEnemy
            end
        end
    end

    -- laning harassment
    if modeName == "laning" and ManaPerc > 0.4 then
        local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, AttackRange)
        if utils.ValidTarget(WeakestEnemy) then
            if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
                return BOT_ACTION_DESIRE_LOW, WeakestEnemy
            end
        end
    end

    -- jungling
    if modeName == "jungling" and ManaPerc > 0.25 then
        local neutralCreeps = gHeroVar.GetNearbyEnemyCreep(bot, AttackRange)
        for _, creep in pairs(neutralCreeps) do
            if utils.ValidTarget(creep) and not creep:HasModifier("modifier_drow_ranger_frost_arrows_slow") and not creep:IsAncientCreep() then
                return BOT_ACTION_DESIRE_LOW, creep
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderW()
    local bot = GetBot()

    if not abilityW:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- WRITE CODE HERE --
    local CastRange = abilityW:GetCastRange()
    local WaveSpeed = abilityW:GetSpecialValueFloat("wave_speed")
    --local Delay = abilityW:GetCastPoint() + GetUnitToUnitDistance(bot, npcEnemy)/WaveSpeed

    --Use gust to break channeling spells
    local enemies = gHeroVar.GetNearbyEnemies(bot, CastRange+300)
    for _, npcEnemy in pairs( enemies ) do
        if utils.ValidTarget(npcEnemy) and npcEnemy:IsChanneling() and not utils.IsTargetMagicImmune(npcEnemy) then
            return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
        end
    end

    -- If we're in a teamfight, silence as many as we can
    local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1000)
    if #tableNearbyAttackingAlliedHeroes >= 2 then
        local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), CastRange, 250, 0, 0 )
        if locationAoE.count >= 2 and GetUnitToLocationDistance(bot, locationAoE.targetloc) <= CastRange then
            return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc
        end
    end

    -- protect myself
    if modeName == "retreat" or modeName == "shrine" then
        local closeEnemies = gHeroVar.GetNearbyEnemies(bot, 350)
        for _, npcEnemy in pairs( closeEnemies ) do
            if utils.ValidTarget(npcEnemy) and not utils.IsTargetMagicImmune( npcEnemy ) and not utils.IsCrowdControlled(npcEnemy) then
                return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderE()
    local bot = GetBot()

    if not abilityE:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- WRITE CODE HERE --
    if modeName == "pushlane" then
        local aCreep    = gHeroVar.GetNearbyAlliedCreep(bot, 900)
        local eCreep    = gHeroVar.GetNearbyEnemyCreep(bot, 900)
        local eTowers   = gHeroVar.GetNearbyEnemyTowers(bot, 900)
        local enemies   = gHeroVar.GetNearbyEnemies(bot, 1200)

        if #eTowers > 0 and #enemies == 0 and #eCreep <= 1 and #aCreep >= 3 then
            return BOT_ACTION_DESIRE_LOW
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function drAbility:AbilityUsageThink(bot)
    if utils.IsBusy(bot) then return true end

    if utils.IsUnableToCast(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    AttackRange   = bot:GetAttackRange() + bot:GetBoundingRadius()
    ManaPerc      = bot:GetMana()/bot:GetMaxMana()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    local modeDesire    = bot.SelfRef:getCurrentModeValue()

    -- CHECK BELOW TO SEE WHICH ABILITIES ARE NOT PASSIVE AND WHAT RETURN TYPES ARE --
    -- Consider using each ability
    local castQDesire, castQTarget  = ConsiderQ()
    local castWDesire, castWLoc     = ConsiderW()
    local castEDesire               = ConsiderE()

    -- CHECK BELOW TO SEE WHAT PRIORITY OF ABILITIES YOU WANT FOR THIS HERO --
    if castEDesire > modeDesire and castEDesire > Max(castWDesire, castQDesire) then
        gHeroVar.HeroUseAbility(bot,  abilityE)
        return true
    end

    if castWDesire > modeDesire and castWDesire > castQDesire then
        gHeroVar.HeroUseAbilityOnLocation(bot, abilityW, castWLoc)
        return true
    end

    if castQDesire > modeDesire then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityQ, castQTarget)
        return true
    end

    return false
end

return drAbility
