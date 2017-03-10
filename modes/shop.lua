-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function GetSideShop()
    local bot = GetBot()

    local Enemies = gHeroVar.GetNearbyEnemies(bot, Min(1600, bot:GetCurrentVisionRange()))

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
            table.remove(getHeroVar("ItemPurchaseClass"):GetPurchaseOrder() , 1)
            bot:SetNextItemPurchaseValue( 0 )
            getHeroVar("ItemPurchaseClass"):UpdateTeamBuyList(NextItem)
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
            table.remove(getHeroVar("ItemPurchaseClass"):GetPurchaseOrder() , 1)
            bot:SetNextItemPurchaseValue( 0 )
            getHeroVar("ItemPurchaseClass"):UpdateTeamBuyList(NextItem)
            return true
        else
            return false
        end
    else
        bot:Action_MoveToLocation(sideLoc)
        return false
    end
end

function X:GetName()
    return "shop"
end

function X:OnStart(myBot)
end

function X:OnEnd()
    setHeroVar("ShopType", constants.SHOP_TYPE_NONE)
    setHeroVar("NextShopItem", nil)
end

function X:Think(bot)
    if utils.IsBusy(bot) then return end

    local bDone = false
    if  getHeroVar("ShopType") == constants.SHOP_TYPE_SIDE then
        bDone = ThinkSideShop( getHeroVar("NextShopItem") )
    elseif getHeroVar("ShopType") == constants.SHOP_TYPE_SECRET then
        bDone = ThinkSecretShop( getHeroVar("NextShopItem") )
    else
        utils.myPrint("shop.lua :: Think() - FIXME")
    end
    
    if bDone then
        getHeroVar("Self"):ClearMode()
    end
end

function X:Desire(bot)
    if bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
    
    local sNextItem = getHeroVar("ItemPurchaseClass"):GetPurchaseOrder()[1]
    setHeroVar("NextShopItem", sNextItem)

    if bot:GetGold() < GetItemCost( sNextItem ) then
        return BOT_MODE_DESIRE_NONE
    end

    local bInSide = IsItemPurchasedFromSideShop( sNextItem )
    local bInSecret = IsItemPurchasedFromSecretShop( sNextItem )

    -- it's in side shop, but it's not safe to go there
    if bInSide and GetSideShop() == nil then
        bInSide = false
    end
    
    -- it's in secret shop, but it's not safe to go there
    -- FIXME: doesn't actually check for "safe to go there"
    if bInSecret and GetSecretShop() == nil then
        bInSecret = false
    end
    
    if bInSide and bInSecret then
        if bot:DistanceFromSecretShop() < bot:DistanceFromSideShop() then
            bInSide = false
        end
    end
    
    if bInSide then
        setHeroVar("ShopType", constants.SHOP_TYPE_SIDE)
        return BOT_MODE_DESIRE_MODERATE
    elseif bInSecret then
        setHeroVar("ShopType", constants.SHOP_TYPE_SECRET)
        return BOT_MODE_DESIRE_MODERATE
    end
    
    local me = getHeroVar("Self")
    if me:getCurrentMode():GetName() == "shop" and
        (bInSide or bInSecret) then
        return me:getCurrentModeValue()
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X