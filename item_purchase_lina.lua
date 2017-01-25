-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

local ItemsToBuyAsHardCarry = {
	StartingItems = {
		"item_null_talisman",
		"item_faerie_fire",
		"item_branches",
		"item_bottle"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_phase_boots",
		"item_cyclone",
		"item_blink",
		"item_aether_lens",
		"item_ultimate_scepter"
	},
	ExtensionItems = {
		{
		},
		{
		}
	}
}
local ItemsToBuyAsMid = {
	StartingItems = {
		"item_null_talisman",
		"item_faerie_fire",
		"item_branches",
		"item_bottle"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_phase_boots",
		"item_cyclone",
		"item_blink",
		"item_aether_lens",
		"item_ultimate_scepter"
	},
	ExtensionItems = {
		{
		},
		{
		}
	}
}
local ItemsToBuyAsOfflane = {}
local ItemsToBuyAsSupport = {
	StartingItems = {
		"item_tango",
		"item_tango",
		"item_clarity",
		"item_clarity",
		"item_branches",
		"item_branches"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_magic_wand",
		"item_arcane_boots",
		"item_cyclone",
		"item_force_staff",
		"item_ultimate_scepter",
		"item_sheepstick"
	},
	ExtensionItems = {
		{
		},
		{
		}
	}
}
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

linaBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
linaBuy.PurchaseOrder = myPurchaseOrder
linaBuy.BoughtItems = myBoughtItems
linaBuy.StartingItems = myStartingItems
linaBuy.UtilityItems = myUtilityItems
linaBuy.CoreItems = myCoreItems
linaBuy.ExtensionItems = myExtensionItems

linaBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
linaBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
linaBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
linaBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
linaBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
linaBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	local npcBot = GetBot()

	if not init then
			-- init the tables
			init = linaBuy:InitTable()
	end

	linaBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
