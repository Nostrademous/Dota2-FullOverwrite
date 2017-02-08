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

local JunglingStates={
    FindCamp=0,
    MoveToCamp=1,
    WaitForSpawn=2,
    Stack=3,
    CleanCamp=4
}

function OnStart(npcBot)
    setHeroVar("JunglingState", JunglingStates.FindCamp)
    setHeroVar("move_ticks", 0)
    -- TODO: if there are camps, consider tp'ing to the jungle

    -- TODO: Pickup runes
    -- TODO: help lanes
    -- TODO: when to stop jungling? (NEVER!!)
end

function OnResume(bot)
    utils.myPrint("resume jungling")
    setHeroVar("JunglingState", JunglingStates.FindCamp) -- reset state
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
    local camp, camp2 = utils.NearestNeutralCamp(bot, jungle)

    if camp2 ~= nil then
        local listAllies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
        for _, ally in pairs(listAllies) do
            local allyID = ally:GetPlayerID()
            if allyID ~= bot:GetPlayerID() and gHeroVar.HasID(allyId) then
                local allyCamp = gHeroVar.GetVar(allyID, "currentCamp")
                if not (allyCamp == nil or allyCamp ~= camp) then
                    utils.myPrint(utils.GetHeroName(ally), "took nearest camp, going to another")
                    camp = camp2
                end
            end
        end
    end

    if getHeroVar("currentCamp") == nil or camp[constants.VECTOR] ~= getHeroVar("currentCamp")[constants.VECTOR] then
        utils.myPrint("moves to camp")
    end
    setHeroVar("currentCamp", camp)
    setHeroVar("move_ticks", 0)
    setHeroVar("JunglingState", JunglingStates.MoveToCamp)
end

local function MoveToCamp(bot)
    if getHeroVar("currentCamp") == nil then
        setHeroVar("JunglingState", JunglingStates.FindCamp)
        return
    end
    if GetUnitToLocationDistance(bot, getHeroVar("currentCamp")[constants.VECTOR]) > 200 then
        local ticks = getHeroVar("move_ticks")
        if ticks > 50 then -- don't do this every frame
            setHeroVar("JunglingState", JunglingStates.FindCamp) -- crossing the jungle takes a lot of time. Check for camps that may have spawned
            return
        else
            setHeroVar("move_ticks", ticks + 1)
        end
        bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.VECTOR])
        return
    end
    local neutrals = bot:GetNearbyNeutralCreeps(EyeRange)
    --[[
    local allNeutrals = GetUnitList(UNIT_LIST_NEUTRAL_CREEPS)
    for _, n in ipairs(allNeutrals) do
        if GetUnitToUnitDistance(bot, n) < EyeRange then
            table.insert(neutrals, n)
        end
    end
    --]]
    
    if #neutrals == 0 then -- no creeps here
        local jungle = jungle_status.GetJungle(GetTeam()) or {}
        jungle = FindCampsByMaxDifficulty(jungle, getHeroVar("Self"):GetMaxClearableCampLevel(bot))
        if #jungle == 0 then -- jungle is empty
            setHeroVar("waituntil", utils.NextNeutralSpawn())
            utils.myPrint("waits for spawn")
            setHeroVar("JunglingState", JunglingStates.WaitForSpawn)
        else
            utils.myPrint("No creeps here :(") -- one of   dumb me, dumb teammates, blocked by enemy, farmed by enemy
            jungle_status.JungleCampClear(GetTeam(), getHeroVar("currentCamp")[constants.VECTOR])
            utils.myPrint("finds camp")
            setHeroVar("JunglingState", JunglingStates.FindCamp)
        end
    else
        --print(utils.GetHeroName(bot), "KILLS")
        setHeroVar("JunglingState", JunglingStates.CleanCamp)
    end
end

local function WaitForSpawn(bot)
    if DotaTime() < getHeroVar("waituntil") then
        bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.STACK_VECTOR]) -- TODO: use a vector that is closer to the camp
        return
    end
    setHeroVar("JunglingState", JunglingStates.MoveToCamp)
end

local function Stack(bot)
    if DotaTime() < getHeroVar("waituntil") then
        bot:Action_MoveToLocation(getHeroVar("currentCamp")[constants.STACK_VECTOR])
        return
    end
    setHeroVar("JunglingState", JunglingStates.FindCamp)
end

local function CleanCamp(bot)
    -- TODO: make sure we have aggro when attempting to stack
    -- TODO: don't attack enemy creeps, unless they attack us / make sure we stay in jungle
    -- TODO: instead of stacking, could we just kill them and move ou of the camp?
    -- TODO: make sure we can actually kill the camp.

    local dtime = DotaTime() % 120
    local stacktime = getHeroVar("currentCamp")[constants.STACK_TIME]
    if dtime >= stacktime and dtime <= stacktime + 1 then
        setHeroVar("JunglingState", JunglingStates.Stack)
        utils.myPrint("stacks")
        setHeroVar("waituntil", utils.NextNeutralSpawn())
        return
    end
    local neutrals = bot:GetNearbyNeutralCreeps(EyeRange)
    --[[
    local allNeutrals = GetUnitList(UNIT_LIST_NEUTRAL_CREEPS)
    for _, n in ipairs(allNeutrals) do
        if GetUnitToUnitDistance(bot, n) < EyeRange then
            table.insert(neutrals, n)
        end
    end
    --]]
    
    if #neutrals == 0 then -- we did it
        local camp, _ = utils.NearestNeutralCamp(bot, jungle_status.GetJungle(GetTeam())) -- we might not have killed the `currentCamp`
        -- we could have been killing lane creeps, don't mistaken for neutral
        if GetUnitToLocationDistance(bot, camp[constants.VECTOR]) <= 200 then
            jungle_status.JungleCampClear(GetTeam(), camp[constants.VECTOR])
        end
        utils.myPrint("finds camp")
        setHeroVar("JunglingState", JunglingStates.FindCamp)
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

function Think(npcBot)
    --[[
    local me = getHeroVar("Self")
    if me:getPrevAction() ~= ACTION_JUNGLING then
        OnResume(npcBot)
    end
    --]]
    if npcBot:IsUsingAbility() then return end

    States[getHeroVar("JunglingState")](npcBot)
end


--------
for k,v in pairs( jungling_generic ) do _G._savedEnv[k] = v end
