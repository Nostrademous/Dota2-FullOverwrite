

----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "item_purchase_generic", package.seeall )

require( GetScriptDirectory().."/role" )

local tableHardSupportItemsToBuy = { 
	"item_courier",
	"item_ward_observer",
	"item_tango",
	"item_branches",
	"item_branches",
	"item_magic_stick",
	"item_circlet",
	"item_boots",
	"item_belt_of_strength",
	"item_gloves",
};

local tableSemiSupportItemsToBuy = { 
	"item_ward_observer",
	"item_tango",
	"item_branches",
	"item_branches",
	"item_magic_stick",
	"item_circlet",
	"item_boots",
	"item_belt_of_strength",
	"item_gloves",
};

local tableItemsToBuy = { 
	"item_tango",
	"item_branches",
	"item_branches",
	"item_magic_stick",
	"item_circlet",
	"item_boots",
	"item_belt_of_strength",
	"item_gloves",
};

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()

	local npcBot = GetBot();
	local pID = npcBot:GetPlayer() - 1;
	
	--print( "Generic.ItemPurchaseThink for player #", pID );
	
	local roles = role.GetRoles();
	if ( roles[pID] == 5 ) then
		if ( #tableHardSupportItemsToBuy == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			return;
		end

		local sNextItem = tableHardSupportItemsToBuy[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) )
		then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableHardSupportItemsToBuy, 1 );
		end
	elseif ( roles[pID] == 4 ) then
		if ( #tableSemiSupportItemsToBuy == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			return;
		end

		local sNextItem = tableSemiSupportItemsToBuy[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) )
		then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableSemiSupportItemsToBuy, 1 );
		end
	elseif ( (roles[pID] == 1) or (roles[pID] == 2) or (roles[pID] == 3) ) then
		if ( #tableItemsToBuy == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			return;
		end

		local sNextItem = tableItemsToBuy[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) )
		then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableItemsToBuy, 1 );
		end
	end
end

----------------------------------------------------------------------------------------------------

for k,v in pairs( item_purchase_generic ) do	_G._savedEnv[k] = v end