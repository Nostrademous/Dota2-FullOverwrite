-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

-------
_G._savedEnv = getfenv()
module( "jungling_generic", package.seeall )
----------
local utils = require( GetScriptDirectory().."/utility")
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
	Start=0
}

local JunglingState=JunglingStates.Start;

function OnStart(npcBot)
	--print(utils.GetHeroName(npcBot), " LANING OnStart Done")
end


----------------------------------

local function Start()
	-- print("start called")
end

----------------------------------

local States = {
[JunglingStates.Start]=Start
}

----------------------------------

local function Updates(npcBot)
	if npcBot.JunglingState ~= nil then
		JunglingState = npcBot.JunglingState;
	end
end


function Think(npcBot)
	Updates(npcBot);

	States[JunglingState](npcBot);

	npcBot.JunglingState = JunglingState;
end


--------
for k,v in pairs( jungling_generic ) do _G._savedEnv[k] = v end
