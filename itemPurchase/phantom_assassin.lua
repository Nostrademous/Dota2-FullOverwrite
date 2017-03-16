-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsHardCarry = {
    StartingItems = {
        "item_tango",
        "item_stout_shield",
		"item_quelling_blade"
	},
	UtilityItems = {
        "item_infused_raindrop"
	},
	CoreItems = {
		"item_ring_of_health",
        "item_boots",
		"item_bfury",
		"item_power_treads_agility",
		"item_lifesteal",
		"item_basher",
        "item_black_king_bar",
        "item_abyssal_blade",
		"item_satanic"
	},
	ExtensionItems = {
		OffensiveItems = {
			"item_assault",
            "item_boots_of_travel_1",
            "item_monkey_king_bar"
		},
		DefensiveItems = {
            "item_skadi",
			"item_ultimate_scepter",
			"item_heart"
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
