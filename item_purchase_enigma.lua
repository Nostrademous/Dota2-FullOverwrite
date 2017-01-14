-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/role" )
local utils = require( GetScriptDirectory().."/utility")

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

function ItemPurchaseThink()

	local npcBot = GetBot();
	if npcBot == nil then return end
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end

	if ( (npcBot:GetNextItemPurchaseValue() > 0) and (npcBot:GetGold() < npcBot:GetNextItemPurchaseValue()) ) then
		return
	end

	local pID = npcBot:GetPlayerID() - 1;
	local roles = role.GetRoles();

	local sNextItem = nil

	if ( roles[pID] == role.ROLE_JUNGLER ) then
		print( "Enigma.ItemPurchaseThink.Jungler" );
		if ( #tableItemsToBuyAsJungler == 0 ) then
			npcBot:SetNextItemPurchaseValue( 0 );
			print( "    No More Items in Purchase Table!" )
			return;
		end

		sNextItem = tableItemsToBuyAsJungler[1];

		npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

		if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
			npcBot:Action_PurchaseItem( sNextItem );
			table.remove( tableItemsToBuyAsJungler, 1 );
			npcBot:SetNextItemPurchaseValue( 0 );
		end
	end

	if sNextItem ~= nil then
		if IsItemPurchasedFromSecretShop( sNextItem ) then
			print(utils.GetHeroName(npcBot), " - ", sNextItem, " available from Secret Shop");
		end
		if IsItemPurchasedFromSideShop( sNextItem ) then
			print(utils.GetHeroName(npcBot), " - ", sNextItem, " available from Side Shop");
		end
	end
end

----------------------------------------------------------------------------------------------------
