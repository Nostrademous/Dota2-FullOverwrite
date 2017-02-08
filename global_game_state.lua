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
    local building = 0
    local listRemainingBuildings = buildings_status.GetStandingBuildingIDs(GetTeam())
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
    local building = 0
    local listRemainingBuildings = buildings_status.GetStandingBuildingIDs(GetTeam())
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
    local building = 0
    local listRemainingBuildings = buildings_status.GetStandingBuildingIDs(GetTeam())
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
    
    local eyeRange = 1200
    local listAllies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    for _, ally in ipairs(listAllies) do
        if ally:IsAlive() and ally:GetHealth()/ally:GetMaxHealth() > 0.4 and 
            gHero.HasID(ally:GetPlayerID()) and gHero.GetVar(ally:GetPlayerID(), "Target").Id == 0 then
            for k, enemy in pairs(enemyData) do
                -- get a valid enemyData enemy 
                if type(k) == "number" and enemy.Alive then
                    local distance = 100000
                    if enemy.Obj then
                        distance = GetUnitToUnitDistance(ally, enemy.Obj)
                    else
                        if GetHeroLastSeenInfo(k) == nil then break end
                        
                        if GetHeroLastSeenInfo(k).time <= 0.5 then
                            distance = GetUnitToLocationDistance(ally, enemy.LocExtra1)
                        elseif GetHeroLastSeenInfo(k).time <= 3.0 then
                            distance = GetUnitToLocationDistance(ally, enemy.LocExtra2)
                        else
                            break --distance = GetUnitToLocationDistance(ally, GetHeroLastSeenInfo(k).location)
                        end
                    end
                    local timeToReach = distance/ally:GetCurrentMovementSpeed()
                    
                    if distance <= eyeRange then
                        --utils.myPrint(utils.GetHeroName(ally), " sees "..enemy.Name.." ", distance, " units away. Time to reach: ", timeToReach)
                        
                        local myStun = ally:GetStunDuration(true)
                        local mySlow = ally:GetSlowDuration(true)
                        local allAllyStun = 0
                        local allAllySlow = 0
                        local myTimeToKillTarget = 0.0
                        if utils.ValidTarget(enemy) then
                            myTimeToKillTarget = fight_simul.estimateTimeToKill(ally, enemy.Obj)
                        else
                            myTimeToKillTarget = enemy.Health/(ally:GetAttackDamage()/ally:GetSecondsPerAttack())/0.75
                        end
                        
                        local totalTimeToKillTarget = myTimeToKillTarget
                        
                        local participatingAllyIDs = {}
                        local listAllies2 = GetUnitList(UNIT_LIST_ALLIED_HEROES)
                        for _, ally2 in ipairs(listAllies2) do
                            if ally2:IsAlive() and not gHero.HasID(ally2:GetPlayerID()) then
                                local distToEnemy = 100000
                                if enemy.Obj then
                                    distToEnemy = GetUnitToUnitDistance(ally2, enemy.Obj)
                                else
                                    if GetHeroLastSeenInfo(k) == nil then break end
                                    
                                    if GetHeroLastSeenInfo(k).time <= 0.5 then
                                        distToEnemy = GetUnitToLocationDistance(ally2, enemy.LocExtra1)
                                    elseif GetHeroLastSeenInfo(k).time <= 3.0 then
                                        distToEnemy = GetUnitToLocationDistance(ally2, enemy.LocExtra2)
                                    else
                                        break --distToEnemy = GetUnitToLocationDistance(ally2, GetHeroLastSeenInfo(k).location)
                                    end
                                end
                                local allyTimeToReach = distToEnemy/ally2:GetCurrentMovementSpeed()
                                
                                if distToEnemy <= 2*eyeRange then
                                    --utils.myPrint("ally ", utils.GetHeroName(ally2), " is ", distToEnemy, " units away. Time to reach: ", allyTimeToReach)
                                    totalTimeToKillTarget = totalTimeToKillTarget + 8.0
                                    table.insert(participatingAllyIDs, ally2:GetPlayerID())
                                end
                                
                            elseif ally2:IsAlive() and ally2:GetPlayerID() ~= ally:GetPlayerID() and gHero.GetVar(ally2:GetPlayerID(), "Target").Id == 0 
                                and (gHero.GetVar(ally2:GetPlayerID(), "GankTarget").Id == 0 or gHero.GetVar(ally2:GetPlayerID(), "GankTarget").Id == k) then
                                local distToEnemy = 100000
                                if enemy.Obj then
                                    distToEnemy = GetUnitToUnitDistance(ally2, enemy.Obj)
                                else
                                    if GetHeroLastSeenInfo(k).time <= 0.5 then
                                        distToEnemy = GetUnitToLocationDistance(ally2, enemy.LocExtra1)
                                    elseif GetHeroLastSeenInfo(k).time <= 3.0 then
                                        distToEnemy = GetUnitToLocationDistance(ally2, enemy.LocExtra2)
                                    else
                                        distToEnemy = GetUnitToLocationDistance(ally2, GetHeroLastSeenInfo(k).location)
                                    end
                                end
                                local allyTimeToReach = distToEnemy/ally2:GetCurrentMovementSpeed()
                                
                                if distToEnemy <= 2*eyeRange then
                                    --utils.myPrint("ally ", utils.GetHeroName(ally2), " is ", distToEnemy, " units away. Time to reach: ", allyTimeToReach)
                                    
                                    allAllyStun = allAllyStun + ally2:GetStunDuration(true)
                                    allAllySlow = allAllySlow + ally2:GetSlowDuration(true)
                                    local allyTimeToKillTarget = 0.0
                                    if utils.ValidTarget(enemy) then
                                        allyTimeToKillTarget = fight_simul.estimateTimeToKill(ally2, enemy.Obj)
                                    else
                                        allyTimeToKillTarget = enemy.Health /(ally2:GetAttackDamage()/ally2:GetSecondsPerAttack())/0.75
                                    end
                                    totalTimeToKillTarget = totalTimeToKillTarget + allyTimeToKillTarget
                                    table.insert(participatingAllyIDs, ally2:GetPlayerID())
                                end
                            end
                        end
                        
                        local numAttackers = #participatingAllyIDs+1
                        local anticipatedTimeToKill = totalTimeToKillTarget/numAttackers
                        local totalStun = myStun + allAllyStun
                        local totalSlow = mySlow + allAllySlow
                        local timeToKillBonus = numAttackers*(totalStun + 0.5*totalSlow)
                        
                        if utils.ValidTarget(enemy) and (anticipatedTimeToKill - timeToKillBonus) < 6.0 then
                            utils.myPrint(#participatingAllyIDs+1, " of us can Stun for: ", totalStun, " and Slow for: ", totalSlow, ". AnticipatedTimeToKill ", enemy.Name ,": ", anticipatedTimeToKill)
                            utils.myPrint(utils.GetHeroName(ally), " - Engaging! Anticipated Time to kill: ", anticipatedTimeToKill)
                            gHero.SetVar(ally:GetPlayerID(), "Target", {Obj=enemy.Obj, Id=k})
                            gHero.GetVar(ally:GetPlayerID(), "Self"):AddAction(constants.ACTION_FIGHT)
                            for _, v in pairs(participatingAllyIDs) do
                                if gHero.GetVar(v, "GankTarget").Id == 0 then
                                    gHero.SetVar(v, "Target", {Obj=enemy.Obj, Id=k})
                                    gHero.GetVar(v, "Self"):AddAction(constants.ACTION_FIGHT)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

for k,v in pairs( global_game_state ) do _G._savedEnv[k] = v end
