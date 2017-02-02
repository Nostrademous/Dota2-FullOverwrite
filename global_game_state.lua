_G._savedEnv = getfenv()
module( "global_game_state", package.seeall )

require( GetScriptDirectory().."/buildings_status" )
local gHero = require( GetScriptDirectory().."/global_hero_data" )
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
    
    return num, building
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
    
    return num, building
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
    
    return num, building
end

local lastPushCheck = -1000.0
function DetectEnemyPush()
    local bUpdate, newTime = utils.TimePassed(lastPushCheck, 0.5)
    if bUpdate then
        local numMid, midBuilding = DetectEnemyPushMid()
        local numTop, topBuilding = DetectEnemyPushTop()
        local numBot, botBuildign = DetectEnemyPushBot()
        if numMid >= 3 then return LANE_MID, midBuilding, numMid
        elseif numTop >= 3 then return LANE_TOP, topBuilding, numTop
        elseif numBot >= 3 then return LANE_BOT, botBuilding, numBot
        end
        lastPushCheck = newTime
    end
    return nil, nil, nil
end

local lastBuildingUpdate = -1000.0
local vulnEnemyBuildings = nil
function GetLatestVulnerableEnemyBuildings()
    local bUpdate, newTime = utils.TimePassed(lastBuildingUpdate, 3.0)
    if bUpdate then
        vulnEnemyBuildings = buildings_status.GetDestroyableTowers(utils.GetOtherTeam())
        lastBuildingUpdate = newTime
    end
    return vulnEnemyBuildings
end

local lastGlobalFightDetermination = -1000.0
function GlobalFightDetermination()
    local bUpdate, newTime = utils.TimePassed(lastGlobalFightDetermination, 0.25)
    if bUpdate then lastGlobalFightDetermination = newTime else return end
    
    enemyData.UpdateEnemyInfo(1.0)
    
    local eyeRange = 1200
    local listAllies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    for _, ally in ipairs(listAllies) do
        if ally:IsAlive() and gHero.HasID(ally:GetPlayerID()) and gHero.GetVar(ally:GetPlayerID(), "Target").Obj == nil then
            for k, enemy in ipairs(enemyData) do
                -- get a valid enemyData enemy 
                if type(k) == "number" and enemy.Health > 0 then
                    local distance = GetUnitToLocationDistance(ally, enemy.Location)
                    local timeToReach = distance/ally:GetCurrentMovementSpeed()
                    
                    if distance <= eyeRange then
                        utils.myPrint("sees ", enemy.Name, " ", distance, " units away. Time to reach: ", timeToReach)
                        
                        local myStun = ally:GetStunDuration(true)
                        local mySlow = ally:GetSlowDuration(true)
                        local myTimeToKillTarget = 0.0
                        if utils.ValidTarget(enemy) then
                            myTimeToKillTarget = fight_simul.estimateTimeToKill(ally, enemy)
                        else
                            myTimeToKillTarget = enemy.Health /(ally:GetAttackDamage()/ally:GetSecondsPerAttack())/0.75
                        end
                        
                        local totalTimeToKillTarget = myTimeToKillTarget
                        
                        local participatingAllyIDs = {}
                        local listAllies2 = GetUnitList(UNIT_LIST_ALLIED_HEROES)
                        for _, ally2 in ipairs(listAllies2) do
                            if ally2:IsAlive() and not gHero.HasID(ally2:GetPlayerID()) then
                                local distToEnemy = GetUnitToLocationDistance(ally2, enemy.Location)
                                local allyTimeToReach = distToEnemy/ally2:GetCurrentMovementSpeed()
                                
                                if distToEnemy <= 2*eyeRange then
                                    utils.myPrint("ally ", utils.GetHeroName(ally2), " is ", distToEnemy, " units away. Time to reach: ", allyTimeToReach)
                                    totalTimeToKillTarget = totalTimeToKillTarget + 8.0
                                    table.insert(participatingAllyIDs, ally2:GetPlayerID())
                                end
                                
                            elseif ally2:IsAlive() and ally2:GetPlayerID() ~= ally:GetPlayerID() and gHero.GetVar(ally2:GetPlayerID(), "Target").Obj == nil then
                                --local distToMe = GetUnitToUnitDistance(ally2, ally)
                                local distToEnemy = GetUnitToLocationDistance(ally2, enemy.Location)
                                local allyTimeToReach = distToEnemy/ally2:GetCurrentMovementSpeed()
                                
                                if distToEnemy <= 2*eyeRange then
                                    utils.myPrint("ally ", utils.GetHeroName(ally2), " is ", distToEnemy, " units away. Time to reach: ", allyTimeToReach)
                                    
                                    local allyStun = ally2:GetStunDuration()
                                    local allySlow = ally2:GetSlowDuration()
                                    local allyTimeToKillTarget = 0.0
                                    if utils.ValidTarget(enemy) then
                                        allyTimeToKillTarget = fight_simul.estimateTimeToKill(ally2, enemy)
                                    else
                                        allyTimeToKillTarget = enemy.Health /(ally2:GetAttackDamage()/ally2:GetSecondsPerAttack())/0.75
                                    end
                                    totalTimeToKillTarget = totalTimeToKillTarget + allyTimeToKillTarget
                                    table.insert(participatingAllyIDs, ally2:GetPlayerID())
                                end
                            end
                        end
                        
                        local anticipatedTimeToKill = totalTimeToKillTarget/(#participatingAllyIDs+1)
                        if utils.ValidTarget(enemy) and anticipatedTimeToKill < 6.0 then
                            utils.myPrint("Engaging! Anticipated Time to kill: ", anticipatedTimeToKill)
                            gHero.SetVar(ally:GetPlayerID(), "Target", {Obj=enemy.Obj, Id=enemy.Obj:GetPlayerID()})
                            for _, v in ipairs(participatingAllyIDs) do
                                gHero.SetVar(v:GetPlayerID(), "Target", {Obj=enemy.Obj, Id=enemy.Obj:GetPlayerID()})
                            end
                        end
                    end
                end
            end
        end
    end
end

for k,v in pairs( global_game_state ) do _G._savedEnv[k] = v end
