-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_viper", package.seeall )

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
	"viper_poison_attack",
	"viper_nethertoxin",
	"viper_corrosive_skin",
	"viper_viper_strike"
}

local function UseQ()
	local npcBot = GetBot()

	local ability = npcBot:GetAbilityByName(Abilities[1])
	local ult = npcBot:GetAbilityByName(Abilities[4])
	
	if (ability == nil) or (not ability:IsFullyCastable()) then
		return false
	end
	
	local Enemies = npcBot:GetNearbyHeroes(ability:GetCastRange() + 100, true, BOT_MODE_NONE)
	
	if #Enemies == 1 and ( ult ~= nil and ult:IsFullyCastable() ) then
		setHeroVar("Target", {Obj=Enemies[1], Id=Enemies[1]:GetPlayerID()})
		return false
	end
	
	local target = getHeroVar("Target")
	if utils.ValidTarget(target) and GetUnitToUnitDistance(npcBot, target.Obj) < ability:GetCastRange() then
		npcBot:Action_UseAbilityOnEntity(ability, target.Obj)
		return true
	end
	
	if (npcBot:GetMana()/npcBot:GetMaxMana()) > 0.5 and #Enemies > 0 and #Enemies < 3 then
		local weakestHero, weakestHeroHealth = utils.GetWeakestHero(npcBot, ability:GetCastRange() + 100)
		if weakestHero ~= nil then
			npcBot:Action_UseAbilityOnEntity(ability, weakestHero)
			return true
		end
	end
	
	return false
end

local function UseUlt()
	local npcBot = GetBot()
    
    local ability = npcBot:GetAbilityByName(Abilities[4])
	if (ability == nil) or (not ability:IsFullyCastable()) then
		return false
	end
    
	local enemy = getHeroVar("Target")
	if not utils.ValidTarget(enemy) then return false end
	
	if GetUnitToUnitDistance(enemy.Obj, npcBot) < ability:GetCastRange() then
		npcBot:Action_UseAbilityOnEntity(ability, enemy.Obj)
		return true
	end
	
	return false
end

function AbilityUsageThink()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

	local npcBot = GetBot()
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then return false end

	if UseUlt() or UseQ() then return true end
end

for k,v in pairs( ability_usage_viper ) do _G._savedEnv[k] = v end
