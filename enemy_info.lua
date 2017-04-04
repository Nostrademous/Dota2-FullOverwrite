-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

local EnemyInfo = {}

-- GLOBAL ENEMY INFORMATION ARRAY
local LastEnemyUpdate = -1000.0
local UpdateFreq1 = 0.25
local UpdateFreq2 = 1.00

function EnemyInfo.BuildEnemyList()
    if GameTime() - LastEnemyUpdate > UpdateFreq1 then
        local listEnemyIDs = GetTeamPlayers(utils.GetOtherTeam())

        for slot_id, pid in ipairs(listEnemyIDs) do
            -- initialize if we have not seen this enemy before
            if EnemyInfo[pid] == nil then
                EnemyInfo[pid] = {}

                -- Let's try to figure out their role
                EnemyInfo.InferRole(pid)
            end

            --------------------------------------------
            -- update our understanding of this enemy --
            --------------------------------------------

            -- are they alive
            EnemyInfo[pid].Alive = IsHeroAlive(pid)

            -- can we see them now
            local hEnemy = EnemyInfo.GetEnemyHeroFromId(pid)
            if hEnemy then
                -- yes we can see them (at least some of them if multiple)
                if EnemyInfo[pid].multiple then
                    for _, hEnemyCopy in pairs(hEnemy) do
                        -- TODO: Figure out how to handle
                    end
                else
                    if not hEnemy:IsNull() then
                        EnemyInfo[pid].Name = utils.GetHeroName(hEnemy)
                        EnemyInfo[pid].Level = hEnemy:GetLevel()
                        
                        EnemyInfo[pid].Location = hEnemy:GetLocation()
                        EnemyInfo[pid].LastSeen = GameTime()
                        EnemyInfo[pid].Lane = utils.NearestLane(hEnemy)
                        EnemyInfo[pid].ExtraLoc1 = hEnemy:GetExtrapolatedLocation(1.0)
                        EnemyInfo[pid].ExtraLoc3 = hEnemy:GetExtrapolatedLocation(3.0)
                        EnemyInfo[pid].ExtraLoc5 = hEnemy:GetExtrapolatedLocation(5.0)
                    end
                end
                
                if hEnemy:IsUnableToMiss() then
                    EnemyInfo[pid].HasTruestrike = true
                    EnemyInfo.HasTruestrike = true
                else
                    EnemyInfo[pid].HasTruestrike = false
                end
                
                if GameTime() - LastEnemyUpdate > UpdateFreq2 then
                    for i = 0, 5, 1 do
                        local item = hEnemy:GetItemInSlot(i)
                        if item ~= nil then
                            local sItemName = item:GetName()
                            EnemyInfo[pid].Items[i] = sItemName
                            
                            if sItemName == "item_gem" or sItemName == "item_ward_dispenser" or 
                                sItemName == "item_ward_sentry" or sItemName == "item_dust" or 
                                sItemName == "item_necronomicon_3" then
                                EnemyInfo[pid].HasDetection = true
                            else
                                EnemyInfo[pid].HasDetection = false
                            end
                        end
                    end
                end
            else
                -- we cannot see them at this time
                local lastSeenLoc, lastSeenTime = GetHeroLastSeenInfo(pid)
                if lastSeenTime then
                    EnemyInfo[pid].Location = lastSeenLoc
                    EnemyInfo[pid].LastSeen = lastSeenTime
                    
                    if lastSeenTime > 6.0 then
                        EnemyInfo[pid].Lane = -1
                        EnemyInfo[pid].ExtraLoc1 = nil
                        EnemyInfo[pid].ExtraLoc3 = nil
                        EnemyInfo[pid].ExtraLoc5 = nil
                    end
                end
            end
        end
        
        LastEnemyUpdate = GameTime()
    end
end

function EnemyInfo.GetLocation( id )
    if EnemyInfo[id] then
        return EnemyInfo[id].Location
    end
    
    local tDelta = GameTime() - EnemyInfo[id].LastSeen
    if tDelta <= 1.0 then
        return EnemyInfo[id].ExtraLoc1
    elseif tDelta <= 3.0 then
        return EnemyInfo[id].ExtraLoc3
    elseif tDelta <= 5.0 then
        return EnemyInfo[id].ExtraLoc5
    end
    
    return nil
end

function EnemyInfo.InferRole( id )
    local hEnemy = EnemyInfo.GetEnemyHeroFromId(id)
    if hEnemy then
        if EnemyInfo[id].multiple then
            hEnemy = hEnemy[1]
        end

        if not hEnemy:IsNull() then
        -- TODO: Implement
        end
    end
end

function EnemyInfo.PrintEnemyInfo()
    local pids = GetTeamPlayers(utils.GetOtherTeam())
    for _, pid in pairs(pids) do
        if EnemyInfo[pid].Name then
            print(EnemyInfo[pid].Name .. " (Lvl: " .. EnemyInfo[pid].Level .. ")")
            print("    Lane: " .. EnemyInfo[pid].Lane)
        end
    end
end

function EnemyInfo.GetEnemyHeroFromId( id )
    local enemyList = GetUnitList(UNIT_LIST_ENEMY_HEROES)

    local list = {}
    for _, enemy in pairs(enemyList) do
        if not enemy:IsNull() and enemy:GetPlayerID() == id then
            if not EnemyInfo[id].Alive then
                enemy.Illusion = true
            end

            table.insert(list, enemy)
        end
    end

    EnemyInfo[id].multiple = false
    if #list > 0 then
        if #list > 1 then
            EnemyInfo[id].multiple = true
            return list
        end
        return list[1]
    end

    return nil
end

return EnemyInfo
