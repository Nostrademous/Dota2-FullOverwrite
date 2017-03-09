-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
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
    utisl.myPrint("Defense mode activated!")
end

function X:OnEnd()
    utisl.myPrint("Defense mode ended!")
end

function X:Desire(bot)
    local defInfo = getHeroVar("DoDefendLane")
    if #defInfo > 0 then
        return BOT_MODE_DESIRE_VERYHIGH
    end
    return BOT_MODE_DESIRE_NONE
end

function X:DefendTower(bot, hBuilding)
    gHeroVar.HeroMoveToLocation(bot, hBuilding:GetLocation()) -- hug the tower
end

function X:Think(bot)
    X.me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")

    local defInfo = X.me:getHeroVar("DoDefendLane") -- TEAM has made the decision.
    -- TODO: unpack function??
    local lane = defInfo[0]
    local building = defInfo[1]
    local numEnemies = defInfo[2]

    local hBuilding = buildings_status.GetHandle(GetTeam(), building)

    if hBuilding == nil then
        X.me:setHeroVar("DoDefendLane", {})
        return false
    end

    local distFromBuilding = GetUnitToUnitDistance(bot, hBuilding)
    local timeToReachBuilding = distFromBuilding/bot:GetCurrentMovementSpeed()

    if timeToReachBuilding <= 5.0 then
        X:DefendTower(bot, hBuilding, {})
    else
        if bot:IsChanneling() or bot:IsCastingAbility() then return true end
        local tp = utils.HaveItem(bot, "item_travel_boots_1") or utils.HaveItem(bot, "item_travel_boots_2") or utils.HaveItem(bot, "item_tpscroll") -- TODO: more generic
        if tp == nil then return false end -- something went wrong.. wait for TEAM to assign us to a new job
        bot:Action_UseAbilityOnLocation(tp, hBuilding:GetLocation())
        utils.myPrint("TPing")
    end

    return true
end

return X
