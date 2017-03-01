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
end

function GetSideShop()
    local bot = GetBot()

    local Enemies = bot:GetNearbyHeroes(1300, true, BOT_MODE_NONE)

    if  bot:DistanceFromSideShop() > 2400 or (#Enemies > 1 and bot:DistanceFromSideShop() > 1500) then
        return nil
    end

    if GetUnitToLocationDistance(bot, constants.SIDE_SHOP_TOP) < GetUnitToLocationDistance(bot, constants.SIDE_SHOP_BOT) then
        return constants.SIDE_SHOP_TOP
    else
        return constants.SIDE_SHOP_BOT
    end

end

local function GetSecretShop()
    local bot = GetBot()

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

    if GetUnitToLocationDistance(bot, constants.SECRET_SHOP_DIRE) < GetUnitToLocationDistance(bot, constants.SECRET_SHOP_RADIANT) then
        return constants.SECRET_SHOP_DIRE
    else
        return constants.SECRET_SHOP_RADIANT
    end
end

function ThinkSecretShop( NextItem )
    local bot = GetBot()
    if  NextItem == nil then
        return false
    end

    if (not IsItemPurchasedFromSecretShop(NextItem)) or bot:GetGold() < GetItemCost( NextItem ) then
        return false
    end

    local secLoc = GetSecretShop()
    if secLoc = =nil then return false end

    if GetUnitToLocationDistance(bot, secLoc) < constants.SHOP_USE_DISTANCE then
        if bot:GetGold() >= GetItemCost( NextItem ) then
            bot:ActionImmediate_PurchaseItem( NextItem )
            return true
        else
            return false
        end
    else
        bot:Action_MoveToLocation(secLoc)
        return false
    end
end

function ThinkSideShop( NextItem )
    local bot = GetBot()
    if  NextItem == nil then
        return false
    end

    if (not IsItemPurchasedFromSideShop(NextItem)) or bot:GetGold() < GetItemCost( NextItem ) then
        return false
    end

    local sideLoc = GetSideShop()
    if sideLoc == nil then return false end

    if GetUnitToLocationDistance(bot, sideLoc) < constants.SHOP_USE_DISTANCE then
        if bot:GetGold() >= GetItemCost( NextItem ) then
            bot:ActionImmediate_PurchaseItem( NextItem )
            return true
        else
            return false
        end
    else
        bot:Action_MoveToLocation(secLoc)
        return false
    end
end

--------
for k,v in pairs( special_shop_generic ) do _G._savedEnv[k] = v end
