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
        "item_flask",
        "item_stout_shield",
        "item_branches",
        "item_branches"
	},
	UtilityItems = {
        "item_infused_raindrop"
	},
	CoreItems = {
        "item_boots",
        "item_blight_stone",
        "item_poor_mans_shield",
        "item_phase_boots",
        "item_armlet",
        "item_desolator",
        "item_basher",
        "item_abyssal_blade"
	},
	ExtensionItems = {
		OffensiveItems = {
			"item_assault",
            "item_boots_of_travel_1",
            "item_rapier"
		},
		DefensiveItems = {
			"item_black_king_bar",
            "item_satanic",
            "item_skadi"
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
