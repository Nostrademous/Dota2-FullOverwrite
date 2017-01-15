-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/generic_item_purchase" )

local tableItemsToBuyAsJungler = {
	"item_stout_shield",
	"item_quelling_blade",
	"item_tango",
	"item_branches",
	"item_branches",
	"item_ring_of_protection",
	"item_recipe_iron_talon"
};

----------------------------------------------------------------------------------------------------

local tableItemsToBuyAsRoamer = {
}

local tableItemsToBuyAsHardCarry = {
}

local tableItemsToBuyAsOfflane = {
}

local tableItemsToBuyAsMid = {
}

local tableItemsToBuyAsSupport = {
}

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()
	generic_item_purchase.ItemPurchaseThink(tableItemsToBuyAsMid, tableItemsToBuyAsHardCarry, tableItemsToBuyAsOfflane, tableItemsToBuyAsSupport, tableItemsToBuyAsJungler, tableItemsToBuyAsRoamer)
end

----------------------------------------------------------------------------------------------------
