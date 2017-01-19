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
	"item_boots",
	"item_circlet",
	"item_wraith_band"
}

local UtilityItems = { 
	 
}

local CoreItems = {	
	"item_ring_of_aquila",
	"item_power_treads_str",
	"item_mekansm",
	
}

local ExtensionItems = {	
	{	
	},
	{	
		"item_assault" 
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
