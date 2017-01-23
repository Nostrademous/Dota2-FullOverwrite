-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_drow_ranger", package.seeall )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
	local bot = bot or GetBot()
	gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
	local bot = bot or GetBot()
	return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local Abilities ={
	"drow_ranger_frost_arrows",
	"drow_ranger_silence",
	"drow_ranger_trueshot",
	"drow_ranger_marksmanship"
}

local function UseQ()
	local npcBot = GetBot()

	local frostArrow = npcBot:GetAbilityByName(Abilities[1])
	local gust = npcBot:GetAbilityByName(Abilities[2])
	
	if (frostArrow == nil) or (not frostArrow:IsFullyCastable()) then
		return false
	end
	
	local Enemies = npcBot:GetNearbyHeroes(frostArrow:GetCastRange() + 100, true, BOT_MODE_NONE)
	
	if #Enemies == 1 and ( gust ~= nil and gust:IsFullyCastable() ) then
		setHeroVar("Target", Enemies[1])
		return false
	end
	
	local target = getHeroVar("Target")
	if target ~= nil and GetUnitToUnitDistance(npcBot, target) < frostArrow:GetCastRange() then
		npcBot:Action_UseAbilityOnEntity(frostArrow, target)
		return true
	end
	
	if (npcBot:GetMana()/npcBot:GetMaxMana()) > 0.5 and #Enemies > 0 and #Enemies < 3 and (getHeroVar("OutOfRangeCasting") + frostArrow:GetCastPoint()) < GameTime() then
		local weakestHero, weakestHeroHealth = utils.GetWeakestHero(npcBot, frostArrow:GetCastRange() + 100)
		if weakestHero ~= nil then
			npcBot:Action_UseAbilityOnEntity(frostArrow, weakestHero)
			setHeroVar("OutOfRangeCasting", GameTime())
			return true
		end
	end
	
	return false
end

local function UseW()
	local npcBot = GetBot()
	
	local enemy = getHeroVar("Target")
	if enemy == nil then return false end
	
	local gust = npcBot:GetAbilityByName(Abilities[2])
	
	if (gust == nil) or (not gust:IsFullyCastable()) then
		return false
	end
	
	if GetUnitToUnitDistance(enemy, npcBot) < gust:GetCastRange() and (not enemy.isSilenced) then
		npcBot:Action_UseAbilityOnEntity(gust, enemy)
		return true
	end
	
	if GetUnitToUnitDistance(enemy, npcBot) < 450 then
		npcBot:Action_UseAbilityOnEntity(gust, enemy)
		return true
	end
	
	return false
end

function AbilityUsageThink()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

	local npcBot = GetBot()
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then return false end
	
	if getHeroVar("Target") == nil then return false end

	if UseW() or UseQ() then return true end
end

for k,v in pairs( ability_usage_drow_ranger ) do _G._savedEnv[k] = v end
