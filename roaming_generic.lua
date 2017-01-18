-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

-------
_G._savedEnv = getfenv()
module( "roaming_generic", package.seeall )
----------
local utils = require( GetScriptDirectory().."/utility")
require( GetScriptDirectory().."/constants" )
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

local RoamingStates={
	FindTarget=0,
	KillTarget=1
}

local RoamingState=RoamingStates.FindTarget;


function OnStart(npcBot)
	RoamingState=RoamingStates.FindTarget;
end

----------------------------------

local function FindTarget(bot)

end

local function KillTarget(bot)
	
end

----------------------------------

local States = {
[RoamingStates.FindTarget]=FindTarget,
[RoamingStates.KillTarget]=KillTarget
}

----------------------------------

local function Updates(npcBot)
	if getHeroVar("RoamingState") ~= nil then
		RoamingState = getHeroVar("RoamingState");
	end
end


function Think(npcBot)
	Updates(npcBot);

	States[RoamingState](npcBot);

	setHeroVar("RoamingState", RoamingState);
end


--------
for k,v in pairs( jungling_generic ) do _G._savedEnv[k] = v end
