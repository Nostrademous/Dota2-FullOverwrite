-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local generic = require( GetScriptDirectory().."/itemPurchase/generic" )

local ItemsToBuyAsHardCarry = {
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
local ItemsToBuyAsMid = {
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
local ItemsToBuyAsOfflane = {}
local ItemsToBuyAsSupport = {}
local ItemsToBuyAsJungler = {}
local ItemsToBuyAsRoamer = {}

ToBuy = generic:new()

-- create a 2nd layer of isolation so this bot has it's own instance not shared with other bots
function ToBuy:new(o)
    o = o or generic:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

-- we need these so if multiple bots inherit from the generic class they don't get mixed with each other
local myPurchaseOrder = {}
local myBoughtItems = {}
local myStartingItems = {}
local myUtilityItems = {}
local myCoreItems = {}
local myExtensionItems = {
    OffensiveItems = {},
    DefensiveItems = {}
}

invBuy = ToBuy:new()

-- set our members to our localized values so we don't fall through to parent's class members
invBuy.PurchaseOrder = myPurchaseOrder
invBuy.BoughtItems = myBoughtItems
invBuy.StartingItems = myStartingItems
invBuy.UtilityItems = myUtilityItems
invBuy.CoreItems = myCoreItems
invBuy.ExtensionItems = myExtensionItems

invBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
invBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
invBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
invBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
invBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
invBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

function Init()
    invBuy:InitTable()
end

function ItemPurchaseThink()
    invBuy:Think(bot)
end

