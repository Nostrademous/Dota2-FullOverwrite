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
        "item_quelling_blade",
        "item_tango",
        "item_branches",
        "item_branches"
    },
    UtilityItems = {
    },
    CoreItems = {
        "item_iron_talon",
        "item_power_treads_agi",
        "item_invis_sword",
        "item_yasha",
        "item_sange_and_yasha",
        "item_basher",
        "item_abyssal_blade",
        "item_assault"
    },
    ExtensionItems = {
        OffensiveItems = {
            "item_silver_edge",
            "item_butterfly",
            "item_monkey_king_bar"
        },
        DefensiveItems = {
            "item_heart",
            "item_black_king_bar",
            "item_aghs_scepter"
        }
    },
    SellItems = {
        "item_branches",
        "item_branches",
        "item_iron_talon"
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