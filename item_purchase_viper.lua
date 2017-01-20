-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois, eteran
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

--[[
require( GetScriptDirectory().."/generic_item_purchase" )
--]]

local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

local ItemsToBuyAsHardCarry = {
	StartingItems = {
		"item_stout_shield",
		"item_flask",
		"item_faerie_fire",
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
		"item_ring_of_aquila",
		"item_mekansm"
	},
	ExtensionItems = {
		{
		"item_assault"
		},
		{
		"item_heart"
		}
	}
}
local ItemsToBuyAsMid = {
	StartingItems = {
		"item_stout_shield",
		"item_flask",
		"item_faerie_fire",
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
		"item_ring_of_aquila",
		"item_mekansm"
	},
	ExtensionItems = {
		{
		"item_assault"
		},
		{
		"item_heart"
		}
	}
}
local ItemsToBuyAsOfflane = {
		StartingItems = {
			"item_stout_shield",
			"item_flask",
			"item_faerie_fire",
		},
		UtilityItems = {
			"item_flask"
		},
		CoreItems = {
			"item_power_treads_agi",
			"item_ring_of_aquila",
			"item_mekansm"
		},
		ExtensionItems = {
			{
			"item_assault"
			},
			{
			"item_heart"
			}
		}
	}
local ItemsToBuyAsSupport = {}
local ItemsToBuyAsJungler = {}
local ItemsToBuyAsRoamer = {}

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
local myStartingItems = {}
local myUtilityItems = {}
local myCoreItems = {}
local myExtensionItems = {
	OffensiveItems = {},
	DefensiveItems = {}
}

local init = false

vpBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
vpBuy.PurchaseOrder = myPurchaseOrder
vpBuy.BoughtItems = myBoughtItems
vpBuy.StartingItems = myStartingItems
vpBuy.UtilityItems = myUtilityItems
vpBuy.CoreItems = myCoreItems
vpBuy.ExtensionItems = myExtensionItems

vpBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
vpBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
vpBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
vpBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
vpBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
vpBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	local npcBot = GetBot()

	if not init then
			-- init the tables
			init = vpBuy:InitTable()
	end

	vpBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
