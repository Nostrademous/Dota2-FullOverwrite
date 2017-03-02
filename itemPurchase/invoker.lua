-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local invBuy = BotsInit.CreateGeneric()

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
    }
}
--generic.ItemsToBuyAsOfflane = {}
--generic.ItemsToBuyAsSupport = {}
--generic.ItemsToBuyAsJungler = {}
--generic.ItemsToBuyAsRoamer = {}

--local ToBuy = generic:new()

-- create a 2nd layer of isolation so this bot has it's own instance not shared with other bots
--[[
function ToBuy:new(o)
    o = o or generic:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end
--]]

-- we need these so if multiple bots inherit from the generic class they don't get mixed with each other
--[[
generic.myPurchaseOrder = {}
generic.myBoughtItems = {}
generic.myStartingItems = {}
generic.myUtilityItems = {}
generic.myCoreItems = {}
generic.myExtensionItems = {
    OffensiveItems = {},
    DefensiveItems = {}
}
--]]

--local invBuy = ToBuy:new()

-- set our members to our localized values so we don't fall through to parent's class members
--invBuy.PurchaseOrder = myPurchaseOrder
--invBuy.BoughtItems = myBoughtItems
--invBuy.StartingItems = myStartingItems
--invBuy.UtilityItems = myUtilityItems
--invBuy.CoreItems = myCoreItems
--invBuy.ExtensionItems = myExtensionItems

--invBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
--invBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
--invBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
--invBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
--invBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
--invBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

function invBuy:Init()
    generic:InitTable()
end

function invBuy:ItemPurchaseThink(bot)
    generic:Think(bot)
end

return invBuy