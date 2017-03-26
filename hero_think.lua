-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
------------------------------------------------------------------------------- 

_G._savedEnv = getfenv()
module( "hero_think", package.seeall )
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_usage" )

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local utils = require( GetScriptDirectory().."/utility" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

local specialFile = nil
local specialFileName = nil
function tryHeroSpecialMode()
    specialFile = dofile(specialFileName)
end

-- Consider incoming projectiles or nearby AOE and if we can evade.
-- This is of highest importance b/c if we are stunned/disabled we 
-- cannot do any of the other actions we might be asked to perform.
function ConsiderEvading(bot)
    if bot.evasionMode ~= nil then
        return bot.evasionMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/evasion_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.evasionMode = specialFile
            return bot.evasionMode:Desire(bot)
        else
            specialFileName = nil
            bot.evasionMode = dofile( GetScriptDirectory().."/modes/evasion" )
            return bot.evasionMode:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- Fight orchestration is done at a global Team level.
-- This just checks if we are given a fight target and a specific
-- action queue to execute as part of the fight.
function ConsiderAttacking(bot)
    if bot.fightMode ~= nil then
        return bot.fightMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/fight_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.fightMode = specialFile
            return bot.fightMode:Desire(bot)
        else
            specialFileName = nil
            bot.fightMode = dofile( GetScriptDirectory().."/modes/fight" )
            return bot.fightMode:Desire(bot)
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

-- Which Heroes should be present for Shrine heal is made at Team level.
-- This just tells us if we should be part of this event.
function ConsiderShrine(bot, playerAssignment)
    if bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
    
    if bot.shrineMode ~= nil then
        return bot.shrineMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/shrine_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.shrineMode = specialFile
            return bot.shrineMode:Desire(bot)
        else
            specialFileName = nil
            bot.shrineMode = dofile( GetScriptDirectory().."/modes/shrine" )
            return bot.shrineMode:Desire(bot)
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

-- Determine if we should retreat. Team Fight Assignements can 
-- over-rule our desire though. It might be more important for us to die
-- in a fight but win the over-all battle. If no Team Fight Assignment, 
-- then it is up to the Hero to manage their safety from global and
-- tower/creep damage.
function ConsiderRetreating(bot)
    if bot.retreatMode ~= nil then
        return bot.retreatMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/retreat_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.retreatMode = specialFile
            return bot.retreatMode:Desire(bot)
        else
            specialFileName = nil
            bot.retreatMode = dofile( GetScriptDirectory().."/modes/retreat" )
            return bot.retreatMode:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- Courier usage is done at Team wide level. We can do our own 
-- shopping at secret/side shop if we are informed that the courier
-- will be unavailable to use for a certain period of time.
function ConsiderSecretAndSideShop(bot)
    if bot.shopMode ~= nil then
        return bot.shopMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/shop_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.shopMode = specialFile
            return bot.shopMode:Desire(bot)
        else
            specialFileName = nil
            bot.shopMode = dofile( GetScriptDirectory().."/modes/shop" )
            return bot.shopMode:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- The decision is made at Team level. 
-- This just checks if the Hero is part of the push, and if so, 
-- what lane.
function ConsiderPushingLane(bot)
    if bot.pushlaneMode ~= nil then
        return bot.pushlaneMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/pushlane_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.pushlaneMode = specialFile
            return bot.pushlaneMode:Desire(bot)
        else
            specialFileName = nil
            bot.pushlaneMode = dofile( GetScriptDirectory().."/modes/pushlane" )
            return bot.pushlaneMode:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- The decision is made at Team level.
-- This just checks if the Hero is part of the defense, and 
-- where to go to defend if so.
function ConsiderDefendingLane(bot)
    if bot.defendLane ~= nil then
        return bot.defendLane:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/defendlane_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.defendLane = specialFile
            return bot.defendLane:Desire(bot)
        else
            specialFileName = nil
            bot.defendLane = dofile( GetScriptDirectory().."/modes/defendlane" )
            return bot.defendLane:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- This is a localized lane decision. An ally defense can turn into an 
-- orchestrated Team level fight, but that will be determined at the 
-- Team level. If not a fight, then this is just a "buy my retreating
-- friend some time to go heal up / retreat".
function ConsiderDefendingAlly(bot)
    if bot.defendAlly ~= nil then
        return bot.defendAlly:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/defendally_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.defendAlly = specialFile
            return bot.defendAlly:Desire(bot)
        else
            specialFileName = nil
            bot.defendAlly = dofile( GetScriptDirectory().."/modes/defendally" )
            return bot.defendAlly:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- Roaming decision are made at the Team level to keep all relevant
-- heroes informed of the upcoming kill opportunity. 
-- This just checks if this Hero is part of the Gank.
function ConsiderRoam(bot) 
    if bot.roam ~= nil then
        return bot.roam:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/roam_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.roam = specialFile
            return bot.roam:Desire(bot)
        else
            specialFileName = nil
            bot.roam = dofile( GetScriptDirectory().."/modes/roam" )
            return bot.roam:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- The decision if and who should get Rune is made Team wide.
-- This just checks if this Hero should get it.
function ConsiderRune(bot, playerAssignment)
    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then return BOT_MODE_DESIRE_NONE end
    
    local playerRuneAssignment = playerAssignment[bot:GetPlayerID()].GetRune
    if playerRuneAssignment ~= nil then
        if playerRuneAssignment[1] == nil or GetRuneStatus(playerRuneAssignment[1]) == RUNE_STATUS_MISSING or
            GetUnitToLocationDistance(bot, playerRuneAssignment[2]) > 3600 then
            playerAssignment[bot:GetPlayerID()].GetRune = nil
            setHeroVar("RuneTarget", nil)
            setHeroVar("RuneLoc", nil)
            return BOT_MODE_DESIRE_NONE
        else
            setHeroVar("RuneTarget", playerRuneAssignment[1])
            setHeroVar("RuneLoc", playerRuneAssignment[2])
            return BOT_MODE_DESIRE_HIGH 
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

-- The decision to Roshan is done in TeamThink().
-- This just checks if this Hero should be part of the effort.
function ConsiderRoshan(bot)
    if bot.roshanMode ~= nil then
        return bot.roshanMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/roshan_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.roshanMode = specialFile
            return bot.roshanMode:Desire(bot)
        else
            specialFileName = nil
            bot.roshanMode = dofile( GetScriptDirectory().."/modes/roshan" )
            return bot.roshanMode:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- Farming assignments are made Team Wide.
-- This just tells the Hero where he should Jungle.
function ConsiderJungle(bot, playerAssignment)
    if bot.junglingMode ~= nil then
        return bot.junglingMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/jungling_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.junglingMode = specialFile
            return bot.junglingMode:Desire(bot)
        else
            specialFileName = nil
            bot.junglingMode = dofile( GetScriptDirectory().."/modes/jungling" )
            return bot.junglingMode:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- Laning assignments are made Team Wide for Pushing & Defending.
-- Laning assignments are initially determined at start of game/hero-selection.
-- This just tells the Hero which Lane he is supposed to be in.
function ConsiderLaning(bot, playerAssignment)
    if playerAssignment[bot:GetPlayerID()].Lane ~= nil then
        setHeroVar("CurLane", playerAssignment[bot:GetPlayerID()].Lane)
    end
    
    if bot.laningMode ~= nil then
        return bot.laningMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/laning_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.laningMode = specialFile
            return bot.laningMode:Desire(bot)
        else
            specialFileName = nil
            bot.laningMode = dofile( GetScriptDirectory().."/modes/laning" )
            return bot.laningMode:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- Warding is done on a per-lane basis. This evaluates if this Hero
-- should ward, and where. (might be a team wide thing later)
function ConsiderWarding(bot, playerAssignment)
    if bot.wardMode ~= nil then
        return bot.wardMode:Desire(bot)
    else
        specialFileName = GetScriptDirectory().."/modes/ward_"..utils.GetHeroName(bot)
        if pcall(tryHeroSpecialMode) then
            specialFileName = nil
            bot.wardMode = specialFile
            return bot.wardMode:Desire(bot)
        else
            specialFileName = nil
            bot.wardMode = dofile( GetScriptDirectory().."/modes/ward" )
            return bot.wardMode:Desire(bot)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

for k,v in pairs( hero_think ) do _G._savedEnv[k] = v end
