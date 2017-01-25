-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/generic_item_purchase" )

local tableItemsToBuyAsJungler = {
	"item_slippers",
	"item_circlet",
	"item_tango",
	"item_branches",
	"item_branches",
	"item_recipe_wraith_band",
	"item_boots",
	"item_ring_of_protection",
	"item_sobi_mask", -- completes Ring of Aquila
	"item_gloves",
	"item_boots_of_elves",
	"item_recipe_power_treads", -- completes Power Treads
	"item_boots_of_elves",
	"item_boots_of_elves",
	"item_lifesteal",  -- get lifesteal
	"item_ogre_axe", -- completes Dragon Lance
	"item_gloves",
	"item_mithril_hammer",
	"item_recipe_maelstrom", -- completes Maelstrom
	"item_ring_of_regen",
	"item_staff_of_wizardry",
	"item_recipe_force_staff",
	"item_recipe_hurricane_pike", -- completes Hurricane Pike
	"item_blade_of_alacrity",
	"item_boots_of_elves",
	"item_recipe_yasha", -- completes Yasha
	"item_ogre_axe",
	"item_belt_of_strength",
	"item_recipe_sange", -- completes Sange & Yasha
	"item_hyperstone",
	"item_recipe_mjollnir", -- commpletes Mjollnir
	"item_eagle",
	"item_talisman_of_evasion",
	"item_quarterstaff", -- completes Butterfly
	"item_reaver",
	"item_mithril_hammer" -- completes Satanic
};

----------------------------------------------------------------------------------------------------

local tableItemsToBuyAsRoamer = {
}

local tableItemsToBuyAsHardCarry = {
	"item_slippers",
	"item_circlet",
	"item_tango",
	"item_branches",
	"item_branches",
	"item_recipe_wraith_band",
	"item_boots",
	"item_ring_of_protection",
	"item_sobi_mask", -- completes Ring of Aquila
	"item_gloves",
	"item_boots_of_elves",
	"item_recipe_power_treads", -- completes Power Treads
	"item_boots_of_elves",
	"item_boots_of_elves",
	"item_ogre_axe", -- completes Dragon Lance
	"item_gloves",
	"item_mithril_hammer",
	"item_recipe_maelstrom", -- completes Maelstrom
	"item_ring_of_regen",
	"item_staff_of_wizardry",
	"item_recipe_force_staff",
	"item_recipe_hurricane_pike", -- completes Hurrican Pike
	"item_point_booster",
	"item_blade_of_alacrity",
	"item_ogre_axe",
	"item_staff_of_wizardry",  -- completes Aghanim's Scepter
	"item_hyperstone",
	"item_recipe_mjollnir", -- commpletes Mjollnir
	"item_eagle",
	"item_talisman_of_evasion",
	"item_quarterstaff", -- completes Butterfly
	"item_broadsword",
	"item_blades_of_attack",
	"item_recipe_lesser_crit", -- completes Crystalys
	"item_demon_edge",
	"item_recipe_greater_crit" -- completes Daedalus
}

local tableItemsToBuyAsOfflane = {
}

local tableItemsToBuyAsMid = {
	"item_slippers",
	"item_circlet",
	"item_tango",
	"item_branches",
	"item_branches",
	"item_recipe_wraith_band",
	"item_boots",
	"item_ring_of_protection",
	"item_sobi_mask", -- completes Ring of Aquila
	"item_gloves",
	"item_boots_of_elves",
	"item_recipe_power_treads", -- completes Power Treads
	"item_boots_of_elves",
	"item_boots_of_elves",
	"item_ogre_axe", -- completes Dragon Lance
	"item_gloves",
	"item_mithril_hammer",
	"item_recipe_maelstrom", -- completes Maelstrom
	"item_ring_of_regen",
	"item_staff_of_wizardry",
	"item_recipe_force_staff",
	"item_recipe_hurricane_pike", -- completes Hurrican Pike
	"item_point_booster",
	"item_blade_of_alacrity",
	"item_ogre_axe",
	"item_staff_of_wizardry",  -- completes Aghanim's Scepter
	"item_hyperstone",
	"item_recipe_mjollnir", -- commpletes Mjollnir
	"item_eagle",
	"item_talisman_of_evasion",
	"item_quarterstaff", -- completes Butterfly
	"item_broadsword",
	"item_blades_of_attack",
	"item_recipe_lesser_crit", -- completes Crystalys
	"item_demon_edge",
	"item_recipe_greater_crit" -- completes Daedalus
}

local tableItemsToBuyAsSupport = {
}

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	generic_item_purchase.ItemPurchaseThink(tableItemsToBuyAsMid, tableItemsToBuyAsHardCarry, tableItemsToBuyAsOfflane, tableItemsToBuyAsSupport, tableItemsToBuyAsJungler, tableItemsToBuyAsRoamer)
end

----------------------------------------------------------------------------------------------------
