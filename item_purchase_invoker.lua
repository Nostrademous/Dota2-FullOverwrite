-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

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

ToBuy = item_purchase:new()

-- create a 2nd layer of isolation so this bot has it's own instance not shared with other bots
function ToBuy:new(o)
    o = o or item_purchase:new(o)
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

local init = false

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

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
    if GetGameState() == GAME_STATE_PRE_GAME and DotaTime() < -89 then return end
    
    local bot = GetBot()

    if not init then
        -- init the tables
        init = invBuy:InitTable()
    end
    invBuy:Think(bot)

end

----------------------------------------------------------------------------------------------------
