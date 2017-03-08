-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsHardCarry = {
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
		OffensiveItems = {
		},
		DefensiveItems = {
		}
	}
}
generic.ItemsToBuyAsMid = {
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
		OffensiveItems = {
		},
		DefensiveItems = {
		}
	}
}

generic.ItemsToBuyAsSupport = {
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
		OffensiveItems = {
		},
		DefensiveItems = {
		}
	}
}

----------------------------------------------------------------------------------------------------

function thisBot:Init()
    generic:InitTable()
end

function thisBot:GetPurchaseOrder()
    return generic:GetPurchaseOrder()
end

function thisBot:ItemPurchaseThink(bot)
    generic:Think(bot)
end

return thisBot

----------------------------------------------------------------------------------------------------
