-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois, eteran
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsHardCarry = {
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
		OffensiveItems = {
		},
		DefensiveItems = {
		}
	},
    SellItems = {
        "item_infused_raindrop"
    }
}

generic.ItemsToBuyAsMid = {
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
		OffensiveItems = {
		},
		DefensiveItems = {
		}
	},
    SellItems = {
        "item_infused_raindrop"
    }
}

generic.ItemsToBuyAsOfflane = {
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
		OffensiveItems = {
		},
		DefensiveItems = {
		}
	},
    SellItems = {
        "item_infused_raindrop"
    }
}

----------------------------------------------------------------------------------------------------

function thisBot:Init()
    generic:InitTable()
end

function thisBot:GetPurchaseOrder()
    return generic:GetPurchaseOrder()
end

function thisBot:UpdateTeamBuyList(sItem)
    generic:UpdateTeamBuyList( sItem )
end

function thisBot:ItemPurchaseThink(bot)
    generic:Think(bot)
end

return thisBot

----------------------------------------------------------------------------------------------------
