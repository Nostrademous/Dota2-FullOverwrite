-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "special_shop_generic", package.seeall )

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

-------------------------------------------------------------------------------

function OnStart()
    utils.InitPath()
end

function GetSideShop()
    local npcBot = GetBot()

    local Enemies = npcBot:GetNearbyHeroes(1300, true, BOT_MODE_NONE)

    if  npcBot:DistanceFromSideShop() > 2400 or (#Enemies > 1 and npcBot:DistanceFromSideShop() > 1500) then
        return nil
    end

    if GetUnitToLocationDistance(npcBot, constants.SIDE_SHOP_TOP) < GetUnitToLocationDistance(npcBot, constants.SIDE_SHOP_BOT) then
        return constants.SIDE_SHOP_TOP
    else
        return constants.SIDE_SHOP_BOT
    end

end

local function GetSecretShop()
    local npcBot = GetBot()

    if GetTeam() == TEAM_RADIANT then
        local safeTower = utils.GetLaneTower(utils.GetOtherTeam(), LANE_BOT, 1)

        if utils.NotNilOrDead(safeTower) then
            return constants.SECRET_SHOP_RADIANT
        end
    else
        local safeTower = utils.GetLaneTower(utils.GetOtherTeam(), LANE_TOP, 1)

        if utils.NotNilOrDead(safeTower) then
            return constants.SECRET_SHOP_DIRE
        end
    end

    if GetUnitToLocationDistance(npcBot, constants.SECRET_SHOP_DIRE) < GetUnitToLocationDistance(npcBot, constants.SECRET_SHOP_RADIANT) then
        return constants.SECRET_SHOP_DIRE
    else
        return constants.SECRET_SHOP_RADIANT
    end
end

function ThinkSecretShop( NextItem )
    local npcBot = GetBot()
    if  NextItem == nil then
        return false
    end

    if npcBot:IsUsingAbility() or npcBot:IsChanneling() then return false end

    if (not IsItemPurchasedFromSecretShop(NextItem)) or npcBot:GetGold() < GetItemCost( NextItem ) then
        return false
    end

    local secLoc = GetSecretShop()

    if GetUnitToLocationDistance(npcBot, secLoc) < constants.SHOP_USE_DISTANCE then
        if npcBot:GetGold() >= GetItemCost( NextItem ) then
            npcBot:Action_PurchaseItem( NextItem )
            utils.InitPath()
            return true
        else
            return false
        end
    else
        utils.MoveSafelyToLocation(npcBot, secLoc)
        return false
    end
end

function ThinkSideShop( NextItem )
    local npcBot = GetBot()
    if  NextItem == nil then
        return false
    end

    if npcBot:IsUsingAbility() or npcBot:IsChanneling() then return false end

    if (not IsItemPurchasedFromSideShop(NextItem)) or npcBot:GetGold() < GetItemCost( NextItem ) then
        return false
    end

    local sideLoc = GetSideShop()

    if sideLoc == nil then return false end

    if GetUnitToLocationDistance(npcBot, sideLoc) < constants.SHOP_USE_DISTANCE then
        if npcBot:GetGold() >= GetItemCost( NextItem ) then
            npcBot:Action_PurchaseItem( NextItem )
            utils.InitPath()
            return true
        else
            return false
        end
    else
        utils.MoveSafelyToLocation(npcBot, sideLoc)
        return false
    end
end

--------
for k,v in pairs( special_shop_generic ) do _G._savedEnv[k] = v end
