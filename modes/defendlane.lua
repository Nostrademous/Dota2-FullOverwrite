-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
require( GetScriptDirectory().."/item_usage" )

----------
X.me            = nil

function X:GetName()
    return "defendlane"
end

function X:OnStart(myBot)
    X.me = myBot
end

function X:OnEnd()
end

function X:DefendTower(bot, hBuilding)
    gHeroVar.HeroMoveToLocation(bot, hBuilding:GetLocation()) -- hug the tower
end

function X:Think(bot)
    print("defendlane think")

    X.me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")

    local data = X.me:getHeroVar("DoDefendLane") -- TEAM has made the decision.
    -- TODO: unpack function??
    local lane = data[0]
    local building = data[1]
    local numEnemies = data[2]

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
        if bot:IsChanneling() or bot:IsCastingAbility() then return true end -- TODO: return true or false?
        local tp = utils.HaveItem(bot, "item_travel_boots_1") or utils.HaveItem(bot, "item_travel_boots_2") or utils.HaveItem(bot, "item_tpscroll")
        bot:Action_UseAbilityOnLocation(tp, dest)
        utils.myPrint("TPing")
    end

    return true
end

return X
