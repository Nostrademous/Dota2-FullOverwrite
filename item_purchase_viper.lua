-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous, dralois, eteran
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

--[[
require( GetScriptDirectory().."/generic_item_purchase" )
--]]

local items = require( GetScriptDirectory().."/items" )
local item_purchase = require( GetScriptDirectory().."/item_purchase_generic_test" )

----------------------------------------------------------------------------------------------------

local StartingItems = {
	"item_stout_shield",
	"item_flask",
	"item_faerie_fire",
}

local UtilityItems = { 
	 
}

local CoreItems = {	
	"item_power_treads_agi",
	"item_ring_of_aquila",
	"item_mekansm"
}

local ExtensionItems = {	
	{
		"item_assault" 
	},
	{	
		"item_heart"
	} 
}

ToBuy = item_purchase:new()

ToBuy:setStartingItems(StartingItems)
ToBuy:setUtilityItems(UtilityItems)
ToBuy:setCoreItems(CoreItems)
ToBuy:setExtensionItems(ExtensionItems[1],ExtensionItems[2])

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()

	local npcBot = GetBot()

	ToBuy:Think(npcBot)
end

----------------------------------------------------------------------------------------------------
