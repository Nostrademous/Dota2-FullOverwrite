-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/generic_item_purchase" )

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
}

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
}
			
local tableItemsToBuyAsHardCarry = { 
	"item_circlet",
	"item_mantle",
	"item_recipe_null_talisman",
	"item_faerie_fire",
	"item_branches",
	"item_boots",
	"item_blades_of_attack",
	"item_blades_of_attack",
	"item_wind_lace",
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
}

local tableItemsToBuyAsOfflane = {
}

local tableItemsToBuyAsJungler = {
}

local tableItemsToBuyAsRoamer = {
}

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	generic_item_purchase.ItemPurchaseThink(tableItemsToBuyAsMid, tableItemsToBuyAsHardCarry, tableItemsToBuyAsOfflane, tableItemsToBuyAsSupport, tableItemsToBuyAsJungler, tableItemsToBuyAsRoamer)
end

----------------------------------------------------------------------------------------------------