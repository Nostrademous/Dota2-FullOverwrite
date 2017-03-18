-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsJungler = {
    StartingItems = {
        "item_clarity",
        "item_clarity",
        "item_sobi_mask",
        "item_ring_of_regen",
        "item_recipe_soul_ring"
	},
	UtilityItems = {
	},
	CoreItems = {
        "item_arcane_boots",
        "item_blink"
	},
	ExtensionItems = {
		OffensiveItems = {
			"item_refresher"
		},
		DefensiveItems = {
			"item_black_king_bar"
		}
	},
    SellItems = {
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
