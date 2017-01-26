_G._savedEnv = getfenv()
module( "buildings_status", package.seeall )

require(GetScriptDirectory() .. "/constants")
local utils = require(GetScriptDirectory() .. "/utility")

local tableBuildings = {
    [constants.TEAM_RADIANT] = {
        {["vector"]=utils.Locations["RTT1"], ["LastSeenHealth"]=1300, ["ApiID"]=0},
        {["vector"]=utils.Locations["RTT2"], ["LastSeenHealth"]=1600, ["ApiID"]=1},
        {["vector"]=utils.Locations["RTT3"], ["LastSeenHealth"]=1600, ["ApiID"]=2},
        {["vector"]=utils.Locations["RMT1"], ["LastSeenHealth"]=1300, ["ApiID"]=3},
        {["vector"]=utils.Locations["RMT2"], ["LastSeenHealth"]=1600, ["ApiID"]=4},
        {["vector"]=utils.Locations["RMT3"], ["LastSeenHealth"]=1600, ["ApiID"]=5},
        {["vector"]=utils.Locations["RBT1"], ["LastSeenHealth"]=1300, ["ApiID"]=6},
        {["vector"]=utils.Locations["RBT2"], ["LastSeenHealth"]=1600, ["ApiID"]=7},
        {["vector"]=utils.Locations["RBT3"], ["LastSeenHealth"]=1600, ["ApiID"]=8},
        {["vector"]=utils.Locations["RadiantBase"], ["LastSeenHealth"]=4250, ["ApiID"]=-1},
        {["vector"]=utils.Locations["RadiantTopShrine"], ["LastSeenHealth"]=1500, ["ApiID"]=-1},
        {["vector"]=utils.Locations["RadiantBotShrine"], ["LastSeenHealth"]=1500, ["ApiID"]=-1},
    },
    [constants.TEAM_DIRE] = {
        {["vector"]=utils.Locations["DTT1"], ["LastSeenHealth"]=1300, ["ApiID"]=0},
        {["vector"]=utils.Locations["DTT2"], ["LastSeenHealth"]=1600, ["ApiID"]=1},
        {["vector"]=utils.Locations["DTT3"], ["LastSeenHealth"]=1600, ["ApiID"]=2},
        {["vector"]=utils.Locations["DMT1"], ["LastSeenHealth"]=1300, ["ApiID"]=3},
        {["vector"]=utils.Locations["DMT2"], ["LastSeenHealth"]=1600, ["ApiID"]=4},
        {["vector"]=utils.Locations["DMT3"], ["LastSeenHealth"]=1600, ["ApiID"]=5},
        {["vector"]=utils.Locations["DBT1"], ["LastSeenHealth"]=1300, ["ApiID"]=6},
        {["vector"]=utils.Locations["DBT2"], ["LastSeenHealth"]=1600, ["ApiID"]=7},
        {["vector"]=utils.Locations["DBT3"], ["LastSeenHealth"]=1600, ["ApiID"]=8},
        {["vector"]=utils.Locations["DireBase"], ["LastSeenHealth"]=4250, ["ApiID"]=-1},
        {["vector"]=utils.Locations["DireTopShrine"], ["LastSeenHealth"]=1500, ["ApiID"]=-1},
        {["vector"]=utils.Locations["DireBotShrine"], ["LastSeenHealth"]=1500, ["ApiID"]=-1},
    }
}

local lastUpdate = -9999

function Update(forceUpdate)
    if DotaTime() - lastUpdate < 0.5 then
        if forceUpdate == nil or forceUpdate == False then return end
    end
    lastUpdate = DotaTime()
    for _, building in pairs(tableBuildings[TEAM_RADIANT]) do
        if building.ApiID ~= -1 then
            local tower = GetTower(TEAM_RADIANT, building.ApiID)
            if tower == nil then
                building.LastSeenHealth = -1
            else
                local health = tower:GetHealth()
                if health > -1 then
                    building.LastSeenHealth = health
                end
            end
        end
    end
    for _, building in pairs(tableBuildings[TEAM_DIRE]) do
        if building.ApiID ~= -1 then
            local tower = GetTower(TEAM_DIRE, building.ApiID)
            if tower == nil then
                building.LastSeenHealth = -1
            else
                local health = tower:GetHealth()
                if health > -1 then
                    building.LastSeenHealth = health
                end
            end
        end
    end
end

function GetTowerHealth(team, tower_id, cacheOnly)
    if cacheOnly == nil then cacheOnly = True end
    local seen = tableBuildings[team][tower_id].LastSeenHealth
    if cacheOnly then return seen end
    if seen <= 0 then return -1 end
    if tableBuildings[team][tower_id].ApiID == -1 then return seen end
    local tower = GetTower(team, tableBuildings[team][tower_id].ApiID)
    if tower == nil then
        tableBuildings[team][tower_id].LastSeenHealth = -1
        return -1
    end
    local health = tower:GetHealth()
    if health > -1 then
        tableBuildings[team][tower_id].LastSeenHealth = health
        return health
    else
        return seen
    end
end

function GetTowerLocation(team, tower_id)
    return tableBuildings[team][tower_id].vector
end

function GetTowerUnit(team, tower_id)
    return GetTower(team, tableBuildings[team][tower_id].ApiID)
end

function GetStandingTowerIDs(team)
    ids = {}
    for i, building in pairs(tableBuildings[team]) do
        if GetTowerHealth(team, i) > -1 then
            ids[#ids+1] = i
        end
    end
    return ids
end

function printBuildings()
    print("Buildings Radiant")
    for i, building in pairs(tableBuildings[TEAM_RADIANT]) do
        print(i, building.LastSeenHealth)
    end
    print("Buildings Dire")
    for i, building in pairs(tableBuildings[TEAM_DIRE]) do
        print(i, building.LastSeenHealth)
    end
end

for k,v in pairs( buildings_status ) do _G._savedEnv[k] = v end
