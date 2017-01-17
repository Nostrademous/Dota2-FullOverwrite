-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "generic_item_purchase", package.seeall )

require( GetScriptDirectory().."/secret_shop_generic" )
local utils = require( GetScriptDirectory().."/utility")

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function getHeroVar(var)
	local bot = GetBot()
	return gHeroVar.GetVar(bot:GetPlayerID(), var)
end


function ItemPurchaseThink(tableItemsToBuyAsMid, tableItemsToBuyAsHardCarry, tableItemsToBuyAsOfflane, tableItemsToBuyAsSupport, tableItemsToBuyAsJungler, tableItemsToBuyAsRoamer)
	local npcBot = GetBot();
	if npcBot == nil then return end
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
	
	if ( (npcBot:GetNextItemPurchaseValue() > 0) and (npcBot:GetGold() < npcBot:GetNextItemPurchaseValue()) ) then
		return
	end
	
	local roleTable = nil
	local sNextItem = nil

	if ( getHeroVar("Role") == role.ROLE_MID ) then
		--print( getHeroVar("Name").."ItemPurchaseThink.Mid" );
		roleTable = tableItemsToBuyAsMid
	elseif ( getHeroVar("Role") == role.ROLE_HARDCARRY ) then
		--print( getHeroVar("Name").."ItemPurchaseThink.HardCarry" );
		roleTable = tableItemsToBuyAsHardCarry
	elseif ( getHeroVar("Role") == role.ROLE_OFFLANE ) then
		--print( getHeroVar("Name").."ItemPurchaseThink.Offlane" )
		roleTable = tableItemsToBuyAsOfflane
	elseif ( getHeroVar("Role") == role.ROLE_HARDSUPPORT or getHeroVar("Role") == role.ROLE_SEMISUPPORT ) then
		--print( getHeroVar("Name").."ItemPurchaseThink.Support" )
		roleTable = tableItemsToBuyAsSupport
	elseif ( getHeroVar("Role") == role.ROLE_JUNGLER ) then
		--print( getHeroVar("Name").."ItemPurchaseThink.Jungler" )
		roleTable = tableItemsToBuyAsJungler
	elseif ( getHeroVar("Role") == role.ROLE_ROAMER ) then
		--print( getHeroVar("Name").."ItemPurchaseThink.Roamer" )
		roleTable = tableItemsToBuyAsRoamer
	end
	
	if ( #roleTable == 0 ) then
		npcBot:SetNextItemPurchaseValue( 0 );
		print( "    No More Items in Purchase Table!" )
		return;
	end

	sNextItem = roleTable[1]
	
	if sNextItem ~= nil then
		
		if IsItemPurchasedFromSecretShop( sNextItem ) then -- and (not IsItemPurchasedFromSideShop(sNextItem)) then
			npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) )

			if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
				local me = getHeroVar("Self")
				if me:GetAction() ~= constants.ACTION_SECRETSHOP then 
					print(getHeroVar("Name"), " - ", sNextItem, " is ONLY available from Secret Shop")
					if ( me:HasAction(constants.ACTION_SECRETSHOP) == false ) then
						me:AddAction(constants.ACTION_SECRETSHOP)
						print(utils.GetHeroName(npcBot), " STARTING TO HEAD TO SECRET SHOP ")
						secret_shop_generic.OnStart()
					end
				end
				local bDone = secret_shop_generic.Think(sNextItem)
				if bDone then
					me:removeAction(constants.ACTION_SECRETSHOP)
					table.remove( roleTable, 1 )
					npcBot:SetNextItemPurchaseValue( 0 )
				end
			end
		
		--elseif IsItemPurchasedFromSideShop( sNextItem ) then
		--	print(getHeroVar("Name"), " - ", sNextItem, " available from Side Shop")
		else
			npcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) )

			if ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then
				npcBot:Action_PurchaseItem( sNextItem )
				table.remove( roleTable, 1 )
				npcBot:SetNextItemPurchaseValue( 0 )
			end
		end
	end
end

for k,v in pairs( generic_item_purchase ) do _G._savedEnv[k] = v end