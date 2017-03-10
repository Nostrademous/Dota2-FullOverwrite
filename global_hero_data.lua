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
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)
    
    if checkSleepAttack(bot, ca) then return end
    
    if (#ca == 0 or not (ca[1] == "MoveToLocation" and ca[2] == loc)) and GetUnitToLocationDistance(bot, loc) > 10.0 then
        if DEFAULT_METHOD then
            bot:Action_MoveToLocation(loc)
        else
            --print(pID .. " set MoveToLocation: " .. loc[1] .. ", " .. loc[2])
            X[pID].prevAction = {unpack(X[pID].currentAction)}
            X[pID].currentAction = {}
            X[pID].actionQueue = {{[1]="MoveToLocation", [2]=loc}}
        end
    end
end

function X.HeroPushMoveToLocation(bot, loc)
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local ca = X.GetHeroCurrentAction(pID)
    
    if checkSleepAttack(bot, ca) then return end
    
    if (#ca == 0 or not (ca[1] == "MoveToLocation" and ca[2] == loc)) and GetUnitToLocationDistance(bot, loc) > 10.0 then
        if DEFAULT_METHOD then
            bot:ActionPush_MoveToLocation(loc)
        else
            X[pID].currentAction = {}
            table.insert(X[pID].actionQueue, 1, {[1]="MoveToLocation", [2]=loc})
        end
    end
end

function X.HeroQueueMoveToLocation(bot, loc)
    if bDisableActions then return end
    
    local pID = bot:GetPlayerID()
    local aqSize = X.GetHeroActionQueueSize(pID)
    local la = {}
    if aqSize > 0 then la = X[pID].actionQueue[aqSize] end
    
    if #la == 0 or not (la[1] == "MoveToLocation" and la[2] == loc) then
        if DEFAULT_METHOD then
            bot:ActionQueue_MoveToLocation(loc)
        else
            table.insert(X[pID].actionQueue, {[1]="MoveToLocation", [2]=loc})
        end
    end
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
    if DEFAULT_METHOD then return end
    
    local pID = bot:GetPlayerID()
    
    if not bot:IsAlive() then
        X[pID].currentAction = {}
        X[pID].actionQueue = {}
        return
    end

    local ca = X.GetHeroCurrentAction(pID)
    
    if #ca == 0 then
        if X.GetHeroActionQueueSize(pID) == 0 then
            bDisableActions = false 
            return
        end

        ca = X.GetHeroActionQueue(pID)[1]
        X.SetHeroCurrentAction(pID, ca)
        table.remove(X[pID].actionQueue, 1)

        if ca[1] == "MoveToLocation" then
            bot:Action_MoveToLocation(ca[2])   
        elseif ca[1] == "UseAbility" then
            bot:Action_UseAbility(ca[2])
        elseif ca[1] == "UseAbilityOnLocation" then
            bot:Action_UseAbilityOnLocation(ca[2], ca[3])
        elseif ca[1] == "AttackUnit" then
            bot:Action_AttackUnit(ca[2], ca[3])
        end
    end
    
    if #ca > 1 then
        if ca[1] == "MoveToLocation" then
            if GetUnitToLocationDistance(bot, ca[2]) <= 10.0 then
                X.SetHeroPrevAction(pID, ca)
                X[pID].currentAction = {}
            end
        elseif ca[1] == "UseAbility" then
            X.SetHeroPrevAction(pID, ca)
            X[pID].currentAction = {}
        elseif ca[1] == "UseAbilityOnLocation" then
            if ca[4] > 0 and GetUnitToLocationDistance(bot, ca[3]) < ca[4] then
                X.SetHeroPrevAction(pID, ca)
                X[pID].currentAction = {}
            end
        elseif ca[1] == "AttackUnit" then
            if not ca[2]:IsNull() and ca[2]:IsAlive() then
                if ca[3] and GetUnitToUnitDistance(bot, ca[2]) < bot:GetAttackRange() then
                    X.SetHeroPrevAction(pID, ca)
                    X[pID].currentAction = {[1]="Sleep", [2]=GameTime()+bot:GetAttackPoint()}
                end
            else
                X.SetHeroPrevAction(pID, ca)
                X[pID].currentAction = {}
            end
        end
    end
    
    --bDisableActions = X.GetHeroActionQueueSize(pID) > 0
end

return X