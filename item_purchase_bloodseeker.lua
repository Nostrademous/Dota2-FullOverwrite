-------------------------------------------------------------------------------
--- AUTHOR: Keithen, Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

local ItemsToBuyAsHardCarry = {}
local ItemsToBuyAsMid = {}
local ItemsToBuyAsOfflane = {}
local ItemsToBuyAsSupport = {}
local ItemsToBuyAsJungler = {
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
    }
}

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

bsBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
bsBuy.PurchaseOrder = myPurchaseOrder
bsBuy.BoughtItems = myBoughtItems
bsBuy.StartingItems = myStartingItems
bsBuy.UtilityItems = myUtilityItems
bsBuy.CoreItems = myCoreItems
bsBuy.ExtensionItems = myExtensionItems

bsBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
bsBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
bsBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
bsBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
bsBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
bsBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
    local npcBot = GetBot()

    if not init then
        -- init the tables
        init = bsBuy:InitTable()
    end

    bsBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
