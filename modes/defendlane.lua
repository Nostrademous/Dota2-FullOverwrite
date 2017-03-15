-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
require( GetScriptDirectory().."/item_usage" )

X.me = nil

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "defendlane"
end

function X:OnStart(myBot)
    X.me = myBot
end

function X:OnEnd()
end

function X:Desire(bot)
    local defInfo = getHeroVar("DoDefendLane")
    if #defInfo > 0 then
        return BOT_MODE_DESIRE_VERYHIGH
    end
    return BOT_MODE_DESIRE_NONE
end

function X:DefendTower(bot, hBuilding)
    -- TODO: all of this should use the fighting system.
    local enemies = gHeroVar.GetNearbyEnemies(bot, 1500)
    local allies = gHeroVar.GetNearbyAllies(bot, 1500)
    if #allies >= #enemies then -- we are good to go
        gHeroVar.HeroAttackUnit(bot, enemies[1], true) -- Charge! at the closes enemy
    else -- stay back
        local dist = GetUnitToUnitDistance(bot, enemies[1])
        if dist < 900 then -- they are to close
            gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), enemies[1]:GetLocation(), 950-dist))
        end -- else do nothing. abilityUse should handle this
    end
end

function X:Think(bot)
    X.me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")

    local defInfo = X.me:getHeroVar("DoDefendLane") -- TEAM has made the decision.
    -- TODO: unpack function??
    local lane = defInfo[1]
    local building = defInfo[2]
    local numEnemies = defInfo[3]

    local hBuilding = buildings_status.GetHandle(GetTeam(), building)

    if hBuilding == nil then
        X.me:setHeroVar("DoDefendLane", {})
        return
    end

    local distFromBuilding = GetUnitToUnitDistance(bot, hBuilding)
    local timeToReachBuilding = distFromBuilding/bot:GetCurrentMovementSpeed()

    if timeToReachBuilding <= 5.0 then
        X:DefendTower(bot, hBuilding, {})
    else
        if bot:IsChanneling() or bot:IsCastingAbility() then return true end
        local tp = utils.HaveItem(bot, "item_travel_boots_1") or utils.HaveItem(bot, "item_travel_boots_2") or utils.HaveItem(bot, "item_tpscroll") -- TODO: more generic
        if tp == nil then
            X:DefendTower(bot, hBuilding, {})
        else
            -- calculate position for a defensive teleport
            -- TODO: consider hiding in trees, position of enemy
            -- TODO: is there, should there be a utils function for this?
            local pos = hBuilding:GetLocation()
            local vec = utils.Fountain(GetTeam()) - pos
            vec = vec * 575 / #vec -- resize to 575 units (max tp range from tower)
            pos = pos + vec
            bot:Action_UseAbilityOnLocation(tp, pos)
        end
    end

    return
end

return X
