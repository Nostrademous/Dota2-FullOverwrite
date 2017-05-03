-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois, eteran
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsHardCarry = {
	StartingItems = {
		"item_tango",
		"item_wraith_band"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_phase_boots",
		"item_ring_of_aquila",
		"item_dragon_lance",
        "item_maelstrom",
        "item_hurricane_pike",
        "item_mjollnir",
	},
	ExtensionItems = {
		{
            "item_monkey_king_bar",
            "item_skadi",
            "item_greater_crit"
		},
		{
            "item_black_king_bar",
            "item_ultimate_scepter",
            "item_silver_edge"
		}
	},
    SellItems = {
        "item_ring_of_aquila"
    }
}
generic.ItemsToBuyAsMid = generic.ItemsToBuyAsHardCarry

function thisBot:Init()
    generic:InitTable()
end

function thisBot:GetPurchaseOrder()
    return generic:GetPurchaseOrder()
end

function thisBot:UpdateTeamBuyList(sItem)
    generic:UpdateTeamBuyList( sItem )
end
function thisBot:UpdateTeamBuyList(sItem)
    generic:UpdateTeamBuyList( sItem )
end

function thisBot:ItemPurchaseThink(bot)
    generic:Think(bot)
end

return thisBot
