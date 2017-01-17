-------------------------------------------------------------------------------
--- AUTHOR: dralois
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "item_purchase_generic_test", package.seeall )

require( GetScriptDirectory().."/role"  )
local utils = require( GetScriptDirectory().."/utility" )
local items = require(GetScriptDirectory().."/items" )
local myEnemies = require( GetScriptDirectory().."/enemy_data" )

--[[
	The idea is that you get a list of starting items, utility items, core items and extension items.
	This class then decides which items to buy, considering what and how much damage the enemy mostly does,
	if we want offensive or defensive items and if we need anything else like consumables
--]]

-------------------------------------------------------------------------------
-- Declarations
-------------------------------------------------------------------------------

local X = {	startingItems = {}, 
					utilityItems = {}, 
					coreItems = {}, 
					extentionItems = {	offensiveItems={}, 
													defensiveItems={}	}	}				

local X.PurchaseOrder = {}				
				
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

function X:getStartingItems()
	return self.startingItems
end

function X:setStartingItems(items)
	self.startingItems = items
end

function X:getUtilityItems()
	return self.utilityItems
end

function X:setUtilityItems(items)
  self.utilityItems = items
end

function X:getCoreItems()
	return self.coreItems
end

function X:setCoreItems(items)
	self.coreItems = items
end

function X:getExtensionItems()
	return self.extensionItems[1], self.extensionItems[2]
end

function X:setExtensionItems(offensiveItems, defensiveItems)
	self.extensionItems = {offensiveItems, defensiveItems)
end

-------------------------------------------------------------------------------
-- Think
--[[
	ToDo: Selling items for better ones      
--]]
-------------------------------------------------------------------------------

function X:Think(npcBot)

	-- If bot nothing bail
	if npcBot == nil then return end
	
	-- If game not in progress bail
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end

	-- If there's an item to be purchased already bail
	if ( (npcBot:GetNextItemPurchaseValue() > 0) and (npcBot:GetGold() < npcBot:GetNextItemPurchaseValue()) ) then return end
	
	-- If we want a new item we determine which one first
	self:UpdatePurchaseOrder(npcBot)
	
	-- Get the next item
	local sNextItem = self.PurchaseOrder[1]
	
	-- Set cost
	npcBot:SetNextItemPurchaseValue(GetItemCost(sNextItem))
	
	-- Enough gold -> buy, remove
	if(npcBot:GetGold() >= GetItemCost(sNextItem)) then
		npcBot:Action_PurchaseItem(sNextItem)
		table.remove(self.PurchaseOrder, 1)
		npcBot:SetNextItemPurchaseValue(0)
	end
end

-------------------------------------------------------------------------------
-- Utilitly functions
-------------------------------------------------------------------------------

local function UpdatePurchaseOrder(npcBot)
	-- Core (doesn't buy utility items such as wards)
	if npcBot.IsCore	
		-- Still starting items to buy?
		if (#self.startingItems == 0) then			
			-- Still core items to buy?
			if( #self.coreItems == 0) then			
				-- Otherwise consider buying extension items
				self:ConsiderBuyingExtensions(npcBot)
			else
				-- Put the core items in the purchase order
				for _,p in pairs(items[self.coreItems[1]) do
					self.PurchaseOrder[#PurchaseOrder+1] = p
				end
				-- Remove entry
				table.remove(self.coreItems, 1)
			end      
		else
			-- Put the core items in the purchase order
			for _,p in pairs(items[self.startingItems[1]) do
				self.PurchaseOrder[#PurchaseOrder+1] = p
			end
			-- Remove entry
			table.remove(self.startingItems, 1)
		end
	-- Support
	else
	--[[
	Idea: 	buy starting items (always, should have courier and wards if hard support),
				then buy either core / extension items unless there is more important utility to buy.
				Upgrade courier at 3:00, buy all available wards and if needed detection (no smoke).
				
	ToDo: 	Functions to check if item in stock 
				Function to return number of invisible enemies.
				Buying consumable items like raindrops if there is a lot of magical damage
				Buying salves for cores?          
	--]]
	end
end

local function ConsiderBuyingExtensions(bot)
	-- Start with 5s of time to do damage
	local DamageTime = 5
	local SilenceCount
	local TrueStrikeCount
	-- Get total disable time
	for p = 1, 5, 1 do		
		DamageTime = DamageTime + (myEnemies.Enemies[p].obj:GetSlowDuration(true) / 2)
		DamageTime = DamageTime + myEnemies.Enemies[p].obj:GetStunDuration(true)
		if myEnemies.Enemies[p].obj:HasSilence then
			SilenceCount = SilenceCount + 1
		elseif myEnemies.Enemies[p].obj:IsUnableToMiss then
			TrueStrikeCount = TrueStrikeCount +1
		end
		print(utils.GetHeroName(myEnemies.Enemies[p].obj).." has "..DamageTime.." seconds of disable")
	end
	print("Total # of silences: "..SilenceCount.." enemies with true strike: "..TrueStrikeCount)
		-- Stores the possible damage over 5s + stun/slow duration from all enemies
	local DamageMagicalPure
	local DamagePhysical
	-- Get possible damage (physical/magical+pure)
	for p = 1, 5, 1 do
		DamageMagicalPure = DamageMagicalPure + myEnemies.Enemies[p].obj:GetEstimatedDamageToTarget(true, bot, DamageTime, DAMAGE_TYPE_MAGICAL)
		DamageMagicalPure = DamageMagicalPure + myEnemies.Enemies[p].obj:GetEstimatedDamageToTarget(true, bot, DamageTime, DAMAGE_TYPE_PURE)
		DamagePhysical = DamagePhysical + myEnemies.Enemies[p].obj:GetEstimatedDamageToTarget(true, bot, DamageTime, DAMAGE_TYPE_PHYSICAL)
		print(utils.GetHeroName(myEnemies.Enemies[p].obj).." deals "..DamageMagicalPure.." magical and pure damage and "..DamagePhysical.." physical damage (5s)")		
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
		print("Has retreat")
	else
		retreatAbility = false
		print("Has no retreat")
	end
	
	-- Remove evasion items if # true strike enemies > 1
	if TrueStrikeCount > 0 then
		if InTable(self.extensionItems.defensiveItems, "item_solar_crest") then
			local ItemIndex = PosInTable(self.extensionItems.defensiveItems, "item_solar_crest")
			table.remove(self.extensionItems.defensiveItems, ItemIndex)
			print("Removing evasion")
		elseif InTable(self.extensionItems.offensiveItems, "item_butterfly") then
			local ItemIndex = PosInTable(self.extensionItems.defensiveItems, "item_butterfly")
			table.remove(self.extensionItems.defensiveItems, ItemIndex)
			print("Removing evasion")
		end
	end
	
	-- Remove magic immunty if not needed
	if DamageMagicalPure > DamagePhysical
		if InTable(self.extensionItems.defensiveItems, "item_hood_of_defiance") or InTable(self.extensionItems.defensiveItems, "item_pipe") then
			print("Considering magic damage reduction")
		elseif InTable(self.extensionItems.defensiveItems, "item_black_king_bar")
			if retreatAbility and SilenceCount > 1 then
				print("Considering buying bkb")
			elseif SilenceCount > 2 or DamageTime > 8 then
				print("Considering buying bkb")
			else
				local ItemIndex = PosInTable(self.extensionItems.defensiveItems, "item_black_king_bar")
				table.remove(self.extensionItems.defensiveItems, ItemIndex)
				print("Removing bkb")
			end
		end
	elseif InTable(self.extensionItems.defensiveItems, "item_black_king_bar")
		if retreatAbility and SilenceCount > 1 then
			if InTable(self.extensionItems.defensiveItems, "item_manta")
				print("Considering buying manta")
			elseif InTable(self.extensionItems.defensiveItems, "item_euls")
				print("Considering buying euls")
			else
				print("Considering buying bkb")
			end
		elseif SilenceCount > 2 
			if DamageTime > 12 then	
				print("Considering buying bkb")
			elseif InTable(self.extensionItems.defensiveItems, "item_manta")
				print("Considering buying manta")
			elseif InTable(self.extensionItems.defensiveItems, "item_euls")
				print("Considering buying euls")
			end
		else
			local ItemIndex = PosInTable(self.extensionItems.defensiveItems, "item_black_king_bar")
			table.remove(self.extensionItems.defensiveItems, ItemIndex)
			print("Removing bkb")
		end
	else
		-- ToDo: Check if enemy has retreat abilities and consider therefore buying stun/silence
		
	end
end

-------------------------------------------------------------------------------
-- Table functions (export to utility.lua probably)
-------------------------------------------------------------------------------

local function InTable (tab, val)
    for index, value in ipairs (tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function PosInTable(tab, val)
	for index,value in ipairs(tab) do
		if value = val then
			return index
		end
	end
	
	return -1
end

-------------------------------------------------------------------------------

return X

for k,v in pairs( item_purchase_generic ) do _G._savedEnv[k] = v end