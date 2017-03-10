-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
local utils = require( GetScriptDirectory().."/utility")
require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/jungle_status")

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

----------

local JunglingStates = {
    FindCamp    = 0,
    MoveToCamp  = 1,
    WaitForSpawn= 2,
    Stack       = 3,
    CleanCamp   = 4
}

function X:GetName()
    return "jungling"
end

function X:OnStart(myBot)
    setHeroVar("JunglingState", JunglingStates.FindCamp)
    setHeroVar("move_ticks", 0)
end

function X:OnEnd()
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
    setHeroVar("JunglingState", JunglingStates.MoveToCamp)
    setHeroVar("move_ticks", 0)
end

local function MoveToCamp(bot)
    if getHeroVar("currentCamp") == nil then
        setHeroVar("JunglingState", JunglingStates.FindCamp)
        return
    end
    
    if GetUnitToLocationDistance(bot, getHeroVar("currentCamp")[constants.VECTOR]) > 200 then
        if getHeroVar("move_ticks") > 50 then -- don't do this every frame
            setHeroVar("JunglingState", JunglingStates.FindCamp) -- crossing the jungle takes a lot of time. Check for camps that may have spawned
            return
        else
            setHeroVar("move_ticks", getHeroVar("move_ticks") + 1)
        end
        gHeroVar.HeroMoveToLocation(bot, getHeroVar("currentCamp")[constants.VECTOR])
        return
    end

    local neutrals = gHeroVar.GetNearbyEnemyCreep(bot, 900)
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
        gHeroVar.HeroMoveToLocation(bot, getHeroVar("currentCamp")[constants.STACK_VECTOR]) -- TODO: use a vector that is closer to the camp
        return
    end
    setHeroVar("JunglingState", JunglingStates.MoveToCamp)
end

local function Stack(bot)
    if DotaTime() < getHeroVar("waituntil") then
        gHeroVar.HeroMoveToLocation(bot, getHeroVar("currentCamp")[constants.STACK_VECTOR])
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
        --utils.myPrint("stacks")
        setHeroVar("waituntil", utils.NextNeutralSpawn())
        return
    end

    local neutrals = gHeroVar.GetNearbyEnemyCreep(bot, 900)
    if #neutrals == 0 then -- we did it
        local camp, _ = utils.NearestNeutralCamp(bot, jungle_status.GetJungle(GetTeam())) -- we might not have killed the `currentCamp`
        -- we could have been killing lane creeps, don't mistaken for neutral
        if GetUnitToLocationDistance(bot, camp[constants.VECTOR]) <= 200 then
            jungle_status.JungleCampClear(GetTeam(), camp[constants.VECTOR])
        end
        utils.myPrint("finds camp")
        setHeroVar("JunglingState", JunglingStates.FindCamp)
    else
        getHeroVar("Self"):DoCleanCamp(bot, neutrals, getHeroVar("currentCamp").difficulty)
    end
end

----------------------------------

function FindCampsByMaxDifficulty(jungle, difficulty)
    local result = {}
    for i,camp in pairs(jungle) do
        if camp[constants.DIFFICULTY] <= difficulty then
            result[#result+1] = camp
        end
    end
    return result
end

----------------------------------

local States = {
    [JunglingStates.FindCamp]       = FindCamp,
    [JunglingStates.MoveToCamp]     = MoveToCamp,
    [JunglingStates.WaitForSpawn]   = WaitForSpawn,
    [JunglingStates.Stack]          = Stack,
    [JunglingStates.CleanCamp]      = CleanCamp
}

----------------------------------

function X:Think(bot)
    if utils.IsBusy(bot) then return end

    States[getHeroVar("JunglingState")](bot)
end

function X:Desire(bot)
    if getHeroVar("Role") == constants.ROLE_JUNGLER then
        return BOT_MODE_DESIRE_MODERATE
    end
    return BOT_MODE_DESIRE_NONE
end

return X