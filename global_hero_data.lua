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
    local endList = bot:GetNearbyTowers(range, true)
    --local startList = X[bot:GetPlayerID()].NearbyEnemyTowers
    --local endList = {}
    --for _, val in pairs(startList) do
    --    if GetUnitToUnitDistance(bot, val) <= range then
    --        table.insert(endList, val)
    --    end
    --end
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
    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)
    
    if checkSleepAttack(bot, ca) then return end
    
    if GetUnitToLocationDistance(bot, loc) > 15.0 then
        bot:Action_MoveToLocation(loc)
    end
end

function X.HeroPushMoveToLocation(bot, loc)    
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
    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)
    
    if checkSleepAttack(bot, ca) then return end
    
    if GetUnitToUnitDistance(bot, hUnit) > 15.0 then
        bot:Action_MoveToUnit(hUnit)
    end
end

function X.HeroPushMoveToUnit(bot, hUnit)
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
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local bOnce = bOnce or true
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end
    
    if #ca == 0 or not (ca[1] == "AttackUnit" and ca[2] == hTarget and ca[3] == bOnce) then
        if DEFAULT_METHOD then
            X[pID].currentAction = {[1]="SleepAttack", [2]=GameTime()+bot:GetAttackPoint()}
            bot:Action_AttackUnit(hTarget, bOnce)
        else
            X[pID].prevAction = {unpack(X[pID].currentAction)}
            X[pID].currentAction = {}
            X[pID].actionQueue = {{[1]="AttackUnit", [2]=hTarget, [3]=bOnce}, {[1]="SleepAttack", [2]=GameTime()+bot:GetAttackPoint()}}
        end
    end
end

function X.HeroPushAttackUnit(bot, hTarget, bOnce)
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local bOnce = bOnce or true
    local ca = X.GetHeroCurrentAction(pID)

    if checkSleepAttack(bot, ca) then return end
    
    if #ca == 0 or not (ca[1] == "AttackUnit" and ca[2] == hTarget and ca[3] == bOnce) then
        if DEFAULT_METHOD then
            X[pID].currentAction = {[1]="SleepAttack", [2]=GameTime()+bot:GetAttackPoint()}
            bot:ActionPush_AttackUnit(hTarget, bOnce)
        else
            X[pID].actionQueue = {{[1]="AttackUnit", [2]=hTarget, [3]=bOnce}, {[1]="SleepAttack", [2]=GameTime()+bot:GetAttackPoint()}}
            X[pID].currentAction = {}
            table.insert(X[pID].actionQueue, 1, {[1]="SleepAttack", [2]=GameTime()+bot:GetAttackPoint()})
            table.insert(X[pID].actionQueue, 1, {[1]="AttackUnit", [2]=hTarget, [3]=bOnce})
        end
    end
end

function X.HeroUseAbility(bot, ability)
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)
    
    if #ca == 0 or not (ca[1] == "UseAbility" and ca[2] == ability) then
        if DEFAULT_METHOD then
            bot:Action_UseAbility(ability)
        else
            --print(pID .. " set UseAbilityOnLocation: " .. loc[1] .. ", " .. loc[2])
            X[pID].prevAction = {unpack(X[pID].currentAction)}
            X[pID].currentAction = {}
            X[pID].actionQueue = {{[1]="UseAbility", [2]=ability}}
        end
    end
end

function X.HeroUseAbilityOnLocation(bot, ability, loc, range)
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local range = range or 0
    local ca = X.GetHeroCurrentAction(pID)
    
    if #ca == 0 or not (ca[1] == "UseAbilityOnLocation" and ca[2] == ability and ca[3] == loc) then
        if DEFAULT_METHOD then
            bot:Action_UseAbilityOnLocation(ability, loc)
        else
            --print(pID .. " set UseAbilityOnLocation: " .. loc[1] .. ", " .. loc[2])
            X[pID].prevAction = {unpack(X[pID].currentAction)}
            X[pID].currentAction = {}
            X[pID].actionQueue = {{[1]="UseAbilityOnLocation", [2]=ability, [3]=loc, [4]=range}}
        end
    end
end

function X.HeroPushUseAbilityOnLocation(bot, ability, loc, range)
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local range = range or 0
    local ca = X.GetHeroCurrentAction(pID)
    
    if #ca == 0 or not (ca[1] == "UseAbilityOnLocation" and ca[2] == ability and ca[3] == loc) then
        if DEFAULT_METHOD then
            bot:ActionPush_UseAbilityOnLocation(ability, loc)
        else
            X[pID].currentAction = {}
            table.insert(X[pID].actionQueue, 1, {[1]="UseAbilityOnLocation", [2]=ability, [3]=loc, [4]=range})
        end
    end
end

function X.HeroQueueUseAbilityOnLocation(bot, ability, loc, range)
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local range = range or 0
    local ca = X.GetHeroCurrentAction(pID)
    
    if #ca == 0 or not (ca[1] == "UseAbilityOnLocation" and ca[2] == ability and ca[3] == loc) then
        if DEFAULT_METHOD then
            bot:ActionQueue_UseAbilityOnLocation(ability, loc)
        else
            table.insert(X[pID].actionQueue, {[1]="UseAbilityOnLocation", [2]=ability, [3]=loc, [4]=range})
        end
    end
end

function X.ExecuteHeroActionQueue(bot)
    return
end

return X