-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

-------
_G._savedEnv = getfenv()
module( "ganking_generic", package.seeall )
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
local HeroCountFactor = 0.3
local MinRating = 1.0;

local IsCore = nil;

local GankingStates={
	FindTarget=0,
	KillTarget=1
}

local GankingState=GankingStates.FindTarget;


function OnStart(npcBot)
	GankingState=GankingStates.FindTarget;
    setHeroVar("move_ticks", 0)
end

----------------------------------

local function FindTarget(bot)
	-- TODO: don't do this every frame and for every ganking hero. Should be part of team level logic.
	local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES); -- check all enemies
    local allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    local ratings = {}
    for i, e in pairs(enemies) do
        if e:CanBeSeen() then
            local r = 0
            r = r + HealthFactor * (1 - e:GetHealth()/e:GetMaxHealth())
            -- time to get there in 10s units
            r = r - DistanceFactor * GetUnitToUnitDistance(bot, e) / 300 / 10 -- TODO: get move speed
            r = r + UnitPosFactor * (1 - utils.GetPositionBetweenBuildings(e, GetTeam()))
            local hero_count = 0
            for _, enemy in pairs(enemies) do
                if enemy:CanBeSeen() and utils.GetHeroName(enemy) ~= utils.GetHeroName(e) then
                    if GetUnitToUnitDistance(enemy, e) < 1500 then
                        hero_count = hero_count - 1
                    end
                end
            end
            for _, ally in pairs(allies) do
                if utils.GetHeroName(ally) ~= utils.GetHeroName(bot) then
                    if GetUnitToUnitDistance(ally, e) < 1500 then
                        hero_count = hero_count + 1
                    end
                end
            end
            r = r + HeroCountFactor * hero_count
            if false then
                  print(utils.GetHeroName(e), 1 - e:GetHealth()/e:GetMaxHealth())
                  print(utils.GetHeroName(e), HealthFactor * (1 - e:GetHealth()/e:GetMaxHealth()))
                  print(utils.GetHeroName(e), GetUnitToUnitDistance(bot, e) / 300 / 10)
                  print(utils.GetHeroName(e), DistanceFactor * GetUnitToUnitDistance(bot, e) / 300 / 10)
                  print(utils.GetHeroName(e), 1 - utils.GetPositionBetweenBuildings(e, GetTeam()))
                  print(utils.GetHeroName(e), UnitPosFactor * (1 - utils.GetPositionBetweenBuildings(e, GetTeam())))
                  print(utils.GetHeroName(e), hero_count)
                  print(utils.GetHeroName(e), HeroCountFactor * hero_count)
                  print(utils.GetHeroName(e), r)
            end
            ratings[#ratings+1] = {r, e}
        end
    end
	  if #ratings == 0 then
	      return false
	  end
    table.sort(ratings, function(a, b) return a[1] > b[1] end) -- sort by rating, descending
		local rating = ratings[1][1]
		if rating < MinRating then -- not worth
			return false
		end
    local target = ratings[1][2]
    setHeroVar("GankTarget", target)
    setHeroVar("move_ticks", 0)
    print(utils.GetHeroName(bot), "let's kill", utils.GetHeroName(target))
    GankingState = GankingStates.KillTarget
    return true
end

local function KillTarget(bot)
    local move_ticks = getHeroVar("move_ticks")
    if move_ticks > 50 then -- time to check for targets again
        GankingState = GankingStates.FindTarget
        return true
    else
        setHeroVar("move_ticks", move_ticks + 1)
    end

	local target = getHeroVar("GankTarget")
    if target ~= nil and target:GetHealth() ~= -1 and target:CanBeSeen() then
				if GetUnitToUnitDistance(bot, target) < 1000 then
					getHeroVar("Self"):RemoveAction(ACTION_GANKING)
					getHeroVar("Self"):AddAction(ACTION_FIGHT)
					setHeroVar("Target", target)
					print(utils.GetHeroName(bot), "found his target!")
					-- TODO: kill!
				else
        	bot:Action_AttackUnit(target, true) -- Let's go there
				end
        -- TODO: consider being sneaky
        return true
    else
        GankingState = GankingStates.KillTarget
        return true
    end
end

----------------------------------

local States = {
[GankingStates.FindTarget]=FindTarget,
[GankingStates.KillTarget]=KillTarget
}

----------------------------------

local function Updates(npcBot)
	if getHeroVar("GankingState") ~= nil then
		GankingState = getHeroVar("GankingState");
	end
end


function Think(npcBot)
	Updates(npcBot);

	local result = States[GankingState](npcBot);

	setHeroVar("GankingState", GankingState);

    return result
end


--------
for k,v in pairs( jungling_generic ) do _G._savedEnv[k] = v end
