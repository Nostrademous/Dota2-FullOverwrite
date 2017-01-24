-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_bloodseeker", package.seeall )

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
	"bloodseeker_bloodrage",
	"bloodseeker_blood_bath",
	"bloodseeker_thirst",
	"bloodseeker_rupture"
};

local function UseW()
	local npcBot = GetBot()
	local ability = npcBot:GetAbilityByName(Abilities[2])
	if ability == nil or not ability:IsFullyCastable() then return false end

	local ult = npcBot:GetAbilityByName(Abilities[4])

	local Enemies = npcBot:GetNearbyHeroes(1500, true, BOT_MODE_NONE)

	if #Enemies == 1 and ( ult ~= nil and ult:IsFullyCastable() ) then
		setHeroVar("Target", Enemies[1])
		return false
	end

	local target = getHeroVar("Target")
	if target ~= nil and GetUnitToUnitDistance(npcBot, target) > 1500 then
		return false
	end

	if #Enemies == 1 then
		-- we use 3.0 for delay b/c cast point is 0.4 and delay is 2.6
		npcBot:Action_UseAbilityOnLocation(ability, Enemies[1]:GetExtrapolatedLocation(3.0))
	else
		local center = utils.GetCenter(Enemies)
		if center ~= nil then
			npcBot:Action_UseAbilityOnLocation(ability, center)
		end
	end

	return true
end

local function UseUlt()
	-- TODO: don't use it if we can kill the enemy by rightclicking / have teammates around
	local npcBot = GetBot()
	local ability = npcBot:GetAbilityByName(Abilities[4])
	if ability == nil or not ability:IsFullyCastable() then return false end

	local enemy = getHeroVar("Target")
	if enemy == nil then return false end

	if GetUnitToUnitDistance(enemy, npcBot) < (ability:GetCastRange() - 100) then
		npcBot:Action_UseAbilityOnEntity(ability, enemy)
		return true
	end

	return false
end

local function UseQ()
	local npcBot = GetBot()
	local ability = npcBot:GetAbilityByName(Abilities[1])
	if ability == nil or not ability:IsFullyCastable() then return false end

	local enemy = getHeroVar("Target")
	if enemy ~= nil and GetUnitToUnitDistance(enemy, npcBot) < (ability:GetCastRange() - 100) then
		npcBot:Action_UseAbilityOnEntity(ability, enemy)
		return true
	end

	npcBot:Action_UseAbilityOnEntity(ability, npcBot)
	return true
end

function AbilityUsageThink()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

	local npcBot = GetBot()

	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then return	false end

	if getHeroVar("Target") == nil then return false end

	if UseQ() or UseUlt() or UseW() then return true end
end

for k,v in pairs( ability_usage_bloodseeker ) do _G._savedEnv[k] = v end
