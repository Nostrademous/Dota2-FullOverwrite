-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local items = require(GetScriptDirectory().."/itemPurchase/items" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )

--[[
    The idea is that you get a list of starting items, utility items, core items and extension items.
    This class then decides which items to buy, considering what and how much damage the enemy mostly does,
    if we want offensive or defensive items and if we need anything else like consumables
--]]

-------------------------------------------------------------------------------
-- Helper Functions for accessing Global Hero Data
-------------------------------------------------------------------------------

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

-------------------------------------------------------------------------------
-- Declarations
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

X.ItemsToBuyAsHardCarry = {}
X.ItemsToBuyAsMid = {}
X.ItemsToBuyAsOfflane = {}
X.ItemsToBuyAsSupport = {}
X.ItemsToBuyAsJungler = {}
X.ItemsToBuyAsRoamer = {}

X.PurchaseOrder = {}
X.BoughtItems = {}
X.StartingItems = {}
X.UtilityItems = {}
X.CoreItems = {}
X.ExtensionItems = {
    OffensiveItems = {},
    DefensiveItems = {}
}

X.LastThink = -1000.0
X.LastSupportThink = -1000.0
X.LastExtensionThink = -1000.0

-------------------------------------------------------------------------------
-- Properties
-------------------------------------------------------------------------------

function X:GetStartingItems()
    return self.StartingItems
end

function X:SetStartingItems(items)
    self.StartingItems = items
end

function X:GetUtilityItems()
    return self.UtilityItems
end

function X:SetUtilityItems(items)
  self.UtilityItems = items
end

function X:GetCoreItems()
    return self.CoreItems
end

function X:SetCoreItems(items)
    self.CoreItems = items
end

function X:GetExtensionItems()
    return self.ExtensionItems[1], self.ExtensionItems[2]
end

function X:SetExtensionItems(items)
    self.ExtensionItems = items
end

-------------------------------------------------------------------------------
-- Think
-- ToDo: Selling items for better ones
-------------------------------------------------------------------------------

function X:UpdateTeamBuyList( sItem )
    local myList = getHeroVar("TeamBuy")
    if #myList > 0 then
        local pos = utils.PosInTable(myList, sItem)
        if pos > 0 then
            table.remove(myList, pos)
        end
    end
end

function X:Think(bot)
    local tDelta = RealTime() - self.LastThink
    -- throttle think for better performance
    if tDelta > 0.1 then
        if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end

        -- Put Team-wide Logic Assigned Items in our list
        local myTeamBuyList = getHeroVar("TeamBuy")
        if #myTeamBuyList > 0 then
            for _, item in ipairs(myTeamBuyList) do
                if not utils.InTable(self.PurchaseOrder, item) then
                    utils.myPrint("Adding team mandated item to my purchase list: ", item)
                    table.insert(self.PurchaseOrder, 1, item)
                end
            end
        end

        -- Put support items in list if we are a support (even if we already wanted to buy something else)
        self:BuySupportItems()

        -- If there's an item to be purchased already bail
        if ( (bot:GetNextItemPurchaseValue() > 0) and (bot:GetGold() < bot:GetNextItemPurchaseValue()) ) then return end

        -- If we want a new item we determine which one first
        if #self.PurchaseOrder == 0 then
            -- update order
            self:UpdatePurchaseOrder()
        end

        -- Consider selling items
        if bot:DistanceFromFountain() < constants.SHOP_USE_DISTANCE or
            bot:DistanceFromSecretShop() < constants.SHOP_USE_DISTANCE or
            bot:DistanceFromSideShop() < constants.SHOP_USE_DISTANCE then
            self:ConsiderSellingItems(bot)
        end

        -- Get the next item
        local sNextItem = self.PurchaseOrder[1]

        if sNextItem ~= nil then
            -- Set cost
            bot:SetNextItemPurchaseValue(GetItemCost(sNextItem))

            -- Enough gold -> buy, remove
            if(bot:GetGold() >= GetItemCost(sNextItem)) then
                if bot:IsAlive() then
                    local me = getHeroVar("Self")
                    
                    if me:getCurrentMode():GetName() ~= "shop" then
                        bot:ActionImmediate_PurchaseItem(sNextItem)
                        table.remove(self.PurchaseOrder, 1)
                        UpdateTeamBuyList(sNextItem)
                        bot:SetNextItemPurchaseValue(0)
                    end
                end

                self.LastThink = RealTime()
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Inits
-------------------------------------------------------------------------------

function X:InitTable()
    -- Init tables based on role    
    if (getHeroVar("Role") == role.ROLE_MID ) then
        self:SetStartingItems(self.ItemsToBuyAsMid.StartingItems)
        self:SetUtilityItems(self.ItemsToBuyAsMid.UtilityItems)
        self:SetCoreItems(self.ItemsToBuyAsMid.CoreItems)
        self:SetExtensionItems(self.ItemsToBuyAsMid.ExtensionItems)
        return true
    elseif (getHeroVar("Role") == role.ROLE_HARDCARRY ) then
        self:SetStartingItems(self.ItemsToBuyAsHardCarry.StartingItems)
        self:SetUtilityItems(self.ItemsToBuyAsHardCarry.UtilityItems)
        self:SetCoreItems(self.ItemsToBuyAsHardCarry.CoreItems)
        self:SetExtensionItems(self.ItemsToBuyAsHardCarry.ExtensionItems)
        return true
    elseif (getHeroVar("Role") == role.ROLE_OFFLANE ) then
        self:SetStartingItems(self.ItemsToBuyAsOfflane.StartingItems)
        self:SetUtilityItems(self.ItemsToBuyAsOfflane.UtilityItems)
        self:SetCoreItems(self.ItemsToBuyAsOfflane.CoreItems)
        self:SetExtensionItems(self.ItemsToBuyAsOfflane.ExtensionItems)
        return true
    elseif (getHeroVar("Role") == role.ROLE_HARDSUPPORT
        or getHeroVar("Role") == role.ROLE_SEMISUPPORT ) then
        self:SetStartingItems(self.ItemsToBuyAsSupport.StartingItems)
        self:SetUtilityItems(self.ItemsToBuyAsSupport.UtilityItems)
        self:SetCoreItems(self.ItemsToBuyAsSupport.CoreItems)
        self:SetExtensionItems(self.ItemsToBuyAsSupport.ExtensionItems)
        return true
    elseif (getHeroVar("Role") == role.ROLE_JUNGLER ) then
        self:SetStartingItems(self.ItemsToBuyAsJungler.StartingItems)
        self:SetUtilityItems(self.ItemsToBuyAsJungler.UtilityItems)
        self:SetCoreItems(self.ItemsToBuyAsJungler.CoreItems)
        self:SetExtensionItems(self.ItemsToBuyAsJungler.ExtensionItems)
        return true
    elseif (getHeroVar("Role") == role.ROLE_ROAMER ) then
        self:SetStartingItems(self.ItemsToBuyAsRoamer.StartingItems)
        self:SetUtilityItems(self.ItemsToBuyAsRoamer.UtilityItems)
        self:SetCoreItems(self.ItemsToBuyAsRoamer.CoreItems)
        self:SetExtensionItems(self.ItemsToBuyAsRoamer.ExtensionItems)
        return true
    end
end

-------------------------------------------------------------------------------
-- Buy functions
-------------------------------------------------------------------------------

function X:BuySupportItems()
    -- insert support items first if available
    if not utils.IsCore() then
    --[[
    Idea: Buy starting items, then buy either core / extension items unless there is more important utility to buy.
                Upgrade courier at 3:00, buy all available wards and if needed detection (no smoke).

    ToDo: Function to return number of invisible enemies.
                Buying consumable items like raindrops if there is a lot of magical damage
                Buying salves/whatever for cores if it makes sense
    --]]
        local tDelta = RealTime() - self.LastSupportThink
        -- throttle support item decisions to every 10s
        if tDelta > 10.0 then
            if GetNumCouriers() == 0 then
                -- we have no courier, buy it
                table.insert(self.PurchaseOrder, 1, "item_courier")
            end
            -- buy flying courier if available (only 1x)
            if GetNumCouriers() > 0 and DotaTime() >= (3*60) then
                if not utils.InTable(self.BoughtItems, "item_flying_courier") then
                    table.insert(self.PurchaseOrder, 1, "item_flying_courier")
                    -- flying courier is the only item we put in the bought item list,
                    -- wards etc. are not important to store
                    table.insert(self.BoughtItems, "item_flying_courier")
                end
            end

            -- since smokes are not being used we don't buy them yet
            local wards = GetItemStockCount("item_ward_observer")

            -- buy all available wards
            local bot = GetBot()
            local item = utils.HaveItem(bot, "item_ward_observer")
            local currWardCount = 0
            if item ~= nil then
                currWardCount = item:GetCurrentCharges()
            end

            if wards > 0 and currWardCount < 1 then
                while wards > 0 do
                    table.insert(self.PurchaseOrder, 1, "item_ward_observer")
                    wards = wards - 1
                end
            end

            -- next support item think in 10 sec
            self.LastSupportThink = RealTime()
        end
    end
end

function X:GetPurchaseOrder()
    return self.PurchaseOrder
end

function X:UpdatePurchaseOrder()
    -- Still starting items to buy?
    if (#self.StartingItems == 0) then
        -- Still core items to buy?
        if( #self.CoreItems == 0) then
            -- Otherwise consider buying extension items
            local tDelta = RealTime() - self.LastExtensionThink
            -- last think over 10s ago?
            if tDelta > 10.0 then
                -- consider buying extensions
                self:ConsiderBuyingExtensions(bot)
                -- update last think time
                self.LastExtensionThink = RealTime()
            end
        else
            -- get next starting item in parts
            local toBuy = {}
            items:GetItemsTable(toBuy, items[self.CoreItems[1]])
            -- single items will always be bought
            if #toBuy > 1 then
                -- go through bought items
                for _,p in pairs(self.BoughtItems) do
                    -- get parts of this bought item
                    local compare = {}
                    items:GetItemsTable(compare, items[p])
                    -- more than 1 part?
                    if #compare > 1 then
                        local remove = true
                        -- check if all parts of the bought item are in the item to buy
                        for _,k in pairs(compare) do
                            if not utils.InTable(toBuy, k) then
                                remove = false
                            end
                        end
                        -- if so remove all parts bought parts from the item to buy
                        if remove then
                            for _,k in pairs(compare) do
                                local pos = utils.PosInTable(toBuy, k)
                                table.remove(toBuy, pos)
                            end
                            -- remove the bought item also (since we are going to use it in the new item)
                            local pos = utils.PosInTable(self.BoughtItems, p)
                            table.remove(self.BoughtItems, pos)
                        end
                    else
                        -- check if item was already bought
                        if utils.InTable(toBuy, p) then
                            -- if so remove it from the item to buy
                            local pos = utils.PosInTable(toBuy, p)
                            table.remove(toBuy, pos)
                            -- remove it from bought items
                            pos = utils.PosInTable(self.BoughtItems, p)
                            table.remove(self.BoughtItems, pos)
                        end
                    end
                end
            end
            -- put all parts that we still need to buy in purchase order
            for _,p in pairs(toBuy) do
                table.insert(self.PurchaseOrder, p)
            end
            -- insert the item to buy in bought items, remove it from starting items
            table.insert(self.BoughtItems, self.CoreItems[1])
            table.remove(self.CoreItems, 1)
        end
    else
        -- get next starting item in parts
        local toBuy = {}
        items:GetItemsTable(toBuy, items[self.StartingItems[1]])
        -- single items will always be bought
        if #toBuy > 1 then
            -- go through bought items
            for _,p in pairs(self.BoughtItems) do
                -- get parts of this bought item
                local compare = {}
                items:GetItemsTable(compare, items[p])
                -- more than 1 part?
                if #compare > 1 then
                    local remove = true
                    -- check if all parts of the bought item are in the item to buy
                    for _,k in pairs(compare) do
                        if not utils.InTable(toBuy, k) then
                            remove = false
                        end
                    end
                    -- if so remove all parts bought parts from the item to buy
                    if remove then
                        for _,k in pairs(compare) do
                            local pos = utils.PosInTable(toBuy, k)
                            table.remove(toBuy, pos)
                        end
                        -- remove the bought item also (since we are going to use it in the new item)
                        local pos = utils.PosInTable(self.BoughtItems, p)
                        table.remove(self.BoughtItems, pos)
                    end
                else
                    -- check if item was already bought
                    if utils.InTable(toBuy, p) then
                        -- if so remove it from the item to buy
                        local pos = utils.PosInTable(toBuy, p)
                        table.remove(toBuy, pos)
                        -- remove it from bought items
                        pos = utils.PosInTable(self.BoughtItems, p)
                        table.remove(self.BoughtItems, pos)
                    end
                end
            end
        end
        -- put all parts that we still need to buy in purchase order
        for _,p in pairs(toBuy) do
            table.insert(self.PurchaseOrder, p)
        end
        -- insert the item to buy in bought items, remove it from starting items
        table.insert(self.BoughtItems, self.StartingItems[1])
        table.remove(self.StartingItems, 1)
    end
end

function X:ConsiderSellingItems(bot)
    local ItemsToConsiderSelling = {}
    local DontSell = {}

    if utils.NumberOfItems(bot) == 6 and utils.NumberOfItemsInBackpack(bot) == 3 then
        local inventory = {}
        -- Store name of the items in a table
        for i = 0,8,1 do
            local item = bot:GetItemInSlot(i)
            table.insert(inventory, item:GetName())
        end

        -- put all items we still want to buy (combined) and all items we bought already (combined) in a table
        local toBuyCombined = {}
        for _,k in pairs(self.StartingItems) do
            local toBuySingle = {}
            items:GetItemsTable(toBuySingle, items[k])
            if #toBuySingle > 1 then
                items:GetItemsTable(toBuyCombined, items[k])
            end
        end
        for _,k in pairs(self.CoreItems) do
            local toBuySingle = {}
            items:GetItemsTable(toBuySingle, items[k])
            if #toBuySingle > 1 then
                items:GetItemsTable(toBuyCombined, items[k])
            end
        end
        for _,k in pairs(self.BoughtItems) do
            local toBuySingle = {}
            items:GetItemsTable(toBuySingle, items[k])
            if #toBuySingle > 1 then
                items:GetItemsTable(toBuyCombined, items[k])
            end
        end

        for _,k in pairs(inventory) do
            local toRemove = -1
            -- check through items to buy
            for _,p in pairs(toBuyCombined) do
                if k == p then
                    -- if inventory item is in there save pos
                    toRemove = utils.PosInTable(toBuyCombined, p)
                end
            end
            -- pos saved -> remove that item
            if toRemove > 0 then
                table.remove(toBuyCombined, toRemove)
            else
                -- otherwise we can potentially sell it
                table.insert(ItemsToConsiderSelling, k)
            end
        end

        local ItemToSell
        local iItemValue = 1000000
        -- Now check which item is least valuable to us
        for _,p in pairs(ItemsToConsiderSelling) do
            local iVal = items:GetItemValueNumber(p)
            -- If the value of this item is lower change handle
            if iVal < iItemValue and iVal > 0 then
                ItemToSell = p
            end
        end
        -- Sell if we found an item to sell
        if ItemToSell ~= nil then
            local pos = bot:FindItemSlot(ItemToSell)
            bot:ActionImmediate_SellItem(bot:GetItemInSlot(pos))
        end
    end
end

function X:ConsiderBuyingExtensions()
    local bot = GetBot()

    -- Start with 5s of time to do damage
    local DamageTime = 5

    -- Get total disable time
    DamageTime = DamageTime + (enemyData.GetEnemyTeamSlowDuration() / 2)
    DamageTime = DamageTime + enemyData.GetEnemyTeamStunDuration()
    local SilenceCount = enemyData.GetEnemyTeamNumSilences()
    local TrueStrikeCount = enemyData.GetEnemyTeamNumTruestrike()

    local DamagePhysical, DamageMagical, DamagePure = enemyData.GetEnemyDmgs(bot:GetPlayerID(), 10.0)

    --[[
        The damage numbers should be calculated, also the disable time and the silence counter should work
        Now there needs to be a decision process for what items should be bought exactly.
        That should account for retreat abilities, what damage is more dangerous to us,
        how much disable and most imporantly what type of disable the enemy has.
        Should also consider how fast the enemy is so that we can buy items to chase.
    --]]

    -- Determine if we have a retreat ability that we must be able to use (blinks etc)
    local retreatAbility
    if getHeroVar("HasMovementAbility") ~= nil then
        retreatAbility = true
    else
        retreatAbility = false
    end

    -- Remove evasion items if # true strike enemies > 1
    if TrueStrikeCount > 0 then
        if utils.InTable(self.ExtensionItems.DefensiveItems, "item_solar_crest") then
            local ItemIndex = utils.PosInTable(self.ExtensionItems.DefensiveItems, "item_solar_crest")
            table.remove(self.ExtensionItems.DefensiveItems, ItemIndex)
        elseif utils.InTable(self.ExtensionItems.OffensiveItems, "item_butterfly") then
            local ItemIndex = utils.PosInTable(self.ExtensionItems.DefensiveItems, "item_butterfly")
            table.remove(self.ExtensionItems.DefensiveItems, ItemIndex)
        end
    end

    -- Remove magic immunty if not needed
    if DamageMagical > DamagePhysical then
        if utils.InTable(self.ExtensionItems.DefensiveItems, "item_hood_of_defiance") or utils.InTable(self.ExtensionItems.DefensiveItems, "item_pipe") then
            --utils.myPrint(" Considering magic damage reduction")
        elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_black_king_bar") then
            if retreatAbility and SilenceCount > 1 then
                --utils.myPrint(" Considering buying bkb")
            elseif SilenceCount > 2 or DamageTime > 8 then
                --utils.myPrint(" Considering buying bkb")
            else
                local ItemIndex = utils.PosInTable(self.ExtensionItems.DefensiveItems, "item_black_king_bar")
                table.remove(self.ExtensionItems.DefensiveItems, ItemIndex)
                --utils.myPrint(" Removing bkb")
            end
        end
    elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_black_king_bar") then
        if retreatAbility and SilenceCount > 1 then
            if utils.InTable(self.ExtensionItems.DefensiveItems, "item_manta") then
                --utils.myPrint(" Considering buying manta")
            elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_cyclone") then
                --utils.myPrint(" Considering buying euls")
            else
                --utils.myPrint(" Considering buying bkb")
            end
        elseif SilenceCount > 2 then
            if DamageTime > 12 then
                --utils.myPrint(" Considering buying bkb")
            elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_manta") then
                --utils.myPrint(" Considering buying manta")
            elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_cyclone") then
                --utils.myPrint(" Considering buying euls")
            end
        else
            local ItemIndex = utils.PosInTable(self.ExtensionItems.DefensiveItems, "item_black_king_bar")
            table.remove(self.ExtensionItems.DefensiveItems, ItemIndex)
            --utils.myPrint(" Removing bkb")
        end
    else
        -- ToDo: Check if enemy has retreat abilities and consider therefore buying stun/silence

    end
end

-------------------------------------------------------------------------------

return X