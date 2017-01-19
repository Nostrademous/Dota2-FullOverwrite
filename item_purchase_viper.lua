-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois, eteran
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

--[[
require( GetScriptDirectory().."/generic_item_purchase" )
--]]

local items = require( GetScriptDirectory().."/items" )
local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

local StartingItems = {
	"item_stout_shield",
	"item_flask",
	"item_faerie_fire",
}

local UtilityItems = { 
	 
}

local CoreItems = {	
	"item_power_treads_agi",
	"item_ring_of_aquila",
	"item_mekansm"
}

local ExtensionItems = {	
	{
		"item_assault" 
	},
	{	
		"item_heart"
	} 
}

ToBuy = item_purchase:new()

-- create a 2nd layer of isolation so this bot has it's own instance not shared with other bots
function ToBuy:new(o)
	o = o or item_purchase:new(o)
	setmetatable(o, self)
	self.__index = self
	return o
end

-- we need these so if multiple bots inherit from the generic class they don't get mixed with each other
local myPurchaseOrder = {}
local myBoughtItems = {}

viperBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
viperBuy.PurchaseOrder = myPurchaseOrder
viperBuy.BoughtItems = myBoughtItems

viperBuy:setStartingItems(StartingItems)
viperBuy:setUtilityItems(UtilityItems)
viperBuy:setCoreItems(CoreItems)
viperBuy:setExtensionItems(ExtensionItems[1],ExtensionItems[2])

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()

	local npcBot = GetBot()

	viperBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
