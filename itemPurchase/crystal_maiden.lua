-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsSupport = {
	StartingItems = {
        "item_courier",
		"item_tango",
		"item_clarity",
		"item_clarity",
		"item_branches",
		"item_branches"
	},
	UtilityItems = {
		"item_ward_observer",
        "item_ward_sentry",
        "item_dust"
	},
	CoreItems = {
		"item_wind_lace",
		"item_tranquil_boots",
		"item_magic_wand",
        "item_glimmer_cape",
		"item_force_staff",
		"item_ultimate_scepter",
		"item_blink"
	},
	ExtensionItems = {
		OffensiveItems = {
            "item_black_king_bar"
		},
		DefensiveItems = {
            "item_lotus_orb"
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
