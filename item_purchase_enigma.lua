-------------------------------------------------------------------------------
--- AUTHOR: Keithen
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
        "item_clarity",
        "item_clarity",
        "item_sobi_mask",
        "item_ring_of_regen",
        "item_recipe_soul_ring"
	},
	UtilityItems = {
	},
	CoreItems = {
        "item_arcane_boots",
        "item_blink"
	},
	ExtensionItems = {
		OffensiveItems = {
			"item_refresher"
		},
		DefensiveItems = {
			"item_black_king_bar"
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

enBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
enBuy.PurchaseOrder = myPurchaseOrder
enBuy.BoughtItems = myBoughtItems
enBuy.StartingItems = myStartingItems
enBuy.UtilityItems = myUtilityItems
enBuy.CoreItems = myCoreItems
enBuy.ExtensionItems = myExtensionItems

enBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
enBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
enBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
enBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
enBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
enBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
    local npcBot = GetBot()

    if not init then
            -- init the tables
            init = enBuy:InitTable()
    end

    enBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
