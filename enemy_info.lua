-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

local EnemyInfo= {}

-- GLOBAL ENEMY INFORMATION ARRAY
local UpdateFreq1 = 0.01

function EnemyInfo.BuildEnemyList()
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
                    EnemyInfo[pid].Location = hEnemy:GetLocation()
                end
            end
        else
            -- we cannot see them at this time
            local lastSeenLoc, lastSeenTime = GetHeroLastSeenInfo(pid)
            EnemyInfo[pid].Location = lastSeenLoc
        end
    end
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

function EnemyInfo.GetEnemyHeroFromId( id )
    local enemyList = GetUnitList(UNIT_LIST_ENEMY_HEROES)

    local list = {}
    for _, enemy in pairs(enemyList) do
        if enemy:GetPlayerID() == id then
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
