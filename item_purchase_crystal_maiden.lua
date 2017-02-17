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
		"item_wind_lace",
		"item_tranquil_boots",
		"item_magic_wand",
        "item_glimmer_cape",
		"item_force_staff",
		"item_ultimate_scepter",
		"item_blink"
	},
	ExtensionItems = {
		OffensiveItems = {
            "item_black_king_bar"
		},
		DefensiveItems = {
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

cmBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
cmBuy.PurchaseOrder = myPurchaseOrder
cmBuy.BoughtItems = myBoughtItems
cmBuy.StartingItems = myStartingItems
cmBuy.UtilityItems = myUtilityItems
cmBuy.CoreItems = myCoreItems
cmBuy.ExtensionItems = myExtensionItems

cmBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
cmBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
cmBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
cmBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
cmBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
cmBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
    if GetGameState() == GAME_STATE_PRE_GAME and DotaTime() < -89 then return end
    
	local npcBot = GetBot()

	if not init then
        -- init the tables
        init = cmBuy:InitTable()
	end

	cmBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------