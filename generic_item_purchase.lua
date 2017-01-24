-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "generic_item_purchase", package.seeall )

require( GetScriptDirectory().."/special_shop_generic" )
local utils = require( GetScriptDirectory().."/utility")

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

function ItemPurchaseThink(tableItemsToBuyAsMid, tableItemsToBuyAsHardCarry, tableItemsToBuyAsOfflane, tableItemsToBuyAsSupport, tableItemsToBuyAsJungler, tableItemsToBuyAsRoamer)
    local npcBot = GetBot();
    if npcBot == nil then return end
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end

    if ( (npcBot:GetNextItemPurchaseValue() > 0) and (npcBot:GetGold() < npcBot:GetNextItemPurchaseValue()) ) then
        return
    end

    local roleTable = nil
    local sNextItem = nil

    if ( getHeroVar("Role") == role.ROLE_MID ) then
        --print( getHeroVar("Name").."ItemPurchaseThink.Mid" );
        roleTable = tableItemsToBuyAsMid
    elseif ( getHeroVar("Role") == role.ROLE_HARDCARRY ) then
        --print( getHeroVar("Name").."ItemPurchaseThink.HardCarry" );
        roleTable = tableItemsToBuyAsHardCarry
    elseif ( getHeroVar("Role") == role.ROLE_OFFLANE ) then
        --print( getHeroVar("Name").."ItemPurchaseThink.Offlane" )
        roleTable = tableItemsToBuyAsOfflane
    elseif ( getHeroVar("Role") == role.ROLE_HARDSUPPORT or getHeroVar("Role") == role.ROLE_SEMISUPPORT ) then
        --print( getHeroVar("Name").."ItemPurchaseThink.Support" )
        roleTable = tableItemsToBuyAsSupport
    elseif ( getHeroVar("Role") == role.ROLE_JUNGLER ) then
        --print( getHeroVar("Name").."ItemPurchaseThink.Jungler" )
        roleTable = tableItemsToBuyAsJungler
    elseif ( getHeroVar("Role") == role.ROLE_ROAMER ) then
        --print( getHeroVar("Name").."ItemPurchaseThink.Roamer" )
        roleTable = tableItemsToBuyAsRoamer
    end

    if ( #roleTable == 0 ) then
        npcBot:SetNextItemPurchaseValue( 0 );
        print( "    No More Items in Purchase Table!" )
        return;
    end

    sNextItem = roleTable[1]

    if sNextItem ~= nil then
        -- Set cost
        npcBot:SetNextItemPurchaseValue(GetItemCost(sNextItem))

        -- Enough gold -> buy, remove
        if(npcBot:GetGold() >= GetItemCost(sNextItem)) then
            -- Next item only available in secret shop?
            local bInSide = IsItemPurchasedFromSideShop( sNextItem )
            local bInSecret = IsItemPurchasedFromSecretShop( sNextItem )

            if bInSide then
                local safeToVisitSide = special_shop_generic.GetSideShop()

                -- if it is not safe to visit the side shop and item is
                -- not available in secret shop, courier buy it
                if safeToVisitSide == nil then
                    if not bInSecret then
                        npcBot:Action_PurchaseItem(sNextItem)
                        table.remove(self.PurchaseOrder, 1)
                        npcBot:SetNextItemPurchaseValue(0)
                        return
                    end
                end

                local me = getHeroVar("Self")
                if me:GetAction() ~= constants.ACTION_SECRETSHOP then
                    if ( me:HasAction(constants.ACTION_SECRETSHOP) == false ) then
                        me:AddAction(constants.ACTION_SECRETSHOP)
                        utils.myPrint(" STARTING TO HEAD TO SIDE SHOP ")
                        special_shop_generic.OnStart()
                    end
                end

                local bDone = special_shop_generic.ThinkSideShop(sNextItem)
                if bDone then
                    me:RemoveAction(constants.ACTION_SECRETSHOP)
                    table.remove(self.PurchaseOrder, 1 )
                    npcBot:SetNextItemPurchaseValue( 0 )
                end
            end

            if bInSecret then
                local me = getHeroVar("Self")
                if me:GetAction() ~= constants.ACTION_SECRETSHOP then
                    if ( me:HasAction(constants.ACTION_SECRETSHOP) == false ) then
                        me:AddAction(constants.ACTION_SECRETSHOP)
                        utils.myPrint(" STARTING TO HEAD TO SECRET SHOP ")
                        special_shop_generic.OnStart()
                    end
                end

                local bDone = special_shop_generic.ThinkSecretShop(sNextItem)
                if bDone then
                    me:RemoveAction(constants.ACTION_SECRETSHOP)
                    table.remove(self.PurchaseOrder, 1 )
                    npcBot:SetNextItemPurchaseValue( 0 )
                end
            else
                npcBot:Action_PurchaseItem(sNextItem)
                table.remove(self.PurchaseOrder, 1)
                npcBot:SetNextItemPurchaseValue(0)
            end

            return
        end
    end
end

for k,v in pairs( generic_item_purchase ) do _G._savedEnv[k] = v end