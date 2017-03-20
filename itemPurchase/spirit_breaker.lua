-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois, eteran
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsOfflane = {
	StartingItems = {
		"item_ward_observer",
		"item_stout_shield",
        "item_tango",
		"item_flask",
        "item_branches"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
        "item_invis_sword",
		"item_medallion_of_courage",
		"item_solar_crest",
        "item_vladmir",
        "item_silver_edge"
	},
	ExtensionItems = {
        {
			"item_butterfly",
			"item_assault"
		},
		{
			"item_heart",
			"item_manta"
		}
	},
    SellItems = {
        "item_stout_shield"
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
function thisBot:UpdateTeamBuyList(sItem)
    generic:UpdateTeamBuyList( sItem )
end

function thisBot:ItemPurchaseThink(bot)
    generic:Think(bot)
end

return thisBot
