-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )

----------
X.me    = nil
X.type  = constants.SHOP_TYPE_NONE

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

function GetSecretShop()
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
    if secLoc == nil then return false end

    if GetUnitToLocationDistance(bot, secLoc) < constants.SHOP_USE_DISTANCE then
        if bot:GetGold() >= GetItemCost( NextItem ) then
            bot:ActionImmediate_PurchaseItem( NextItem )
            table.remove(X.me:getHeroVar("ItemPurchaseClass").PurchaseOrder , 1)
            bot:SetNextItemPurchaseValue( 0 )
            X.me:getHeroVar("ItemPurchaseClass"):UpdateTeamBuyList(NextItem)
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
            table.remove(X.me:getHeroVar("ItemPurchaseClass").PurchaseOrder , 1)
            bot:SetNextItemPurchaseValue( 0 )
            X.me:getHeroVar("ItemPurchaseClass"):UpdateTeamBuyList(NextItem)
            return true
        else
            return false
        end
    else
        bot:Action_MoveToLocation(secLoc)
        return false
    end
end

function X:GetName()
    return "shop"
end

function X:OnStart(myBot)
    X.me = myBot
    X.type = X.me:getHeroVar("ShopType")
end

function X:OnEnd()
    X.type = constants.SHOP_TYPE_NONE
end

function X:Think(bot)
    local bDone = false
    if X.type == constants.SHOP_TYPE_SIDE then
        bDone = ThinkSideShop( sNextItem )
    elseif X.type == constants.SHOP_TYPE_SECRET then
        bDone =ThinkSecretShop( sNextItem )
    end
    
    if bDone then
        X.me:ClearMode()
    end
end

return X