-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

--[[
require( GetScriptDirectory().."/generic_item_purchase" )
--]]

local items = require( GetScriptDirectory().."/items" )
local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

--[[
local tableItemsToBuyAsSupport = {
	"item_tango",
	"item_tango",
	"item_clarity",
	"item_clarity",
	"item_branches",
	"item_branches",
	"item_magic_stick",
	"item_circlet",
	"item_boots",
	"item_energy_booster",
	"item_staff_of_wizardry",
	"item_ring_of_regen",
	"item_recipe_force_staff",
	"item_point_booster",
	"item_staff_of_wizardry",
	"item_ogre_axe",
	"item_blade_of_alacrity",
	"item_mystic_staff",
	"item_ultimate_orb",
	"item_void_stone",
	"item_staff_of_wizardry",
	"item_wind_lace",
	"item_void_stone",
	"item_recipe_cyclone",
	"item_cyclone",
};

local tableItemsToBuyAsMid = {
	"item_circlet",
	"item_mantle",
	"item_recipe_null_talisman",
	"item_faerie_fire",
	"item_branches",
	"item_bottle",
	"item_boots",
	"item_wind_lace",
	"item_blades_of_attack",
	"item_blades_of_attack",
	"item_staff_of_wizardry",
	"item_void_stone",
	"item_recipe_cyclone",
	"item_cyclone",
	"item_blink",
	"item_energy_booster",
	"item_ring_of_health",
	"item_recipe_aether_lens",
	"item_aether_lens",
	"item_point_booster",
	"item_ogre_axe",
	"item_staff_of_wizardry",
	"item_blade_of_alacrity",
	"item_ultimate_orb",
	"item_ultimate_orb",
};

local tableItemsToBuyAsHardCarry = {
	"item_stout_shield",
	"item_tango",
	"item_flask",
	"item_branches",
	"item_quelling_blade",
	"item_ring_of_health",
	"item_boots",
	"item_gloves",
	"item_belt_of_strength", -- completes Treads
	"item_void_stone",
	"item_claymore",
	"item_broadsword", -- completes Battlefury
	"item_ring_of_health",
	"item_vitality_booster", -- completes Vanguard
	"item_blade_of_alacrity",
	"item_boots_of_elves",
	"item_recipe_yasha", -- completes Yasha
	"item_ultimate_orb",
	"item_recipe_manta", -- completes Manta
	"item_javelin",
	"item_belt_of_strength",
	"item_recipe_basher", -- completes Basher
	"item_recipe_abyssal_blade", -- completes Abyssal Blade
	"item_reaver",
	"item_vitality_booster",
	"item_recipe_heart", -- completes Heart
	"item_relic"
};

local tableItemsToBuyAsOfflane = {
}

local tableItemsToBuyAsJungler = {
}

local tableItemsToBuyAsRoamer = {
}
--]]

local ItemsToBuyAsHardCarry = {
	StartingItems = {
		"item_stout_shield",
		"item_tango",
		"item_flask",
		"item_branches",
		"item_branches"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
		"item_bfury",
		"item_vanguard",
		"item_yasha",
		"item_manta",
		"item_abyssal_blade"
	},
	ExtensionItems = {
		{
			"item_butterfly",
			"item_monkey_king_bar"
		},
		{
			"item_heart",
			"item_black_king_bar",
			"item_aghs_scepter"
		}
	}
}

local ItemsToBuyAsMid = {}
local ItemsToBuyAsOfflane = {}
local ItemsToBuyAsSupport = {}
local ItemsToBuyAsJungler = {}
local ItemsToBuyAsRoamer = {}

ToBuy = item_purchase:new(ItemsToBuyAsHardCarry,
													ItemsToBuyAsMid,
													ItemsToBuyAsOfflane,
													ItemsToBuyAsSupport,
													ItemsToBuyAsJungler,
													ItemsToBuyAsRoamer)

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	--[[
	generic_item_purchase.ItemPurchaseThink(tableItemsToBuyAsMid, tableItemsToBuyAsHardCarry, tableItemsToBuyAsOfflane, tableItemsToBuyAsSupport, tableItemsToBuyAsJungler, tableItemsToBuyAsRoamer)
	--]]

	local npcBot = GetBot()

	ToBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
