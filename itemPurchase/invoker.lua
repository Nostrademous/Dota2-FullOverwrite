-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

generic.ItemsToBuyAsHardCarry = {
    StartingItems = {
        "item_wraith_band",
        "item_faerie_fire",
        "item_branches"
    },
    UtilityItems = {
        "item_tome_of_knowledge"
    },
    CoreItems = {
        "item_ring_of_aquila",
        "item_boots",
        "item_hand_of_midas",
        "item_blink",
        "item_boots_of_travel_1",
        "item_ultimate_scepter"
    },
    ExtensionItems = {
        OffensiveItems = {
            "item_octarine_core"
        },
        DefensiveItems = {
            "item_black_king_bar"
        }
    },
    SellItems = {
        "item_ring_of_aquila"
    }
}
generic.ItemsToBuyAsMid = {
    StartingItems = {
        "item_wraith_band",
        "item_faerie_fire",
        "item_branches"
    },
    UtilityItems = {
        "item_tome_of_knowledge"
    },
    CoreItems = {
        "item_ring_of_aquila",
        "item_boots",
        "item_hand_of_midas",
        "item_blink",
        "item_boots_of_travel_1",
        "item_ultimate_scepter"
    },
    ExtensionItems = {
        OffensiveItems = {
            "item_octarine_core"
        },
        DefensiveItems = {
            "item_black_king_bar"
        }
    },
    SellItems = {
        "item_ring_of_aquila"
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