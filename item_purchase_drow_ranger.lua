-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

local ItemsToBuyAsHardCarry = {StartingItems = {
        "item_slippers",
        "item_flask",
        "item_tango",
        "item_branches",
        "item_branches",
		"item_faerie_fire"
	},
	UtilityItems = {
	},
	CoreItems = {
        "item_ring_of_aquila",
		"item_power_treads_agi",
		"item_dragon_lance",
		"item_maelstrom",
		"item_ultimate_scepter",
		"item_mjollnir",
		"item_lesser_crit",
		"item_greater_crit"
	},
	ExtensionItems = {
		OffensiveItems = {
			"item_butterfly",
			"item_monkey_king_bar"
		},
		DefensiveItems = {
			"item_hurricane_pike",
			"item_black_king_bar"
		}
	}}
local ItemsToBuyAsMid = {StartingItems = {
        "item_wraith_band",
        "item_tango"
	},
	UtilityItems = {
	},
	CoreItems = {
        "item_ring_of_aquila",
		"item_power_treads_agi",
		"item_yasha",
		"item_dragon_lance",
        "item_manta",
		"item_maelstrom",
		"item_mjollnir"
	},
	ExtensionItems = {
		OffensiveItems = {
			"item_butterfly",
			"item_monkey_king_bar"
		},
		DefensiveItems = {
			"item_hurricane_pike",
			"item_black_king_bar",
		    "item_ultimate_scepter"
		}
	}}
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

drBuy = ToBuy:new()
-- set our members to our localized values so we don't fall through to parent's class members
drBuy.PurchaseOrder = myPurchaseOrder
drBuy.BoughtItems = myBoughtItems
drBuy.StartingItems = myStartingItems
drBuy.UtilityItems = myUtilityItems
drBuy.CoreItems = myCoreItems
drBuy.ExtensionItems = myExtensionItems

drBuy.ItemsToBuyAsHardCarry = ItemsToBuyAsHardCarry
drBuy.ItemsToBuyAsMid = ItemsToBuyAsMid
drBuy.ItemsToBuyAsOfflane = ItemsToBuyAsOfflane
drBuy.ItemsToBuyAsSupport = ItemsToBuyAsSupport
drBuy.ItemsToBuyAsJungler = ItemsToBuyAsJungler
drBuy.ItemsToBuyAsRoamer = ItemsToBuyAsRoamer

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
    if GetGameState() == GAME_STATE_PRE_GAME and DotaTime() < -89 then return end

    if not init then
        -- init the tables
        init = drBuy:InitTable()
    end

    drBuy:Think(GetBot())
end

----------------------------------------------------------------------------------------------------
