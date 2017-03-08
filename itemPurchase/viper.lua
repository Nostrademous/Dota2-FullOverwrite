-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois, eteran
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsHardCarry = {
	StartingItems = {
		"item_stout_shield",
		"item_flask",
		"item_faerie_fire"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
		"item_ring_of_aquila",
		"item_mekansm",
		"item_dragon_lance"
	},
	ExtensionItems = {
		{
			"item_ultimate_scepter",
			"item_assault"
		},
		{
			"item_heart"
		}
	}
}
generic.ItemsToBuyAsMid = {
	StartingItems = {
		"item_stout_shield",
		"item_flask",
		"item_faerie_fire"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
		"item_ring_of_aquila",
		"item_mekansm",
		"item_dragon_lance"
	},
	ExtensionItems = {
		{
			"item_ultimate_scepter",
			"item_assault"
		},
		{
			"item_heart"
		}
	}
}
generic.ItemsToBuyAsOfflane = {
	StartingItems = {
		"item_ward_observer",
		"item_stout_shield",
		"item_flask",
		"item_faerie_fire"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
		"item_ring_of_aquila",
		"item_mekansm",
		"item_dragon_lance"
	},
	ExtensionItems = {
		{
			"item_ultimate_scepter",
			"item_butterfly",
			"item_assault"
		},
		{
			"item_pipe",
			"item_heart",
			"item_manta"
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
function thisBot:UpdateTeamBuyList(sItem)
    generic:UpdateTeamBuyList( sItem )
end

function thisBot:ItemPurchaseThink(bot)
    generic:Think(bot)
end

return thisBot
