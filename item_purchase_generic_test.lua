-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/secret_shop_generic" )
local utils = require( GetScriptDirectory().."/utility" )
local items = require(GetScriptDirectory().."/items" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

enemyData = require( GetScriptDirectory().."/enemy_data" )

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
local X = {}

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

-------------------------------------------------------------------------------
-- Init
-------------------------------------------------------------------------------

function X:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

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

function X:Think(npcBot)
	local tDelta = RealTime() - self.LastThink
	-- throttle think for better performance
	if tDelta > 0.25 then
		-- If bot nothing bail
		if npcBot == nil then return end

		if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end

		-- Initialization
		self:Init(npcBot)

		-- If there's an item to be purchased already bail
		if ( (npcBot:GetNextItemPurchaseValue() > 0) and (npcBot:GetGold() < npcBot:GetNextItemPurchaseValue()) ) then return end

		-- If we want a new item we determine which one first
		if #self.PurchaseOrder == 0 then
			self:UpdatePurchaseOrder(npcBot)
		end

		-- Consider selling items
		-- self:ConsiderSellingItems(npcBot)

		-- Get the next item
		local sNextItem = self.PurchaseOrder[1]

		if sNextItem ~= nil then
			-- Set cost
			npcBot:SetNextItemPurchaseValue(GetItemCost(sNextItem))

			-- Enough gold -> buy, remove
			if(npcBot:GetGold() >= GetItemCost(sNextItem)) then
				-- Next item only available in secret shop?
				if IsItemPurchasedFromSecretShop(sNextItem) then
					local me = getHeroVar("Self")
					if me:GetAction() ~= constants.ACTION_SECRETSHOP then
						print(getHeroVar("Name"), " - ", sNextItem, " is ONLY available from Secret Shop")
						if ( me:HasAction(constants.ACTION_SECRETSHOP) == false ) then
							me:AddAction(constants.ACTION_SECRETSHOP)
							print(utils.GetHeroName(npcBot), " STARTING TO HEAD TO SECRET SHOP ")
							secret_shop_generic.OnStart()
						end
					end
					local bDone = secret_shop_generic.Think(sNextItem)
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
			end
		end
		self.LastThink = RealTime()
	end
end

-------------------------------------------------------------------------------
-- Utility functions
-------------------------------------------------------------------------------

function X:InitTable()
	-- Don't do this before the game starts
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then	return false end
	-- Tables already initialized, bail
	if #self.StartingItems > 0
		or #self.UtilityItems > 0
		or #self.CoreItems > 0
		or #self.ExtensionItems > 0 then
		return false
	else
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
end

function X:Init(npcBot)
	local bInit = getHeroVar("ItemPurchaseInitialized")
	if bInit == nil then
		print(getHeroVar("Name"), " - Initializing Item Purchase class - Role: ", getHeroVar("Role"))
		setHeroVar("ItemPurchaseInitialized", true)
	end
end

function X:UpdatePurchaseOrder(npcBot)
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
				-- since smokes are not being used we don't buy them yet
				local wards = GetItemStockCount("item_ward_observer")
				local tomes = GetItemStockCount("item_tome_of_knowledge")
				local flyingCour = GetItemStockCount("item_flying_courier")
				-- buy all available wards
				if wards > 0 then
					while wards > 0 do
						table.insert(self.PurchaseOrder, 1, "item_ward_observer")
						wards = wards - 1
					end
				end
				-- buy all available tomes
				if tomes > 0 then
					while tomes > 0 do
						table.insert(self.PurchaseOrder, 1, "item_tome_of_knowledge")
						tomes = tomes - 1
					end
				end
				-- buy flying courier if available (only 1x)
				if flyingCour > 0 then
					if not utils.InTable(self.BoughtItems, "item_flying_courier") then
						table.insert(self.PurchaseOrder, 1, "item_flying_courier")
					end
				end
			else
				-- we have no courier, buy it
				table.insert(self.PurchaseOrder, 1, "item_courier")
			end
			self.LastSupportThink = RealTime()
		end
	end
	-- Still starting items to buy?
	if (#self.StartingItems == 0) then
		-- Still core items to buy?
		if( #self.CoreItems == 0) then
			-- Otherwise consider buying extension items
			print("FIXME: if enemy_data is fixed enable buying extensions")
			--[[
			Not active until enemy_data problem is solved
			self:ConsiderBuyingExtensions(npcBot)
			--]]
		else
			-- Put the core items in the purchase order
			local newItem = {}
			items:GetItemsTable(newItem, self.CoreItems[1])
			for _,p in pairs(newItem) do
				table.insert(self.PurchaseOrder, p)
			end
			-- Remove entry
			table.insert(self.BoughtItems, self.CoreItems[1])
			table.remove(self.CoreItems, 1)
		end
	else
		-- Put the starting items in the purchase order
		local newItem = {}
		items:GetItemsTable(newItem, self.StartingItems[1])
		for _,p in pairs(newItem) do
			table.insert(self.PurchaseOrder, p)
		end
		-- Remove entry
		table.insert(self.BoughtItems, self.StartingItems[1])
		table.remove(self.StartingItems, 1)
	end
end

function X:ConsiderSellingItems(bot)
	--[[
	Idea: Check if items we want to buy need the item,
	 			if not sell it. (E.g. two branches in inventory, we want to buy stick)
				Check both items that are still going to be bought (starting, core)
				as well as already bought items
	--]]
	local ItemsToConsiderSelling = {}

	if utils.NumberOfItems(bot) == 6 then
		print(getHeroVar("Name").." - Considering selling items")
		local items = {}
		-- Store name of the items in a table
		for i = 0,5,1 do
			local item = bot:GetItemInSlot(i)
			table.insert(items, item)
		end

		for _,p in pairs(items) do
			local bSell = true
			-- Check through all starting items
			for _,k in pairs(self.StartingItems) do
				-- Assembled item?
				if #items[k] > 1 then
					-- If item is part of an item we want to buy then don't sell it
					if utils.InTable(item[k], p:GetName()) then
						bSell = false
					end
				end
			end
			-- Same for core items
			for _,k in pairs(self.CoreItems) do
				-- Assembled item?
				if #items[k] > 1 then
					if utils.InTable(item[k], p:GetName()) then
						bSell = false
					end
				end
			end
			-- Same for bought items (parts probably still in purchase queue or stash)
			for _,k in pairs(self.BoughtItems) do
				-- Assembled item?
				if #items[k] > 1 then
					if utils.InTable(item[k], p:GetName()) then
						bSell = false
					end
				end
			end
			-- Do we really want to sell the item?
			if bSell then
				print("Considering selling "..p:GetName())
				table.insert(ItemsToConsiderSelling, p)
			end
		end

		local hItemToSell
		local iItemValue = 1000000
		-- Now check which item is least valuable to us
		for _,p in pairs(ItemsToConsiderSelling) do
			local iVal = items.GetItemValueNumber(p:GetName())
			-- If the value of this item is lower change handle
			if iVal < iItemValue and iVal > 0 then
				hItemToSell = p
			end
		end
		print(hItemToSell:GetName().." selling")
		-- Sell if we found an item to sell
		if hItemToSell ~= nil then
			bot:Action_SellItem(hItemToSell)
		end
	end
end

function X:ConsiderBuyingExtensions(bot)
	--[[
	ToDo: Change how we fetch enemy information, the way it's currently done
				is either slow or might not even work at all. Wait for new version of enemy_data.
	--]]

	-- Start with 5s of time to do damage
	local DamageTime = 5
	local SilenceCount
	local TrueStrikeCount
	-- Get total disable time
	for p = 1, 5, 1 do
		if enemyData.Enemies[p].obj ~= nil then
			DamageTime = DamageTime + (enemyData.Enemies[p].obj:GetSlowDuration(true) / 2)
			DamageTime = DamageTime + enemyData.Enemies[p].obj:GetStunDuration(true)
			if enemyData.Enemies[p].obj:HasSilence() then
				SilenceCount = SilenceCount + 1
			elseif enemyData.Enemies[p].obj:IsUnableToMiss() then
				TrueStrikeCount = TrueStrikeCount +1
			end
			print(utils.GetHeroName(enemyData.Enemies[p].obj).." has "..DamageTime.." seconds of disable")
		end
	end
	print(getHeroVar("Name").." - Total # of silences: "..SilenceCount.." enemies with true strike: "..TrueStrikeCount)
		-- Stores the possible damage over 5s + stun/slow duration from all enemies
	local DamageMagicalPure
	local DamagePhysical
	-- Get possible damage (physical/magical+pure)
	for p = 1, 5, 1 do
		if enemyData.Enemies[p].obj ~= nil then
			DamageMagicalPure = DamageMagicalPure + enemyData.Enemies[p].obj:GetEstimatedDamageToTarget(true, bot, DamageTime, DAMAGE_TYPE_MAGICAL)
			DamageMagicalPure = DamageMagicalPure + enemyData.Enemies[p].obj:GetEstimatedDamageToTarget(true, bot, DamageTime, DAMAGE_TYPE_PURE)
			DamagePhysical = DamagePhysical + enemyData.Enemies[p].obj:GetEstimatedDamageToTarget(true, bot, DamageTime, DAMAGE_TYPE_PHYSICAL)
			print(utils.GetHeroName(enemyData.Enemies[p].obj).." deals "..DamageMagicalPure.." magical and pure damage and "..DamagePhysical.." physical damage (5s)")
		end
	end

	--[[
		The damage numbers should be calculated, also the disable time and the silence counter should work
		Now there needs to be a decision process for what items should be bought exactly.
		That should account for retreat abilities, what damage is more dangerous to us,
		how much disable and most imporantly what type of disable the enemy has.
		Big ToDo: figure out how to get the number of magic immunity piercing disables the enemy has
	--]]

	-- Determine if we have a retreat ability that we must be able to use (blinks etc)
	local retreatAbility
	if getHeroVar("HasMovementAbility") ~= nil then
		retreatAbility = true
		print(getHeroVar("Name").." - Has retreat")
	else
		retreatAbility = false
		print(getHeroVar("Name").." - Has no retreat")
	end

	-- Remove evasion items if # true strike enemies > 1
	if TrueStrikeCount > 0 then
		if utils.InTable(self.ExtensionItems.DefensiveItems, "item_solar_crest") then
			local ItemIndex = utils.PosInTable(self.ExtensionItems.DefensiveItems, "item_solar_crest")
			table.remove(self.ExtensionItems.DefensiveItems, ItemIndex)
			print(getHeroVar("Name").." - Removing evasion")
		elseif utils.InTable(self.ExtensionItems.OffensiveItems, "item_butterfly") then
			local ItemIndex = utils.PosInTable(self.ExtensionItems.DefensiveItems, "item_butterfly")
			table.remove(self.ExtensionItems.DefensiveItems, ItemIndex)
			print(getHeroVar("Name").." - Removing evasion")
		end
	end

	-- Remove magic immunty if not needed
	if DamageMagicalPure > DamagePhysical then
		if utils.InTable(self.ExtensionItems.DefensiveItems, "item_hood_of_defiance") or InTable(self.ExtensionItems.DefensiveItems, "item_pipe") then
			print(getHeroVar("Name").." - Considering magic damage reduction")
		elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_black_king_bar") then
			if retreatAbility and SilenceCount > 1 then
				print(getHeroVar("Name").." - Considering buying bkb")
			elseif SilenceCount > 2 or DamageTime > 8 then
				print(getHeroVar("Name").." - Considering buying bkb")
			else
				local ItemIndex = utils.PosInTable(self.ExtensionItems.DefensiveItems, "item_black_king_bar")
				table.remove(self.ExtensionItems.DefensiveItems, ItemIndex)
				print(getHeroVar("Name").." - Removing bkb")
			end
		end
	elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_black_king_bar") then
		if retreatAbility and SilenceCount > 1 then
			if utils.InTable(self.ExtensionItems.DefensiveItems, "item_manta") then
				print(getHeroVar("Name").." - Considering buying manta")
			elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_cyclone") then
				print(getHeroVar("Name").." - Considering buying euls")
			else
				print(getHeroVar("Name").." - Considering buying bkb")
			end
		elseif SilenceCount > 2 then
			if DamageTime > 12 then
				print(getHeroVar("Name").." - Considering buying bkb")
			elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_manta") then
				print(getHeroVar("Name").." - Considering buying manta")
			elseif utils.InTable(self.ExtensionItems.DefensiveItems, "item_cyclone") then
				print(getHeroVar("Name").." - Considering buying euls")
			end
		else
			local ItemIndex = utils.PosInTable(self.ExtensionItems.DefensiveItems, "item_black_king_bar")
			table.remove(self.ExtensionItems.DefensiveItems, ItemIndex)
			print(getHeroVar("Name").." - Removing bkb")
		end
	else
		-- ToDo: Check if enemy has retreat abilities and consider therefore buying stun/silence

	end
end

-------------------------------------------------------------------------------

return X
