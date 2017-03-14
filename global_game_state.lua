_G._savedEnv = getfenv()
module( "global_game_state", package.seeall )

require( GetScriptDirectory().."/buildings_status" )
require( GetScriptDirectory().."/debugging" )
local gHero = require( GetScriptDirectory().."/global_hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )

local laneStates = {[LANE_TOP] = {dontdefend = false},
                    [LANE_MID] = {dontdefend = false},
                    [LANE_BOT] = {dontdefend = false}}

-- TODO: used for reading and writing. not really good.
function LaneState(lane)
    return laneStates[lane]
end

function EvaluateGameState()
    -- TODO: rate limiting
    local team = GetTeam()
    local topA = EvaluateLaneState(team, LANE_TOP)
    local midA = EvaluateLaneState(team, LANE_MID)
    local botA = EvaluateLaneState(team, LANE_BOT)
end

-- calculate some metrices on the given lane
function EvaluateLaneState(team, lane)
    enemy_team = utils.GetOtherTeam()
    -- consider defence
    local ttr_attackers, enemies = TimeToReachBuilding(team, enemy_team, lane)
    local ttr_defenders, allies = TimeToReachBuilding(team, team, lane)
    local backdoor = TimeUntilBackdoorIsDown(team, lane)
    local dps = ExpectedDpsOnBuilding(enemy_team, lane, enemies)

    debugging.SetTeamState("Push/Defend", lane * 2 - 1, string.format("Defence: TTRD %.1f TTRA %.1f backdoor %.1f dps %d %dv%d", ttr_defenders, ttr_attackers, backdoor, dps, #allies, #enemies))

    ttr_attackers, allies = TimeToReachBuilding(enemy_team, team, lane)
    ttr_defenders, enemies = TimeToReachBuilding(enemy_team, enemy_team, lane)
    backdoor = TimeUntilBackdoorIsDown(enemy_team, lane)
    dps = ExpectedDpsOnBuilding(team, lane, allies)

    debugging.SetTeamState("Push/Defend", lane * 2, string.format("Push: TTRD %.1f TTRA %.1f backdoor %.1f dps %d %dv%d", ttr_defenders, ttr_attackers, backdoor, dps, #allies, #enemies))
end

local MAX_DISTANCE = 3000

-- When will the heroes reach the tower? (for now: consider all heroes close to the tower)
function TimeToReachBuilding(tower_team, heroes_team, lane)
    local tower = buildings_status.GetVulnerableBuildingIDs(tower_team, lane)
    if #tower == 0 then return 99999, {} end
    tower = tower[1]
    local hTower = buildings_status.GetHandle(tower_team, tower)
    local heroes = {}
    local slowest = 0

    if heroes_team == GetTeam() then -- our team, we know everything
        local allies = GetUnitList(UNIT_LIST_ALLIED_HEROES) -- TODO: illusions?
        for i, ally in pairs(allies) do
            local dist = GetUnitToUnitDistance(ally, hTower)
            if dist < MAX_DISTANCE then -- TODO: use some better geometry
                table.insert(heroes, ally)
                local time = dist / ally:GetCurrentMovementSpeed()
                if time > slowest then slowest = time end
            end
        end
    else -- enemy team, might have to use estimated values
        for k, enemy in pairs(enemyData) do
            if type(k) == "number" and enemy.Alive then
                local dist = 100000
                if enemy.Obj then
                    dist = GetUnitToUnitDistance(hTower, enemy.Obj)
                else
                    if GetHeroLastSeenInfo(k).time <= 0.5 then
                        dist = GetUnitToLocationDistance(hTower, enemy.LocExtra1)
                    elseif GetHeroLastSeenInfo(k).time <= 3.0 then
                        dist = GetUnitToLocationDistance(hTower, enemy.LocExtra2)
                    else
                        dist = GetUnitToLocationDistance(hTower, GetHeroLastSeenInfo(k).location)
                    end
                end
                if dist < MAX_DISTANCE then -- TODO: use some better geometry
                    table.insert(heroes, enemy)
                    local time = dist / enemy.MoveSpeed
                    if time > slowest then slowest = time end
                end
            end
        end
    end

    return slowest, heroes
end

-- When will there be creeps, if they move with their max speed? (0 for T1)
function TimeUntilBackdoorIsDown(tower_team, lane)
    local tower = buildings_status.GetVulnerableBuildingIDs(tower_team, lane)
    if #tower == 0 then return 99999 end
    tower = tower[1]
    local apiid = buildings_status.GetApiID(tower_team, tower)
    if buildings_status.GetType(tower_team, tower) == buildings_status.TYPE_TOWER and (apiid == TOWER_TOP_1 or apiid == TOWER_MID_1 or apiid == TOWER_BOT_1) then
        return 0
    end

    local hTower = buildings_status.GetHandle(tower_team, tower)

    local lane_fron

    if tower_team == GetTeam() then
         lane_front = GetLaneFrontLocation( tower_team, lane, 0 )
         return GetUnitToLocationDistance(hTower, lane_front) / 325
    else
        lane_front = GetLaneFrontLocation( tower_team, lane, 0 ) -- TODO: is this an estimation? if yes, can we do better?
        return GetUnitToLocationDistance(hTower, lane_front) / 325
    end
end

-- Considered that all nearby enemy heroes auto hit the tower, calculate their dps
function ExpectedDpsOnBuilding(team, lane, heroes)
    dps = 0

    local tower = buildings_status.GetVulnerableBuildingIDs(team, lane)
    if #tower == 0 then return 99999 end
    tower = tower[1]
    local hTower = buildings_status.GetHandle(team, tower)
    local armor = hTower:GetArmor()
    local dmg_factor = 0.5 * (1 - 0.06 * armor / (1 + (0.06 * math.abs(armor))))

    if team == GetTeam() then -- our team
        for i, hero in pairs(heroes) do
            dps = dps + dmg_factor * hero:GetAttackDamage() / hero:GetSecondsPerAttack()
        end
    else -- enemy team, use estimations
        for i, hero in pairs(heroes) do
            dps = dps + dmg_factor * hero.AttackDamage / hero.SecondsPerAttack -- TODO: results are far to high; armor is reported as -1 !!
        end
    end
    return dps
end


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
    return utils.GetDistance(unitLoc, building) <= 1000
end

function numEnemiesNearBuilding(building)
    local num = 0
    for k, enemy in pairs(enemyData) do
        if type(k) == "number" then
            if enemy.Alive then
                local eLoc = enemy.LocExtra1
                if utils.ValidTarget(enemy.Obj) then
                    eLoc = enemy.Obj:GetLocation()
                end

                if eLoc == nil then return 0 end

                if building > 0 then
                    if nearBuilding(eLoc, buildings_status.GetLocation(GetTeam(), building)) then
                        num = num + 1
                    end
                else
                    if nearBuilding(eLoc, GetAncient(GetTeam()):GetLocation()) then
                        num = num + 1
                    end
                end
            end
        end
    end
    return num
end

-- Detect if a tower is being pushed
function DetectEnemyPushMid()
    local building = buildings_status.GetVulnerableBuildingIDs(GetTeam(), LANE_MID)[1]

    local hBuilding = buildings_status.GetHandle(GetTeam(), building)

    if hBuilding == nil then return 0, building end

    debugging.SetTeamState("Getting Pushed", 5, "mid: "..hBuilding:GetUnitName().." "..hBuilding:TimeSinceDamagedByAnyHero().." "..numEnemiesNearBuilding(building))
    debugging.SetCircle("mid_tower", hBuilding:GetLocation(), 0, 255, 0)

    if hBuilding and hBuilding:TimeSinceDamagedByAnyHero() < 1.5 then
        local num = numEnemiesNearBuilding(building)
        return num, building
    end
    return 0, building
end

function DetectEnemyPushTop()
    local building = buildings_status.GetVulnerableBuildingIDs(GetTeam(), LANE_TOP)[1]

    local hBuilding = buildings_status.GetHandle(GetTeam(), building)

    if hBuilding == nil then return 0, building end

    debugging.SetTeamState("Getting Pushed", 4, "top: "..hBuilding:GetUnitName().." "..hBuilding:TimeSinceDamagedByAnyHero().." "..numEnemiesNearBuilding(building))
    debugging.SetCircle("top_tower", hBuilding:GetLocation(), 0, 255, 0)

    if hBuilding and hBuilding:TimeSinceDamagedByAnyHero() < 1.5 then
        local num = numEnemiesNearBuilding(building)
        return num, building
    end
    return 0, building
end

function DetectEnemyPushBot()
    local building = buildings_status.GetVulnerableBuildingIDs(GetTeam(), LANE_BOT)[1]

    local hBuilding = buildings_status.GetHandle(GetTeam(), building)

    if hBuilding == nil then return 0, building end

    debugging.SetTeamState("Getting Pushed", 6, "bot: "..hBuilding:GetUnitName().." "..hBuilding:TimeSinceDamagedByAnyHero().." "..numEnemiesNearBuilding(building))
    debugging.SetCircle("bot_tower", hBuilding:GetLocation(), 0, 255, 0)

    if hBuilding and hBuilding:TimeSinceDamagedByAnyHero() < 1.5 then
        local num = numEnemiesNearBuilding(building)
        return num, building
    end
    return 0, building
end

local lastPushCheck = -1000.0
function DetectEnemyPush()
    local bUpdate, newTime = utils.TimePassed(lastPushCheck, 0.5)
    if bUpdate then
        local numMid, midBuilding = DetectEnemyPushMid()
        local numTop, topBuilding = DetectEnemyPushTop()
        local numBot, botBuilding = DetectEnemyPushBot()
        if numMid > 0 then
            debugging.SetTeamState("Getting Pushed", 1, "MID")
            return LANE_MID, midBuilding, numMid
        elseif numTop > 0 then
            debugging.SetTeamState("Getting Pushed", 1, "TOP")
            return LANE_TOP, topBuilding, numTop
        elseif numBot > 0 then
            debugging.SetTeamState("Getting Pushed", 1, "BOT")
            return LANE_BOT, botBuilding, numBot
        end
        lastPushCheck = newTime
    end
    debugging.SetTeamState("Getting Pushed", 1, "no incoming pushes")
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
    for _, ally in pairs(listAllies) do
        if ally:IsAlive() and ally:IsBot() and ally:GetHealth()/ally:GetMaxHealth() > 0.4 and not ally:IsIllusion()
            and gHero.HasID(ally:GetPlayerID()) and gHero.GetVar(ally:GetPlayerID(), "Target").Id == 0 then

            local totalNukeDmg = 0

            local numEnemiesThatCanAttackMe = 0
            local numAlliesThatCanHelpMe = 0

            for k, enemy in pairs(enemyData) do
                -- get a valid enemyData enemy
                if type(k) == "number" and enemy.Alive then
                    local distance = 100000
                    if enemy.Obj then
                        distance = GetUnitToUnitDistance(ally, enemy.Obj)
                    else
                        if GetHeroLastSeenInfo(k).time == -1 then break end

                        if GetHeroLastSeenInfo(k).time <= 0.5 then
                            distance = GetUnitToLocationDistance(ally, enemy.LocExtra1)
                        elseif GetHeroLastSeenInfo(k).time <= 3.0 then
                            distance = GetUnitToLocationDistance(ally, enemy.LocExtra2)
                        else
                            break --distance = GetUnitToLocationDistance(ally, GetHeroLastSeenInfo(k).location)
                        end
                    end

                    local theirTimeToReachMe = distance/enemy.MoveSpeed

                    local timeToReach = distance/ally:GetCurrentMovementSpeed()
                    local myNukeDmg, myActionQueue, myCastTime, myStun, mySlow, myEngageDist = gHero.GetVar(ally:GetPlayerID(), "Self"):GetNukeDamage( ally, enemy.Obj )

                    -- update our total nuke damage
                    totalNukeDmg = totalNukeDmg + myNukeDmg

                    if distance <= eyeRange then
                        numEnemiesThatCanAttackMe = numEnemiesThatCanAttackMe + 1
                        --utils.myPrint(utils.GetHeroName(ally), " sees "..enemy.Name.." ", distance, " units away. Time to reach: ", timeToReach)

                        local allAllyStun = 0
                        local allAllySlow = 0
                        local myTimeToKillTarget = 0.0
                        if utils.ValidTarget(enemy) then
                            myTimeToKillTarget = fight_simul.estimateTimeToKill(ally, enemy.Obj)
                        else
                            myTimeToKillTarget = enemy.Health/(ally:GetAttackDamage()/ally:GetSecondsPerAttack())/0.75
                        end

                        local totalTimeToKillTarget = myTimeToKillTarget

                        local participatingAllies = {}
                        local globalAllies = {}

                        for _, ally2 in pairs(listAllies) do
                            -- this 'if' is for non-implemented bot heroes that are on our team
                            if ally2:IsAlive() and ally2:IsBot() and not ally2:IsIllusion() and not gHero.HasID(ally2:GetPlayerID()) then
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

                                local globalAbility = gHero.GetVar(ally2:GetPlayerID(), "HasGlobal")

                                if distToEnemy <= 2*eyeRange then
                                    --utils.myPrint("ally ", utils.GetHeroName(ally2), " is ", distToEnemy, " units away. Time to reach: ", allyTimeToReach)
                                    totalTimeToKillTarget = totalTimeToKillTarget + 8.0
                                    table.insert(participatingAllies, {ally2, {}, 500})
                                elseif globalAbility and globalAbility[1]:IsFullyCastable() then
                                    table.insert(globalAllies, {ally2, globalAbility})
                                end
                            -- this 'elseif' is for implemented bot heroes on our team
                            elseif ally2:IsAlive() and not ally2:IsIllusion() and ally2:GetPlayerID() ~= ally:GetPlayerID() and gHero.GetVar(ally2:GetPlayerID(), "Target").Id == 0
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
                                        --distToEnemy = GetUnitToLocationDistance(ally2, GetHeroLastSeenInfo(k).location)
                                        break
                                    end
                                end

                                if GetUnitToUnitDistance(ally, ally2) < eyeRange then
                                    numAlliesThatCanHelpMe = numAlliesThatCanHelpMe + 1
                                end

                                local allyTimeToReach = distToEnemy/ally2:GetCurrentMovementSpeed()
                                local allyNukeDmg, allyActionQueue, allyCastTime, allyStun, allySlow, allyEngageDist = gHero.GetVar(ally2:GetPlayerID(), "Self"):GetNukeDamage( ally2, enemy.Obj )

                                -- update our total nuke damage
                                totalNukeDmg = totalNukeDmg + allyNukeDmg

                                local globalAbility = gHero.GetVar(ally2:GetPlayerID(), "HasGlobal")
                                if allyTimeToReach <= 6.0 then
                                    --utils.myPrint("ally ", utils.GetHeroName(ally2), " is ", distToEnemy, " units away. Time to reach: ", allyTimeToReach)

                                    allAllyStun = allAllyStun + allyStun
                                    allAllySlow = allAllySlow + allySlow
                                    local allyTimeToKillTarget = 0.0
                                    if utils.ValidTarget(enemy) then
                                        allyTimeToKillTarget = fight_simul.estimateTimeToKill(ally2, enemy.Obj)
                                    else
                                        allyTimeToKillTarget = enemy.Health /(ally2:GetAttackDamage()/ally2:GetSecondsPerAttack())/0.75
                                    end
                                    totalTimeToKillTarget = totalTimeToKillTarget + allyTimeToKillTarget
                                    table.insert(participatingAllies, {ally2, allyActionQueue, allyEngageDist})
                                elseif globalAbility and globalAbility[1]:IsFullyCastable() then
                                    table.insert(globalAllies, {ally2, globalAbility})
                                end
                            end
                        end

                        local numAttackers = #participatingAllies+1
                        local anticipatedTimeToKill = (totalTimeToKillTarget/numAttackers) - 2*#globalAllies
                        local totalStun = myStun + allAllyStun
                        local totalSlow = mySlow + allAllySlow
                        local timeToKillBonus = numAttackers*(totalStun + 0.5*totalSlow)

                        if utils.ValidTarget(enemy) then
                            -- if global we picked a 1v? fight then let it work out at the hero-level
                            if numAttackers == 1 then break end

                            if totalNukeDmg/#gHeroVar.GetNearbyEnemies(ally, 1200) >= enemy.Obj:GetHealth() then
                                utils.myPrint(#participatingAllies+1, " of us can Nuke ", enemy.Name)
                                utils.myPrint(utils.GetHeroName(ally), " - Engaging!")

                                local allyID = ally:GetPlayerID()
                                gHero.SetVar(allyID, "Target", {Obj=enemy.Obj, Id=k})
                                gHero.GetVar(allyID, "Self"):AddMode(constants.MODE_FIGHT)
                                gHero.GetVar(allyID, "Self"):QueueNuke(ally, enemy.Obj, myActionQueue, myEngageDist)

                                for _, v in pairs(participatingAllies) do
                                    if gHero.GetVar(v[1]:GetPlayerID(), "GankTarget").Id == 0 then
                                        gHero.SetVar(v[1]:GetPlayerID(), "Target", {Obj=enemy.Obj, Id=k})
                                        gHero.GetVar(v[1]:GetPlayerID(), "Self"):AddMode(constants.MODE_FIGHT)
                                        if #v[2] > 0 and GetUnitToUnitDistance(v[1], enemy.Obj) < v[3] then
                                            gHero.GetVar(v[1]:GetPlayerID(), "Self"):QueueNuke(v[1], enemy.Obj, v[2], v[3])
                                        elseif #v[2] > 0 then
                                            gHero.HeroAttackUnit(v[1], enemy.Obj, true)
                                        end
                                    end
                                end

                                for _, v in pairs(globalAllies) do
                                    gHero.SetVar(v[1]:GetPlayerID(), "UseGlobal", {v[2][1], enemy.Obj})
                                    utils.myPrint(utils.GetHeroName(v[1]).." casting global skill.")
                                end

                                return
                            elseif (anticipatedTimeToKill - timeToKillBonus) < 6.0/#gHeroVar.GetNearbyEnemies(ally, 1200) then
                                utils.myPrint(#participatingAllies+#globalAllies+1, " of us can Stun for: ", totalStun, " and Slow for: ", totalSlow, ". AnticipatedTimeToKill ", enemy.Name ,": ", anticipatedTimeToKill)
                                utils.myPrint(utils.GetHeroName(ally), " - Engaging! Anticipated Time to kill: ", anticipatedTimeToKill)
                                gHero.SetVar(ally:GetPlayerID(), "Target", {Obj=enemy.Obj, Id=k})
                                gHero.GetVar(ally:GetPlayerID(), "Self"):AddMode(constants.MODE_FIGHT)
                                for _, v in pairs(participatingAllies) do
                                    if gHero.GetVar(v[1]:GetPlayerID(), "GankTarget").Id == 0 then
                                        gHero.SetVar(v[1]:GetPlayerID(), "Target", {Obj=enemy.Obj, Id=k})
                                        gHero.GetVar(v[1]:GetPlayerID(), "Self"):AddMode(constants.MODE_FIGHT)
                                        if #v[2] > 0 and GetUnitToUnitDistance(v[1], enemy.Obj) < v[3] then
                                            gHero.GetVar(v[1]:GetPlayerID(), "Self"):QueueNuke(v[1], enemy.Obj, v[2], v[3])
                                        elseif #v[2] > 0 then
                                            gHero.HeroAttackUnit(v[1], enemy.Obj, true)
                                        end
                                    end
                                end

                                for _, v in pairs(globalAllies) do
                                    gHero.SetVar(v[1]:GetPlayerID(), "UseGlobal", {v[2][1], enemy.Obj})
                                    utils.myPrint(utils.GetHeroName(v[1]).." casting global skill.")
                                end

                                return
                            end
                        end
                    end
                end
            end

            if numEnemiesThatCanAttackMe > numAlliesThatCanHelpMe then
                --utils.myPrint(utils.GetHeroName(ally), "This is a bad idea")
                --ally:Action_ClearActions(false)
            end
        end
    end
end

for k,v in pairs( global_game_state ) do _G._savedEnv[k] = v end
