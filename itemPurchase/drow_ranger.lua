-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsHardCarry = {
    StartingItems = {
        "item_slippers",
        "item_flask",
        "item_tango",
        "item_branches",
        "item_branches",
		"item_faerie_fire"
	},
	UtilityItems = {
	},
	CoreItems = {
        "item_ring_of_aquila",
		"item_power_treads_agi",
		"item_dragon_lance",
		"item_maelstrom",
		"item_ultimate_scepter",
		"item_mjollnir",
		"item_lesser_crit",
		"item_greater_crit"
	},
	ExtensionItems = {
		OffensiveItems = {
			"item_butterfly",
			"item_monkey_king_bar"
		},
		DefensiveItems = {
			"item_hurricane_pike",
			"item_black_king_bar"
		}
	}
}

generic.ItemsToBuyAsMid = {
    StartingItems = {
        "item_wraith_band",
        "item_tango"
	},
	UtilityItems = {
	},
	CoreItems = {
        "item_ring_of_aquila",
		"item_power_treads_agi",
		"item_yasha",
		"item_dragon_lance",
        "item_manta",
		"item_maelstrom",
		"item_mjollnir"
	},
	ExtensionItems = {
		OffensiveItems = {
			"item_butterfly",
			"item_monkey_king_bar"
		},
		DefensiveItems = {
			"item_hurricane_pike",
			"item_black_king_bar",
		    "item_ultimate_scepter"
		}
	}
}

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
