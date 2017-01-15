-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

-------
_G._savedEnv = getfenv()
module( "jungling_generic", package.seeall )
----------
local utils = require( GetScriptDirectory().."/utility")
require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/jungle_status")

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
	local bot = GetBot()
	gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
	local bot = GetBot()
	return gHeroVar.GetVar(bot:GetPlayerID(), var)
end
----------

local CurLane = nil;
local EyeRange=1200;
local BaseDamage=50;
local AttackRange=150;
local AttackSpeed=0.6;
local LastTiltTime=0.0;

local DamageThreshold=1.0;
local MoveThreshold=1.0;

local BackTimerGen=-1000;

local IsCore = nil;

local JunglingStates={
	FindCamp=0,
	MoveToCamp=1,
	WaitForSpawn=2,
	CleanCamp=3
}

local JunglingState=JunglingStates.FindCamp;


function OnStart(npcBot)

end

----------------------------------

local function FindCamp(bot)
	local jungle = jungle_status.GetJungle(GetTeam()) or {}
	jungle = FindCampsByMaxDifficulty(jungle, constants.CAMP_MEDIUM)
	if #jungle == 0 then -- they are all dead
		jungle = utils.deepcopy(utils.tableNeutralCamps[GetTeam()])
		jungle = FindCampsByMaxDifficulty(jungle, constants.CAMP_MEDIUM)
	end
	local camp = utils.NearestNeutralCamp(bot, jungle)
	setHeroVar("currentCamp", camp)
	bot:Action_MoveToLocation(camp[constants.PRE_STACK_VECTOR])
	print(utils.GetHeroName(bot), "moves to camp")
	JunglingState = JunglingStates.MoveToCamp
end

local function MoveToCamp(bot)
	if GetUnitToLocationDistance(bot, getHeroVar("currentCamp")[constants.PRE_STACK_VECTOR]) > 200 then
		bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.PRE_STACK_VECTOR]) -- FIXME: is this slow??
		return
	end
	local neutrals = bot:GetNearbyCreeps(EyeRange,true);
	if #neutrals == 0 then -- no creeps here
		local jungle = jungle_status.GetJungle(GetTeam())
		if jungle == nil then -- jungle is empty
			bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.STACK_VECTOR]) -- make sure it spawns
			setHeroVar("waituntil", utils.NextNeutralSpawn())
			print(utils.GetHeroName(bot), "waits for spawn")
			JunglingState = JunglingStates.WaitForSpawn
		else
			print("No creeps here :(") -- one of  dumb teammates, blocked by enemy, farmed by enemy
			jungle_status.JungleCampClear(GetTeam(), getHeroVar("currentCamp")[constants.VECTOR])
			print(utils.GetHeroName(bot), "finds camp")
			JunglingState = JunglingStates.FindCamp
		end
	else
		print(utils.GetHeroName(bot), "KILLS")
		JunglingState = JunglingStates.CleanCamp
	end
end

local function WaitForSpawn(bot)
	if DotaTime() < getHeroVar("waituntil") then return end
	bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.PRE_STACK_VECTOR])
	JunglingState = JunglingStates.MoveToCamp
end

local function CleanCamp(bot)
	local neutrals = bot:GetNearbyCreeps(EyeRange,true);
	if #neutrals == 0 then -- we did it
		print(utils.GetHeroName(bot), "finds camp")
		JunglingState = JunglingStates.FindCamp
	else
		bot:Action_AttackUnit(neutrals[1], true)
	end
end

----------------------------------

function FindCampsByMaxDifficulty(jungle, difficulty)
	result = {}
	for i,camp in pairs(jungle) do
		if camp[constants.DIFFICULTY] <= difficulty then
			result[#result+1] = camp
		end
	end
	return result
end

----------------------------------

local States = {
[JunglingStates.FindCamp]=FindCamp,
[JunglingStates.MoveToCamp]=MoveToCamp,
[JunglingStates.WaitForSpawn]=WaitForSpawn,
[JunglingStates.CleanCamp]=CleanCamp
}

----------------------------------

local function Updates(npcBot)
	if getHeroVar("JunglingState") ~= nil then
		JunglingState = getHeroVar("JunglingState");
	end
end


function Think(npcBot)
	Updates(npcBot);

	States[JunglingState](npcBot);

	setHeroVar("JunglingState", JunglingState);
end


--------
for k,v in pairs( jungling_generic ) do _G._savedEnv[k] = v end
