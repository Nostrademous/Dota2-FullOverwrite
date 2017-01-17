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
	Stack=3,
	CleanCamp=4
}

local JunglingState=JunglingStates.FindCamp;


function OnStart(npcBot)
	JunglingState=JunglingStates.FindCamp;
	setHeroVar("move_ticks", 0)
	-- TODO: if there are camps, consider tp'ing to the jungle

	-- TODO: implement stacking
	-- TODO: Pickup runes
	-- TODO: help lanes
	-- TODO: when to stop jungling? (NEVER!!)
end

----------------------------------

local function FindCamp(bot)
	-- TODO: just killing the closest one might not be the best strategy
	local jungle = jungle_status.GetJungle(GetTeam()) or {}
	local maxcamplvl = getHeroVar("Self"):GetMaxClearableCampLevel(bot)
	jungle = FindCampsByMaxDifficulty(jungle, maxcamplvl)
	if #jungle == 0 then -- they are all dead
		jungle = utils.deepcopy(utils.tableNeutralCamps[GetTeam()])
		jungle = FindCampsByMaxDifficulty(jungle, maxcamplvl)
	end
	local camp = utils.NearestNeutralCamp(bot, jungle)
	if getHeroVar("currentCamp") == nil or camp[constants.VECTOR] ~= getHeroVar("currentCamp")[constants.VECTOR] then
		print(utils.GetHeroName(bot), "moves to camp")
	end
	setHeroVar("currentCamp", camp)
	setHeroVar("move_ticks", 0)
	JunglingState = JunglingStates.MoveToCamp
end

local function MoveToCamp(bot)
	if GetUnitToLocationDistance(bot, getHeroVar("currentCamp")[constants.VECTOR]) > 200 then
		local ticks = getHeroVar("move_ticks")
		if ticks > 50 then -- don't do this every frame
			JunglingState = JunglingStates.FindCamp -- crossing the jungle takes a lot of time. Check for camps that may have spawned
			return
		else
			setHeroVar("move_ticks", ticks + 1)
		end
		bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.VECTOR])
		return
	end
	local neutrals = bot:GetNearbyCreeps(EyeRange,true);
	if #neutrals == 0 then -- no creeps here
		local jungle = jungle_status.GetJungle(GetTeam()) or {}
		jungle = FindCampsByMaxDifficulty(jungle, getHeroVar("Self"):GetMaxClearableCampLevel(bot))
		if #jungle == 0 then -- jungle is empty
			setHeroVar("waituntil", utils.NextNeutralSpawn())
			print(utils.GetHeroName(bot), "waits for spawn")
			JunglingState = JunglingStates.WaitForSpawn
		else
			print("No creeps here :(") -- one of   dumb me, dumb teammates, blocked by enemy, farmed by enemy
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
	if DotaTime() < getHeroVar("waituntil") then
		bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.STACK_VECTOR]) -- TODO: use a vector that is closer to the camp
		return
	end
	JunglingState = JunglingStates.MoveToCamp
end

local function Stack(bot)
	if DotaTime() < getHeroVar("waituntil") then
		bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.STACK_VECTOR])
		return
	end
	JunglingState = JunglingStates.FindCamp
end

local function CleanCamp(bot)
	-- TODO: make sure we have aggro when attempting to stack
	-- TODO: don't attack enemy creeps, unless they attack us / make sure we stay in jungle
	-- TODO: instead of stacking, could we just kill them and move ou of the camp?
	-- TODO: make sure we can actually kill the camp.
	local time = DotaTime() % 120
	local stacktime = getHeroVar("currentCamp")[constants.STACK_TIME]
	if time >= stacktime and time <= stacktime + 1 then
		JunglingState = JunglingStates.Stack
		print(utils.GetHeroName(bot), "stacks")
		setHeroVar("waituntil", utils.NextNeutralSpawn())
		return
	end
	local neutrals = bot:GetNearbyCreeps(EyeRange,true);
	if #neutrals == 0 then -- we did it
		jungle_status.JungleCampClear(GetTeam(), getHeroVar("currentCamp")[constants.VECTOR])
		print(utils.GetHeroName(bot), "finds camp")
		JunglingState = JunglingStates.FindCamp
	else
		getHeroVar("Self"):DoCleanCamp(bot, neutrals)
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
[JunglingStates.Stack]=Stack,
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
