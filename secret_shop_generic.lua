-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "secret_shop_generic", package.seeall )

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
	local bot = GetBot()
	gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
	local bot = GetBot()
	return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

-------------------------------------------------------------------------------

function  OnStart()
	utils.InitPath()
end

local function GetSecretShop()
	local npcBot = GetBot()
	
	if GetTeam() == TEAM_RADIANT then
		local safeTower = utils.GetLaneTower(utils.GetOtherTeam(), LANE_BOT, 1)
		
		if utils.NotNilOrDead(safeTower) then
			return constants.SECRET_SHOP_RADIANT
		end
	else
		local safeTower = utils.GetLaneTower(utils.GetOtherTeam(), LANE_TOP, 1)
		
		if utils.NotNilOrDead(safeTower) then
			return constants.SECRET_SHOP_DIRE
		end
	end
	
	local loc = nil
	if GetUnitToLocationDistance(npcBot, constants.SECRET_SHOP_DIRE) < GetUnitToLocationDistance(npcBot, constants.SECRET_SHOP_RADIANT) then
		return constants.SECRET_SHOP_DIRE;
	else
		return constants.SECRET_SHOP_RADIANT;
	end
end

function Think( NextItem )
	local npcBot = GetBot()
	if	NextItem == nil then
		setHeroVar("IsGoingToShop", false)
		return false
	end
	
	if npcBot:IsUsingAbility() or npcBot:IsChanneling() then return	false end

	if (not IsItemPurchasedFromSecretShop(NextItem)) or npcBot:GetGold() < GetItemCost( NextItem ) then
		setHeroVar("IsGoingToShop", false)
		return false
	end
	
	local secLoc = GetSecretShop()
	
	if IsItemPurchasedFromSecretShop(NextItem) then
		if GetUnitToLocationDistance(npcBot, secLoc) < 250 then
			if npcBot:GetGold() >= GetItemCost( NextItem ) then
				npcBot:Action_PurchaseItem( NextItem )
				setHeroVar("IsGoingToShop", false)
				utils.InitPath()
				return true
			else
				setHeroVar("IsGoingToShop", false)
				return false
			end
		else
			utils.MoveSafelyToLocation(npcBot, secLoc)
			return false
		end
	end
end

--------
for k,v in pairs( secret_shop_generic ) do	_G._savedEnv[k] = v end
