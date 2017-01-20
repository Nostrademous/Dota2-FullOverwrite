-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

local ItemsToBuyAsHardCarry = {
	StartingItems = {
		"item_stout_shield",
		"item_tango",
		"item_flask",
		"item_branches",
		"item_branches",
		"item_branches"
	},
	UtilityItems = {
		"item_flask"
	},
	CoreItems = {
		"item_power_treads_agi",
		"item_bfury",
		"item_vanguard",
		"item_yasha",
		"item_manta",
		"item_abyssal_blade"
	},
	ExtensionItems = {
		{
			"item_butterfly",
			"item_monkey_king_bar"
		},
		{
			"item_heart",
			"item_black_king_bar",
			"item_aghs_scepter"
		}
	}
}

local ItemsToBuyAsMid = {}
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

amBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
amBuy.PurchaseOrder = myPurchaseOrder
amBuy.BoughtItems = myBoughtItems
amBuy.StartingItems = myStartingItems
amBuy.UtilityItems = myUtilityItems
amBuy.CoreItems = myCoreItems
amBuy.ExtensionItems = myExtensionItems

amBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
amBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
amBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
amBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
amBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
amBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	local npcBot = GetBot()

	if not init then
			-- init the tables
			init = amBuy:InitTable()
	end

	amBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
