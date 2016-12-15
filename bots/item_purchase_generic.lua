

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

local tableHardCarryItemsToBuy = { 
	"item_tango",
	"item_branches",
	"item_branches",
	"item_magic_stick",
	"item_circlet",
	"item_boots",
	"item_belt_of_strength",
	"item_gloves",
	"item_ultimate_orb",
};

local tableMidItemsToBuy = { 
	"item_tango",
	"item_branches",
	"item_branches",
	"item_magic_stick",
	"item_circlet",
	"item_boots",
	"item_belt_of_strength",
	"item_gloves",
	"item_ultimate_orb",
};

local tableOfflaneItemsToBuy = { 
	"item_tango",
	"item_branches",
	"item_branches",
	"item_magic_stick",
	"item_circlet",
	"item_boots",
	"item_belt_of_strength",
	"item_gloves",
	"item_ultimate_orb",
};

----------------------------------------------------------------------------------------------------

function ItemPurchaseThink()

	local npcBot = GetBot();
	if ( npcBot == nil ) then
		return;
	end
	
	if ( (npcBot:GetNextItemPurchaseValue() > 0) and (npcBot:GetGold() < npcBot:GetNextItemPurchaseValue()) ) then
		return
	end
	
	local pID = npcBot:GetPlayer() - 1;
	local roles = role.GetRoles();
	
	if ( roles[pID] == role.ROLE_HARDSUPPORT ) then
		print( "Generic.ItemPurchaseThink.HardSupport for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableHardSupportItemsToBuy == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableHardSupportItemsToBuy[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableHardSupportItemsToBuy, 1 );
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	elseif ( roles[pID] == role.ROLE_SEMISUPPORT ) then
		print( "Generic.ItemPurchaseThink.SemiSupport for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableSemiSupportItemsToBuy == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableSemiSupportItemsToBuy[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableSemiSupportItemsToBuy, 1 );
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	elseif ( roles[pID] == role.ROLE_HARDCARRY ) then
		print( "Generic.ItemPurchaseThink.HardCarry for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableHardCarryItemsToBuy == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableHardCarryItemsToBuy[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableHardCarryItemsToBuy, 1 );
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	elseif ( roles[pID] == role.ROLE_MID ) then
		print( "Generic.ItemPurchaseThink.Mid for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableMidItemsToBuy == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableMidItemsToBuy[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableMidItemsToBuy, 1 );
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	elseif ( roles[pID] == role.ROLE_OFFLANE ) then
		print( "Generic.ItemPurchaseThink.Offlane for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableOfflaneItemsToBuy == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableOfflaneItemsToBuy[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableOfflaneItemsToBuy, 1 );
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	end
end

----------------------------------------------------------------------------------------------------

for k,v in pairs( item_purchase_generic ) do _G._savedEnv[k] = v end