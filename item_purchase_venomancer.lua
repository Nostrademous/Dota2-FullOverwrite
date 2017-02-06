-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

local ItemsToBuyAsHardCarry = {}
local ItemsToBuyAsMid = {}
local ItemsToBuyAsOfflane = {}
local ItemsToBuyAsSupport = {
	StartingItems = {
        "item_courier",
		"item_tango",
		"item_clarity",
		"item_clarity",
		"item_branches",
		"item_branches"
	},
	UtilityItems = {
		"item_ward_observer",
        "item_ward_sentry",
        "item_dust"
	},
	CoreItems = {
		"item_infused_raindrop",
		"item_tranquil_boots",
		"item_veil_of_discord",
		"item_force_staff",
		"item_ultimate_scepter"
	},
	ExtensionItems = {
		OffensiveItems = {
            "item_blink",
            "item_black_king_bar"
		},
		DefensiveItems = {
            "item_ghost",
            "item_lotus_orb"
		}
	}
}
local ItemsToBuyAsJungler = {}
local ItemsToBuyAsRoamer = {}

local ToBuy = item_purchase:new()

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

vmBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
vmBuy.PurchaseOrder = myPurchaseOrder
vmBuy.BoughtItems = myBoughtItems
vmBuy.StartingItems = myStartingItems
vmBuy.UtilityItems = myUtilityItems
vmBuy.CoreItems = myCoreItems
vmBuy.ExtensionItems = myExtensionItems

vmBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
vmBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
vmBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
vmBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
vmBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
vmBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	local npcBot = GetBot()

	if not init then
        -- init the tables
        init = vmBuy:InitTable()
	end

	vmBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
