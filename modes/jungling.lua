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

----------

local JunglingStates = {
    FindCamp    = 0,
    MoveToCamp  = 1,
    WaitForSpawn= 2,
    Stack       = 3,
    CleanCamp   = 4
}

X.me = nil
X.move_ticks = 0

function X:GetName()
    return "Jungling Mode"
end

function X:OnStart(myBot)
    X.me = myBot
    X.me:setHeroVar("JunglingState", JunglingStates.FindCamp)
    X.move_ticks = 0
end

function X:OnEnd()
end

----------------------------------

local function FindCamp(bot)
    -- TODO: just killing the closest one might not be the best strategy
    local jungle = jungle_status.GetJungle(GetTeam()) or {}
    local maxcamplvl = X.me:getHeroVar("Self"):GetMaxClearableCampLevel(bot)
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
            if allyID ~= X.me.pID and gHeroVar.HasID(allyId) then
                local allyCamp = gHeroVar.GetVar(allyID, "currentCamp")
                if not (allyCamp == nil or allyCamp ~= camp) then
                    utils.myPrint(utils.GetHeroName(ally), "took nearest camp, going to another")
                    camp = camp2
                end
            end
        end
    end

    if X.me:getHeroVar("currentCamp") == nil or camp[constants.VECTOR] ~= X.me:getHeroVar("currentCamp")[constants.VECTOR] then
        utils.myPrint("moves to camp")
    end
    X.me:setHeroVar("currentCamp", camp)
    X.me:setHeroVar("JunglingState", JunglingStates.MoveToCamp)
    X.move_ticks = 0
end

local function MoveToCamp(bot)
    if X.me:getHeroVar("currentCamp") == nil then
        X.me:setHeroVar("JunglingState", JunglingStates.FindCamp)
        return
    end
    
    if GetUnitToLocationDistance(bot, X.me:getHeroVar("currentCamp")[constants.VECTOR]) > 200 then
        if X.move_ticks > 50 then -- don't do this every frame
            X.me:setHeroVar("JunglingState", JunglingStates.FindCamp) -- crossing the jungle takes a lot of time. Check for camps that may have spawned
            return
        else
            X.move_ticks = X.move_ticks + 1
        end
        gHeroVar.HeroMoveToLocation(bot, X.me:getHeroVar("currentCamp")[constants.VECTOR])
        return
    end

    local neutrals = bot:GetNearbyCreeps(1200, true)
    if #neutrals == 0 then -- no creeps here
        local jungle = jungle_status.GetJungle(GetTeam()) or {}
        jungle = FindCampsByMaxDifficulty(jungle, X.me:getHeroVar("Self"):GetMaxClearableCampLevel(bot))
        if #jungle == 0 then -- jungle is empty
            X.me:setHeroVar("waituntil", utils.NextNeutralSpawn())
            utils.myPrint("waits for spawn")
            X.me:setHeroVar("JunglingState", JunglingStates.WaitForSpawn)
        else
            utils.myPrint("No creeps here :(") -- one of   dumb me, dumb teammates, blocked by enemy, farmed by enemy
            jungle_status.JungleCampClear(GetTeam(), X.me:getHeroVar("currentCamp")[constants.VECTOR])
            utils.myPrint("finds camp")
            X.me:setHeroVar("JunglingState", JunglingStates.FindCamp)
        end
    else
        --print(utils.GetHeroName(bot), "KILLS")
        X.me:setHeroVar("JunglingState", JunglingStates.CleanCamp)
    end
end

local function WaitForSpawn(bot)
    if DotaTime() < X.me:getHeroVar("waituntil") then
        gHeroVar.HeroMoveToLocation(bot, X.me:getHeroVar("currentCamp")[constants.STACK_VECTOR]) -- TODO: use a vector that is closer to the camp
        return
    end
    X.me:setHeroVar("JunglingState", JunglingStates.MoveToCamp)
end

local function Stack(bot)
    if DotaTime() < X.me:getHeroVar("waituntil") then
        gHeroVar.HeroMoveToLocation(bot, X.me:getHeroVar("currentCamp")[constants.STACK_VECTOR])
        return
    end
    X.me:setHeroVar("JunglingState", JunglingStates.FindCamp)
end

local function CleanCamp(bot)
    -- TODO: make sure we have aggro when attempting to stack
    -- TODO: don't attack enemy creeps, unless they attack us / make sure we stay in jungle
    -- TODO: instead of stacking, could we just kill them and move ou of the camp?
    -- TODO: make sure we can actually kill the camp.

    local dtime = DotaTime() % 120
    local stacktime = X.me:getHeroVar("currentCamp")[constants.STACK_TIME]
    if dtime >= stacktime and dtime <= stacktime + 1 then
        X.me:setHeroVar("JunglingState", JunglingStates.Stack)
        --utils.myPrint("stacks")
        X.me:setHeroVar("waituntil", utils.NextNeutralSpawn())
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
        X.me:setHeroVar("JunglingState", JunglingStates.FindCamp)
    else
        X.me:DoCleanCamp(bot, neutrals, X.me:getHeroVar("currentCamp").difficulty)
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

    States[X.me:getHeroVar("JunglingState")](bot)
end

return X