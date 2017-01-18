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

local HealthFactor = 1
local UnitPosFactor = 1
local DistanceFactor = 0.1

local IsCore = nil;

local RoamingStates={
	FindTarget=0,
	KillTarget=1
}

local RoamingState=RoamingStates.FindTarget;


function OnStart(npcBot)
	RoamingState=RoamingStates.FindTarget;
    setHeroVar("move_ticks") = 0
end

----------------------------------

local function FindTarget(bot)
	local enemies = bot:GetNearbyHeroes(999999, true, BOT_MODE_NONE); -- check all enemies
    if #enemies == 0 then
        return false
    end
    local ratings = {}
    for i, e in pairs(enemies) do
        local r = 0
        r += HealthFactor * (1 - e:GetHealth()/e:GetMaxHealth())
        print(utils.GetHeroName(e), 1 - e:GetHealth()/e:GetMaxHealth())
        print(utils.GetHeroName(e), HealthFactor * (1 - e:GetHealth()/e:GetMaxHealth()))
        -- time to get there in 10s units
        r += DistanceFactor * GetUnitToUnitDistance(bot, e) / 300 / 10 -- TODO: get move speed
        print(utils.GetHeroName(e), GetUnitToUnitDistance(bot, e) / 300 / 10)
        print(utils.GetHeroName(e), DistanceFactor * GetUnitToUnitDistance(bot, e) / 300 / 10)
        r += UnitPosFactor * (1 - utils.GetPositionBetweenBuildings(e, GetTeam()))
        print(utils.GetHeroName(e), 1 - utils.GetPositionBetweenBuildings(e, GetTeam()))
        print(utils.GetHeroName(e), UnitPosFactor * (1 - utils.GetPositionBetweenBuildings(e, GetTeam())))
        print(utils.GetHeroName(e), r)
        -- TODO: rate the number of heroes
        ratings[i] = {r, e}
    end
    table.sort(ratings, function(a, b) return a[2] > b[2] end) -- sort by rating, descending
    local target = ratings[1][1]
    setHeroVar("RoamTarget", target)
    setHeroVar("move_ticks", 0)
    print(utils.GetHeroName(bot), "let's kill", utils.GetHeroName(target))
    RoamingState = RoamingStates.KillTarget
    return true
end

local function KillTarget(bot)
    local move_ticks = getHeroVar("move_ticks")
    
    if move_ticks > 50 then -- time to check for targets again
        RoamingState = RoamingStates.KillTarget
        return true
    else
        setHeroVar("move_ticks", move_ticks + 1)
    end

	local target = getHeroVar("RoamTarget")
    if target:CanBeSeen() then
        bot:Action_MoveToUnit(target) -- Let's go there
        return true
    else
        RoamingState = RoamingStates.KillTarget
        return true
    end
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

	local result = States[RoamingState](npcBot);

	setHeroVar("RoamingState", RoamingState);
    
    return result
end


--------
for k,v in pairs( jungling_generic ) do _G._savedEnv[k] = v end
