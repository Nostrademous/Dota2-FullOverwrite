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
		"item_flask",
		"item_poor_mans_shield",
		"item_quelling_blade"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_boots",
		"item_energy_booster",
		"item_point_booster",
		"item_vitality_booster",
		"item_energy_booster",
		"item_ring_of_regen",
		"item_sobi_mask",
		"item_recipe_soul_ring",
		"item_recipe_bloodstone",
		"item_platemail",
		"item_void_stone",
		"item_ring_of_health",
		"item_energy_booster",
		"item_vitality_booster",
		"item_reaver",
		"item_recipe_heart",
		"item_platemail",
		"item_mystic_staff",
		"item_recipe_shivas_guard",
		"item_vitality_booster",
		"item_staff_of_wizardry",
		"item_staff_of_wizardry",
		"item_point_booster",
		"item_vitality_booster",
		"item_energy_booster",
		"item_mystic_staff",
		"item_cloak",
		"item_ring_of_health",
		"item_ring_of_regen",
		"item_branches",
		"item_ring_of_regen",
		"item_recipe_headdress",
		"item_recipe_pipe"
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
		"item_flask",
		"item_poor_mans_shield",
		"item_quelling_blade"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_boots",
		"item_energy_booster",
		"item_point_booster",
		"item_vitality_booster",
		"item_energy_booster",
		"item_ring_of_regen",
		"item_sobi_mask",
		"item_recipe_soul_ring",
		"item_recipe_bloodstone",
		"item_platemail",
		"item_void_stone",
		"item_ring_of_health",
		"item_energy_booster",
		"item_vitality_booster",
		"item_reaver",
		"item_recipe_heart",
		"item_platemail",
		"item_mystic_staff",
		"item_recipe_shivas_guard",
		"item_vitality_booster",
		"item_staff_of_wizardry",
		"item_staff_of_wizardry",
		"item_point_booster",
		"item_vitality_booster",
		"item_energy_booster",
		"item_mystic_staff",
		"item_cloak",
		"item_ring_of_health",
		"item_ring_of_regen",
		"item_branches",
		"item_ring_of_regen",
		"item_recipe_headdress",
		"item_recipe_pipe"
	},
	ExtensionItems = {
		{
		},
		{
		}
	}
}

local ItemsToBuyAsOfflane = {
	StartingItems = {
		"item_flask",
		"item_poor_mans_shield",
		"item_quelling_blade"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_boots",
		"item_energy_booster",
		"item_point_booster",
		"item_vitality_booster",
		"item_energy_booster",
		"item_ring_of_regen",
		"item_sobi_mask",
		"item_recipe_soul_ring",
		"item_recipe_bloodstone",
		"item_platemail",
		"item_void_stone",
		"item_ring_of_health",
		"item_energy_booster",
		"item_vitality_booster",
		"item_reaver",
		"item_recipe_heart",
		"item_platemail",
		"item_mystic_staff",
		"item_recipe_shivas_guard",
		"item_vitality_booster",
		"item_staff_of_wizardry",
		"item_staff_of_wizardry",
		"item_point_booster",
		"item_vitality_booster",
		"item_energy_booster",
		"item_mystic_staff",
		"item_cloak",
		"item_ring_of_health",
		"item_ring_of_regen",
		"item_branches",
		"item_ring_of_regen",
		"item_recipe_headdress",
		"item_recipe_pipe"
	},
	ExtensionItems = {
		{
		},
		{
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
