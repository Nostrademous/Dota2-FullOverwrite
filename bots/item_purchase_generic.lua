

----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "item_purchase_generic", package.seeall )

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

	--print( "Generic.ItemPurchaseThink" );
	local npcBot = GetBot();
	
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

----------------------------------------------------------------------------------------------------

for k,v in pairs( item_purchase_generic ) do	_G._savedEnv[k] = v end