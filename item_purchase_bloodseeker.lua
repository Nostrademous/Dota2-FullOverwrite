-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/generic_item_purchase" )

local tableItemsToBuyAsJungler = {
	"item_stout_shield",
	"item_quelling_blade",
	"item_tango",
	"item_branches",
	"item_branches",
	"item_ring_of_protection",
	"item_recipe_iron_talon",
	"item_boots",
	"item_gloves",
	"item_belt_of_strength",
	"item_recipe_power_treads",
	"item_shadow_amulet",
	"item_claymore", -- completes shadow blade
	"item_blade_of_alacrity",
	"item_boots_of_elves",
	"item_recipe_yasha", -- completes Yasha
	"item_ogre_axe",
	"item_belt_of_strength",
	"item_recipe_sange", -- completes Sange & Yasha
	"item_ultimate_orb",
	"item_recipe_silver_edge", -- commpletes Silver Edge
	"item_javelin",
	"item_belt_of_strength",
	"item_recipe_basher", -- completes Basher
	"item_stout_shield",
	"item_vitality_booster",
	"item_ring_of_health", -- completes Vanguard
	"item_recipe_abyssal_blade", -- completes Abyssal Blade
	"item_hyperstone",
	"item_chainmail",
	"item_platemail",
	"item_recipe_assault" -- completes AC
};

----------------------------------------------------------------------------------------------------

local tableItemsToBuyAsRoamer = {
}

local tableItemsToBuyAsHardCarry = {
}

local tableItemsToBuyAsOfflane = {
}

local tableItemsToBuyAsMid = {
}

local tableItemsToBuyAsSupport = {
}

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	generic_item_purchase.ItemPurchaseThink(tableItemsToBuyAsMid, tableItemsToBuyAsHardCarry, tableItemsToBuyAsOfflane, tableItemsToBuyAsSupport, tableItemsToBuyAsJungler, tableItemsToBuyAsRoamer)
end

----------------------------------------------------------------------------------------------------
