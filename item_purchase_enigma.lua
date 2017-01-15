-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/generic_item_purchase" )

local tableItemsToBuyAsJungler = {
	"item_clarity",
	"item_clarity",
	"item_sobi_mask",
	"item_ring_of_regen",
	"item_recipe_soul_ring",
	"item_boots",
	"item_energy_booster",
	"item_blink"
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
