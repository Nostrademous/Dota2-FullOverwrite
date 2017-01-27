_G._savedEnv = getfenv()
module( "global_game_state", package.seeall )

require( GetScriptDirectory().."/buildings_status" )
local utils = require( GetScriptDirectory().."/utility" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )

-- Returns the closest building of team to a unit
function GetClosestBuilding(unit, team)
    local min_dist = 99999999
    local building = nil
    for _, id in pairs(buildings_status.GetStandingBuildingIDs(team)) do
        local vec = buildings_status.GetLocation(team, id)
        local d = GetUnitToLocationDistance(unit, vec)
        if d < min_dist then
            min_dist = d
            building = vec
        end
    end
    return id, building
end

-- Get the position between buildings (0 = sitting on teams tower, 1 = sitting on enemy's tower)
function GetPositionBetweenBuildings(unit, team)
    local _, allied_building = GetClosestBuilding(unit, team)
    local d_allied = GetUnitToLocationDistance(unit, allied_building)
    local _, enemy_building = GetClosestBuilding(unit, utils.GetOppositeTeamTo(team))
    local d_enemy = GetUnitToLocationDistance(unit, enemy_building)

    return d_allied / (d_allied + d_enemy)
end

function nearBuilding(unitLoc, building)
    return utils.GetDistance(unitLoc, building) <= 500
end

-- Detect if a tower is being pushed
function DetectEnemyPushMid()
    enemyData.UpdateEnemyInfo(1.0)
    
    local building
    local listRemainingBuildings = GetVulnerableBuildingIDs(GetTeam())
    if utils.InTable(listRemainingBuildings, TOWER_MID_1) then building = TOWER_MID_1
    elseif utils.InTable(listRemainingBuildings, TOWER_MID_2) then building = TOWER_MID_2
    elseif utils.InTable(listRemainingBuildings, TOWER_MID_3) then building = TOWER_MID_3
    elseif utils.InTable(listRemainingBuildings, BARRACKS_MID_MELEE) then building = BARRACKS_MID_MELEE
    elseif utils.InTable(listRemainingBuildings, BARRACKS_MID_RANGED) then building = BARRACKS_MID_RANGED
    elseif utils.InTable(listRemainingBuildings, TOWER_BASE_1) then building = TOWER_BASE_1
    elseif utils.InTable(listRemainingBuildings, TOWER_BASE_2) then building = TOWER_BASE_2
    else building = 0 
    end
    
    local num = 0
    for k, enemy in pairs(enemyData) do
        if type(k) == "number" and enemy.Location ~= nil then
            if building > 0 then
                if nearBuilding(enemy.Location, GetLocation(GetTeam(), building)) then
                    num = num + 1
                end
            else
                if nearBuilding(enemy.Location, GetAncient(GetTeam()):GetLocation()) then
                    num = num + 1
                end
            end
        end
    end
    
    return num >= 3
end

function DetectEnemyPushTop()
    enemyData.UpdateEnemyInfo(1.0)
    
    local building
    local listRemainingBuildings = GetVulnerableBuildingIDs(GetTeam())
    if utils.InTable(listRemainingBuildings, TOWER_TOP_1) then building = TOWER_TOP_1
    elseif utils.InTable(listRemainingBuildings, TOWER_TOP_2) then building = TOWER_TOP_2
    elseif utils.InTable(listRemainingBuildings, TOWER_TOP_3) then building = TOWER_TOP_3
    elseif utils.InTable(listRemainingBuildings, BARRACKS_TOP_MELEE) then building = BARRACKS_TOP_MELEE
    elseif utils.InTable(listRemainingBuildings, BARRACKS_TOP_RANGED) then building = BARRACKS_TOP_RANGED
    elseif utils.InTable(listRemainingBuildings, TOWER_BASE_1) then building = TOWER_BASE_1
    elseif utils.InTable(listRemainingBuildings, TOWER_BASE_2) then building = TOWER_BASE_2
    else building = 0 
    end
    
    local num = 0
    for k, enemy in pairs(enemyData) do
        if type(k) == "number" and enemy.Location ~= nil then
            if building > 0 then
                if nearBuilding(enemy.Location, GetLocation(GetTeam(), building)) then
                    num = num + 1
                end
            else
                if nearBuilding(enemy.Location, GetAncient(GetTeam()):GetLocation()) then
                    num = num + 1
                end
            end
        end
    end
    
    return num >= 3
end

function DetectEnemyPushBot()
    enemyData.UpdateEnemyInfo(1.0)
    
    local building
    local listRemainingBuildings = GetVulnerableBuildingIDs(GetTeam())
    if utils.InTable(listRemainingBuildings, TOWER_BOT_1) then building = TOWER_BOT_1
    elseif utils.InTable(listRemainingBuildings, TOWER_BOT_2) then building = TOWER_BOT_2
    elseif utils.InTable(listRemainingBuildings, TOWER_BOT_3) then building = TOWER_BOT_3
    elseif utils.InTable(listRemainingBuildings, BARRACKS_BOT_MELEE) then building = BARRACKS_BOT_MELEE
    elseif utils.InTable(listRemainingBuildings, BARRACKS_BOT_RANGED) then building = BARRACKS_BOT_RANGED
    elseif utils.InTable(listRemainingBuildings, TOWER_BASE_1) then building = TOWER_BASE_1
    elseif utils.InTable(listRemainingBuildings, TOWER_BASE_2) then building = TOWER_BASE_2
    else building = 0 
    end
    
    local num = 0
    for k, enemy in pairs(enemyData) do
        if type(k) == "number" and enemy.Location ~= nil then
            if building > 0 then
                if nearBuilding(enemy.Location, GetLocation(GetTeam(), building)) then
                    num = num + 1
                end
            else
                if nearBuilding(enemy.Location, GetAncient(GetTeam()):GetLocation()) then
                    num = num + 1
                end
            end
        end
    end
    
    return num >= 3
end

local lastPushCheck = -1000.0
function DetectEnemyPush()
    local bUpdate, newTime = utils.TimePassed(lastPushCheck, 0.5)
    if bUpdate then
        if DetectEnemyPushMid() then return LANE_MID
        elseif DetectEnemyPushTop() then return LANE_TOP
        elseif DetectEnemyPushBot() then return LANE_BOT
        end
        lastPushCheck = newTime
    end
    return nil
end
    

for k,v in pairs( global_game_state ) do _G._savedEnv[k] = v end
