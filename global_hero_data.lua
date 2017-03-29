-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local DEFAULT_METHOD = true
local bDisableActions = false

X = {}

function X.InitHeroVar(pID)
    if X[pID] == nil then
        X[pID] = {}
        X[pID].actionQueue = {}
        X[pID].currentAction = {}
    end
end

function X.HasID(pID)
    return X[pID] ~= nil
end

function X.SetVar(pID, var, value)
    X[pID][var] = value
end

function X.GetVar(pID, var)
    return X[pID][var]
end

function X.SetGlobalVar(var, value)
    X[var] = value
end

function X.GetGlobalVar(var)
    return X[var]
end

function X.GetNearbyEnemies(bot, range)
    local endList = bot:GetNearbyHeroes(range, true, BOT_MODE_NONE)
    --local startList = X[bot:GetPlayerID()].NearbyEnemies
    --local endList = {}
    --for _, val in pairs(startList) do
    --    if GetUnitToUnitDistance(bot, val) <= range then
    --        table.insert(endList, val)
    --    end
    --end
    return endList
end

function X.GetNearbyAllies(bot, range)
    local endList = bot:GetNearbyHeroes(range, false, BOT_MODE_NONE)
    --local startList = X[bot:GetPlayerID()].NearbyAllies
    --local endList = {}
    --for _, val in pairs(startList) do
    --    if GetUnitToUnitDistance(bot, val) <= range then
    --        table.insert(endList, val)
    --    end
    --end
    return endList
end

function X.GetNearbyEnemyTowers(bot, range)
    local startList = bot:GetNearbyTowers(range, true)

    endList = {}
    for _, val in pairs(startList) do
        if string.find(val:GetUnitName(), "tower") then
            table.insert(endList, val)
        end
    end
    return endList
end

function X.GetNearbyEnemyBarracks(bot, range)
    local endList = bot:GetNearbyBarracks(range, true)
    --[[
    if #endList > 0 then
        utils.pause("[CRITICAL]: API bug fixed. plas adjust code. random uniqe marker: AWESDFWRGWFE")
    end

    local startList = bot:GetNearbyTowers(range, true)

    endList = {}
    for _, val in pairs(startList) do
        if string.find(val:GetUnitName(), "rax") then
            table.insert(endList, val)
        end
    end
    --]]
    return endList
end

function X.GetNearbyAlliedTowers(bot, range)
    local endList = bot:GetNearbyTowers(range, false)
    -- local startList = X[bot:GetPlayerID()].NearbyAlliedTowers
    -- local endList = {}
    -- for _, val in pairs(startList) do
        -- if GetUnitToUnitDistance(bot, val) <= range then
            -- table.insert(endList, val)
        -- end
    -- end
    return endList
end

function X.GetNearbyEnemyCreep(bot, range)
    local endList = bot:GetNearbyCreeps(range, true)
    -- local startList = X[bot:GetPlayerID()].NearbyEnemyCreep
    -- local endList = {}
    -- for _, val in pairs(startList) do
        -- if GetUnitToUnitDistance(bot, val) <= range then
            -- table.insert(endList, val)
        -- end
    -- end
    return endList
end

function X.GetNearbyAlliedCreep(bot, range)
    local endList = bot:GetNearbyCreeps(range, false)
    -- local startList = X[bot:GetPlayerID()].NearbyEnemyCreep
    -- local endList = {}
    -- for _, val in pairs(startList) do
        -- if GetUnitToUnitDistance(bot, val) <= range then
            -- table.insert(endList, val)
        -- end
    -- end
    return endList
end

-------------------------------------------------------------------------------
function X.SetHeroActionQueue(pID, aq)
    X[pID].actionQueue = {unpack(aq)}
end

function X.GetHeroActionQueue(pID)
    return X[pID].actionQueue
end

function X.GetHeroActionQueueSize(pID)
    return #X[pID].actionQueue
end

function X.GetHeroPrevAction(pID)
    return X[pID].prevAction or {}
end

function X.SetHeroPrevAction(pID, action)
    X[pID].prevAction = {unpack(action)}
end

function X.GetHeroCurrentAction(pID)
    return X[pID].currentAction
end

function X.SetHeroCurrentAction(pID, action)
    X[pID].currentAction = {unpack(action)}
end

local function checkSleepAttack(bot, ca)
    if #ca > 0 and ca[1] == "SleepAttack" then
        local pID = bot:GetPlayerID()
        if GameTime() < ca[2] then
            return true
        else
            X.SetHeroPrevAction(pID, ca)
            X[pID].currentAction = {}
        end
    end
    return false
end

function X.HeroMoveToLocation(bot, loc)
    if bot.DontMove then return end

    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end

    if GetUnitToLocationDistance(bot, loc) > 15.0 then
        bot:Action_MoveToLocation(loc)
    end
end

function X.HeroPushMoveToLocation(bot, loc)
    if bot.DontMove then return end

    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end

    if GetUnitToLocationDistance(bot, loc) > 15.0 then
        bot:ActionPush_MoveToLocation(loc)
    end
end

function X.HeroQueueMoveToLocation(bot, loc)
    bot:ActionQueue_MoveToLocation(loc)
end

function X.HeroMoveToUnit(bot, hUnit)
    if bot.DontMove then return end

    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end

    if GetUnitToUnitDistance(bot, hUnit) > 15.0 then
        bot:Action_MoveToUnit(hUnit)
    end
end

function X.HeroPushMoveToUnit(bot, hUnit)
    if bot.DontMove then return end

    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end

    if GetUnitToUnitDistance(bot, hUnit) > 15.0 then
        bot:ActionPush_MoveToUnit(hUnit)
    end
end

function X.HeroQueueMoveToUnit(bot, hUnit)
    bot:ActionQueue_MoveToUnit(hUnit)
end

function X.HeroAttackUnit(bot, hTarget, bOnce)
    local pID = bot:GetPlayerID()
    local bOnce = bOnce or true
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end

    X[pID].currentAction = {[1]="SleepAttack", [2]=GameTime()+bot:GetAttackPoint()}
    bot:Action_AttackUnit(hTarget, bOnce)
end

function X.HeroPushAttackUnit(bot, hTarget, bOnce)
    local pID = bot:GetPlayerID()
    local bOnce = bOnce or true
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end

    X[pID].currentAction = {[1]="SleepAttack", [2]=GameTime()+bot:GetAttackPoint()}
    bot:ActionPush_AttackUnit(hTarget, bOnce)
end

function X.HeroQueueAttackUnit(bot, hUnit, bOnce)
    bot:ActionQueue_AttackUnit(hUnit, bOnce)
end

function X.HeroAttackMove(bot, loc)
    if bot.DontMove then return end

    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end

    if GetUnitToLocationDistance(bot, loc) > 15.0 then
        bot:Action_AttackMove(loc)
    end
end

function X.HeroPushAttackMove(bot, loc)
    if bot.DontMove then return end

    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end

    if GetUnitToLocationDistance(bot, loc) > 15.0 then
        bot:ActionPush_AttackMove(loc)
    end
end

function X.HeroQueueAttackMove(bot, loc)
    bot:ActionQueue_AttackMove(loc)
end

function X.HeroUseAbility(bot, ability)
    bot:Action_UseAbility(ability)
end

function X.HeroPushUseAbility(bot, ability)
    bot:ActionPush_UseAbility(ability)
end

function X.HeroQueueUseAbility(bot, ability)
    bot:ActionQueue_UseAbility(ability)
end

function X.HeroUseAbilityOnEntity(bot, ability, hUnit)
    bot:Action_UseAbilityOnEntity(ability, hUnit)
    bot.AbilityOnEntityUseTime = GameTime()
end

function X.HeroPushUseAbilityOnEntity(bot, ability, hUnit)
    bot:ActionPush_UseAbilityOnEntity(ability, hUnit)
    bot.AbilityOnEntityUseTime = GameTime()
end

function X.HeroQueueUseAbilityOnEntity(bot, ability, hUnit)
    bot:ActionQueue_UseAbilityOnEntity(ability, hUnit)
end

function X.HeroUseAbilityOnLocation(bot, ability, loc)
    bot:Action_UseAbilityOnLocation(ability, loc)
end

function X.HeroPushUseAbilityOnLocation(bot, ability, loc)
    bot:ActionPush_UseAbilityOnLocation(ability, loc)
end

function X.HeroQueueUseAbilityOnLocation(bot, ability, loc)
    bot:ActionQueue_UseAbilityOnLocation(ability, loc)
end

function X.HeroUseAbilityOnTree(bot, ability, iTree)
    bot:Action_UseAbilityOnTree(ability, iTree)
end

function X.HeroPushUseAbilityOnTree(bot, ability, iTree)
    bot:ActionPush_UseAbilityOnTree(ability, iTree)
end

function X.HeroQueueUseAbilityOnTree(bot, ability, iTree)
    bot:ActionQueue_UseAbilityOnTree(ability, iTree)
end

function X.ExecuteHeroActionQueue(bot)
    return
end

return X
