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

----------

local JunglingStates={
    FindCamp    = 0,
    MoveToCamp  = 1,
    WaitForSpawn= 2,
    Stack       = 3,
    CleanCamp   = 4
}

local me = nil
local move_ticks = 0

function OnStart(myBot)
    me = myBot
    me:setHeroVar("JunglingState", JunglingStates.FindCamp)
    move_ticks = 0
end

function OnEnd()
end

----------------------------------

local function FindCamp(bot)
    -- TODO: just killing the closest one might not be the best strategy
    local jungle = jungle_status.GetJungle(GetTeam()) or {}
    local maxcamplvl = me:getHeroVar("Self"):GetMaxClearableCampLevel(bot)
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
            if allyID ~= me.pID and gHeroVar.HasID(allyId) then
                local allyCamp = gHeroVar.GetVar(allyID, "currentCamp")
                if not (allyCamp == nil or allyCamp ~= camp) then
                    utils.myPrint(utils.GetHeroName(ally), "took nearest camp, going to another")
                    camp = camp2
                end
            end
        end
    end

    if me:getHeroVar("currentCamp") == nil or camp[constants.VECTOR] ~= me:getHeroVar("currentCamp")[constants.VECTOR] then
        utils.myPrint("moves to camp")
    end
    me:setHeroVar("currentCamp", camp)
    me:setHeroVar("JunglingState", JunglingStates.MoveToCamp)
    move_ticks = 0
end

local function MoveToCamp(bot)
    if me:getHeroVar("currentCamp") == nil then
        me:setHeroVar("JunglingState", JunglingStates.FindCamp)
        return
    end
    
    if GetUnitToLocationDistance(bot, me:getHeroVar("currentCamp")[constants.VECTOR]) > 200 then
        if move_ticks > 50 then -- don't do this every frame
            me:setHeroVar("JunglingState", JunglingStates.FindCamp) -- crossing the jungle takes a lot of time. Check for camps that may have spawned
            return
        else
            move_ticks = move_ticks + 1
        end
        gHeroVar.HeroMoveToLocation(bot, me:getHeroVar("currentCamp")[constants.VECTOR])
        return
    end

    local neutrals = bot:GetNearbyCreeps(1200, true)
    if #neutrals == 0 then -- no creeps here
        local jungle = jungle_status.GetJungle(GetTeam()) or {}
        jungle = FindCampsByMaxDifficulty(jungle, me:getHeroVar("Self"):GetMaxClearableCampLevel(bot))
        if #jungle == 0 then -- jungle is empty
            me:setHeroVar("waituntil", utils.NextNeutralSpawn())
            utils.myPrint("waits for spawn")
            me:setHeroVar("JunglingState", JunglingStates.WaitForSpawn)
        else
            utils.myPrint("No creeps here :(") -- one of   dumb me, dumb teammates, blocked by enemy, farmed by enemy
            jungle_status.JungleCampClear(GetTeam(), me:getHeroVar("currentCamp")[constants.VECTOR])
            utils.myPrint("finds camp")
            me:setHeroVar("JunglingState", JunglingStates.FindCamp)
        end
    else
        --print(utils.GetHeroName(bot), "KILLS")
        me:setHeroVar("JunglingState", JunglingStates.CleanCamp)
    end
end

local function WaitForSpawn(bot)
    if DotaTime() < me:getHeroVar("waituntil") then
        gHeroVar.HeroMoveToLocation(bot, me:getHeroVar("currentCamp")[constants.STACK_VECTOR]) -- TODO: use a vector that is closer to the camp
        return
    end
    me:setHeroVar("JunglingState", JunglingStates.MoveToCamp)
end

local function Stack(bot)
    if DotaTime() < me:getHeroVar("waituntil") then
        gHeroVar.HeroMoveToLocation(bot, me:getHeroVar("currentCamp")[constants.STACK_VECTOR])
        return
    end
    me:setHeroVar("JunglingState", JunglingStates.FindCamp)
end

local function CleanCamp(bot)
    -- TODO: make sure we have aggro when attempting to stack
    -- TODO: don't attack enemy creeps, unless they attack us / make sure we stay in jungle
    -- TODO: instead of stacking, could we just kill them and move ou of the camp?
    -- TODO: make sure we can actually kill the camp.

    local dtime = DotaTime() % 120
    local stacktime = me:getHeroVar("currentCamp")[constants.STACK_TIME]
    if dtime >= stacktime and dtime <= stacktime + 1 then
        me:setHeroVar("JunglingState", JunglingStates.Stack)
        utils.myPrint("stacks")
        me:setHeroVar("waituntil", utils.NextNeutralSpawn())
        return
    end

    local neutrals = bot:GetNearbyCreeps(EyeRange, true)
    if #neutrals == 0 then -- we did it
        local camp, _ = utils.NearestNeutralCamp(bot, jungle_status.GetJungle(GetTeam())) -- we might not have killed the `currentCamp`
        -- we could have been killing lane creeps, don't mistaken for neutral
        if GetUnitToLocationDistance(bot, camp[constants.VECTOR]) <= 200 then
            jungle_status.JungleCampClear(GetTeam(), camp[constants.VECTOR])
        end
        utils.myPrint("finds camp")
        me:setHeroVar("JunglingState", JunglingStates.FindCamp)
    else
        me:DoCleanCamp(bot, neutrals, me:getHeroVar("currentCamp").difficulty)
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

function Think(bot)
    if utils.IsBusy(bot) then return end

    States[me:getHeroVar("JunglingState")](bot)
end


--------
for k,v in pairs( jungling_generic ) do _G._savedEnv[k] = v end
