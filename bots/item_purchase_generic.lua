

----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "item_purchase_generic", package.seeall )

require( GetScriptDirectory().."/role" )
require( GetScriptDirectory().."/global_vars" )

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
	
	side = TEAM_RADIANT
	if ( GetTeam() == TEAM_DIRE ) then
		side = TEAM_DIRE
	end
	
	if ( (npcBot:GetNextItemPurchaseValue() > 0) and (npcBot:GetGold() < npcBot:GetNextItemPurchaseValue()) ) then
		return
	end
	
	local pID = npcBot:GetPlayer() - 1;
	local roles = role.GetRoles();
	
	purch_index = global_vars.purchase_index[side][roles[pID]]
	
	if ( roles[pID] == role.ROLE_HARDSUPPORT ) then
		print( "Generic.ItemPurchaseThink.HardSupport for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableHardSupportItemsToBuy < purch_index ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableHardSupportItemsToBuy[purch_index];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			--table.remove( tableHardSupportItemsToBuy, 1 );
			global_vars.purchase_index[side][roles[pID]] = purch_index + 1
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	elseif ( roles[pID] == role.ROLE_SEMISUPPORT ) then
		print( "Generic.ItemPurchaseThink.SemiSupport for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableSemiSupportItemsToBuy < purch_index ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableSemiSupportItemsToBuy[purch_index];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			--table.remove( tableSemiSupportItemsToBuy, 1 );
			global_vars.purchase_index[side][roles[pID]] = purch_index + 1
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	elseif ( roles[pID] == role.ROLE_HARDCARRY ) then
		print( "Generic.ItemPurchaseThink.HardCarry for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableHardCarryItemsToBuy < purch_index ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableHardCarryItemsToBuy[purch_index];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			--table.remove( tableHardCarryItemsToBuy, 1 );
			global_vars.purchase_index[side][roles[pID]] = purch_index + 1
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	elseif ( roles[pID] == role.ROLE_MID ) then
		print( "Generic.ItemPurchaseThink.Mid for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableMidItemsToBuy < purch_index ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableMidItemsToBuy[purch_index];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			--table.remove( tableMidItemsToBuy, 1 );
			global_vars.purchase_index[side][roles[pID]] = purch_index + 1
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	elseif ( roles[pID] == role.ROLE_OFFLANE ) then
		print( "Generic.ItemPurchaseThink.Offlane for player #", pID, " name:", npcBot:GetUnitName() );
		if ( #tableOfflaneItemsToBuy < purch_index ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		local sNextItem = tableOfflaneItemsToBuy[purch_index];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			--table.remove( tableOfflaneItemsToBuy, 1 );
			global_vars.purchase_index[side][roles[pID]] = purch_index + 1
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	end
end

-------------------------------------------------------------------------------
--- Utility Functions
-------------------------------------------------------------------------------

function BuyTPScroll(npcBot, count)
	count = count or 1;
	local iScrollCount = 0;
	
	for i=0,14 do
		local sCurItem = npcBot:GetItemInSlot( i );
		if ( sCurItem ~= nil ) then
			local iName = sCurItem:GetName();
			if ( iName == "item_tpscroll" ) then
				iScrollCount = iScrollCount + 1;
			elseif ( iName == "item_travel_boots_1" or iName == "item_travel_boots_2" ) then
				return; --we are done, no need to check further
			end
		end
	end
	
	-- If we are at the sideshop or fountain with no TPs, then buy up to count
	if ( (npcBot:DistanceFromSideShop() == 0 or npcBot:DistanceFromFountain() == 0) and iScrollCount < count ) then
		for i=1,(count-iScrollCount) do
			if ( npcBot:GetGold() >= GetItemCost( "item_tpscroll" ) ) then
				npcBot:Action_PurchaseItem( "item_tpscroll" );
				iScrollCount = iScrollCount + 1;
			end
		end
	end
end

----------------------------------------------------------------------------------------------------

for k,v in pairs( item_purchase_generic ) do _G._savedEnv[k] = v end