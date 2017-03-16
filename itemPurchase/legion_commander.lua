-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsJungler = {
    StartingItems = {
        "item_stout_shield",
        "item_iron_talon",
        "item_boots",
        "item_blight_stone",
	},
	UtilityItems = {
        "item_infused_raindrop"
	},
	CoreItems = {
        "item_power_treads_agi",
        "item_blink",
        "item_blade_mail",
        "item_desolator",
        "item_armlet",
        "item_black_king_bar"
	},
	ExtensionItems = {
		OffensiveItems = {
            "item_abyssal_blade",
            "item_moon_shard",
            "item_boots_of_travel_1",
            "item_monkey_king_bar"
		},
		DefensiveItems = {
            "item_assault",
            "item_skadi",
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
