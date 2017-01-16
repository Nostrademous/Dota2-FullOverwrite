-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_bloodseeker", package.seeall )

local utils = require( GetScriptDirectory().."/utility" )

local Abilities ={
	"bloodseeker_bloodrage",
	"bloodseeker_blood_bath",
	"bloodseeker_thirst",
	"bloodseeker_rupture"
};

local function UseW()
	local npcBot = GetBot()

	local ability = npcBot:GetAbilityByName(Abilities[2])
	local ult = npcBot:GetAbilityByName(Abilities[4])
	
	if ability == nil or not ability:IsFullyCastable() then
		return false
	end
	
	local Enemies = npcBot:GetNearbyHeroes(1500, true, BOT_MODE_NONE)
	
	if (Enemies == nil or #Enemies <= 1) and ( ult ~= nil and ult:IsFullyCastable() ) then
		return false
	end
	
	if GetUnitToUnitDistance(npcBot, npcBot:GetTarget()) > 1500 then
		return false
	end
	
	local center = utils.GetCenter(Enemies)
	if center ~= nil then
		npcBot:Action_UseAbilityOnLocation(ability, center)
	end
	
	return true
end

local function UseUlt()
	local npcBot = GetBot()
	
	local enemy = npcBot:GetTarget()
	if enemy == nil then return false end
	
	local ability = npcBot:GetAbilityByName(Abilities[4])
	
	if ability == nil or not ability:IsFullyCastable() then
		return false
	end
	
	if GetUnitToUnitDistance(enemy, npcBot) < (ability:GetCastRange() - 100) then
		npcBot:Action_UseAbilityOnEntity(ability, enemy)
		return true
	end
	
	return false
end

function AbilityUsageThink()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end

	local npcBot = GetBot()
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then return	end
	
	if npcBot:GetTarget() == nil then return end

	if UseUlt() or UseW() then return end
end

for k,v in pairs( ability_usage_bloodseeker ) do _G._savedEnv[k] = v end
