-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsHardCarry = {
	StartingItems = {
		"item_stout_shield",
		"item_tango",
		"item_flask",
		"item_branches",
		"item_branches",
		"item_quelling_blade"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
		"item_bfury",
		"item_vanguard",
		"item_yasha",
		"item_manta",
		"item_abyssal_blade"
	},
	ExtensionItems = {
		{
			"item_butterfly",
			"item_monkey_king_bar"
		},
		{
			"item_heart",
			"item_black_king_bar",
			"item_aghs_scepter"
		}
	},
    SellItems = {
        "item_branches",
		"item_branches"
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
