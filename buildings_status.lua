_G._savedEnv = getfenv()
module( "buildings_status", package.seeall )

 TYPE_TOWER = "tower"
 TYPE_MELEE = "melee"
 TYPE_RANGED = "ranged"
 TYPE_SHRINE = "shrine"
 TYPE_ANCIENT = "ancient"

local buildings = {
    {["ApiID"]=TOWER_TOP_1, ["Type"]=TYPE_TOWER}, -- 1
    {["ApiID"]=TOWER_TOP_2, ["Type"]=TYPE_TOWER},
    {["ApiID"]=TOWER_TOP_3, ["Type"]=TYPE_TOWER},
    {["ApiID"]=TOWER_MID_1, ["Type"]=TYPE_TOWER}, -- 4
    {["ApiID"]=TOWER_MID_2, ["Type"]=TYPE_TOWER},
    {["ApiID"]=TOWER_MID_3, ["Type"]=TYPE_TOWER},
    {["ApiID"]=TOWER_BOT_1, ["Type"]=TYPE_TOWER}, -- 7
    {["ApiID"]=TOWER_BOT_2, ["Type"]=TYPE_TOWER},
    {["ApiID"]=TOWER_BOT_3, ["Type"]=TYPE_TOWER},
    {["ApiID"]=TOWER_BASE_1, ["Type"]=TYPE_TOWER}, -- 10
    {["ApiID"]=TOWER_BASE_2, ["Type"]=TYPE_TOWER}, -- 11
    {["ApiID"]=BARRACKS_TOP_MELEE, ["Type"]=TYPE_MELEE},
    {["ApiID"]=BARRACKS_TOP_RANGED, ["Type"]=TYPE_RANGED},
    {["ApiID"]=BARRACKS_MID_MELEE, ["Type"]=TYPE_MELEE},
    {["ApiID"]=BARRACKS_MID_RANGED, ["Type"]=TYPE_RANGED},
    {["ApiID"]=BARRACKS_BOT_MELEE, ["Type"]=TYPE_MELEE},
    {["ApiID"]=BARRACKS_BOT_RANGED, ["Type"]=TYPE_RANGED},
    {["ApiID"]=0, ["Type"]=TYPE_ANCIENT},
    {["ApiID"]=SHRINE_JUNGLE_1, ["Type"]=TYPE_SHRINE},
    {["ApiID"]=SHRINE_JUNGLE_2, ["Type"]=TYPE_SHRINE},
    {["ApiID"]=SHRINE_BASE_1, ["Type"]=TYPE_SHRINE},
    {["ApiID"]=SHRINE_BASE_2, ["Type"]=TYPE_SHRINE},
    {["ApiID"]=SHRINE_BASE_3, ["Type"]=TYPE_SHRINE},
    {["ApiID"]=SHRINE_BASE_4, ["Type"]=TYPE_SHRINE},
    {["ApiID"]=SHRINE_BASE_5, ["Type"]=TYPE_SHRINE}
}

local tableBuildings = {}

local towers = {}
local barracks = {}
local shrines = {}

local lastUpdate = -9999

-- fill the empty tables
local function Initialize()
    tableBuildings[TEAM_RADIANT] = {}
    tableBuildings[TEAM_DIRE] = {}
    local team = GetTeam()
    for i, building in ipairs(buildings) do
        local building_radiant = {}
        local building_dire = {}
        tableBuildings[TEAM_RADIANT][i] = building_radiant
        tableBuildings[TEAM_DIRE][i] = building_dire
        local health = 0
        local pos_radiant = nil
        local pos_dire = nil
        if building.Type == TYPE_TOWER then
            health = GetTower(team, building.ApiID):GetMaxHealth()
            pos_radiant = GetTower(TEAM_RADIANT, building.ApiID):GetLocation()
            pos_dire = GetTower(TEAM_DIRE, building.ApiID):GetLocation()
            towers[#towers+1] = i
        elseif building.Type == TYPE_MELEE then
            health = GetBarracks(team, building.ApiID):GetMaxHealth()
            pos_radiant = GetBarracks(TEAM_RADIANT, building.ApiID):GetLocation()
            pos_dire = GetBarracks(TEAM_DIRE, building.ApiID):GetLocation()
            barracks[#barracks+1] = i
        elseif building.Type == TYPE_RANGED then
            health = GetBarracks(team, building.ApiID):GetMaxHealth()
            pos_radiant = GetBarracks(TEAM_RADIANT, building.ApiID):GetLocation()
            pos_dire = GetBarracks(TEAM_DIRE, building.ApiID):GetLocation()
            barracks[#barracks+1] = i
        elseif building.Type == TYPE_SHRINE then
            health = GetShrine(team, building.ApiID):GetMaxHealth()
            pos_radiant = GetShrine(TEAM_RADIANT, building.ApiID):GetLocation()
            pos_dire = GetShrine(TEAM_DIRE, building.ApiID):GetLocation()
            shrines[#shrines+1] = i
        elseif building.Type == TYPE_ANCIENT then
            health = GetAncient(team):GetMaxHealth()
            pos_radiant = GetAncient(TEAM_RADIANT):GetLocation()
            pos_dire = GetAncient(TEAM_DIRE):GetLocation()
        end
        building_radiant.ApiID = building.ApiID
        building_radiant.Type = building.Type
        building_radiant.MaxHealth = health
        building_radiant.LastSeenHealth = health
        building_radiant.Vector = pos_radiant
        building_dire.ApiID = building.ApiID
        building_dire.Type = building.Type
        building_dire.MaxHealth = health
        building_dire.LastSeenHealth = health
        building_dire.Vector = pos_dire
    end
end

function Update(forceUpdate)
    if lastUpdate < -1000 then
        Initialize()
    end
    if DotaTime() - lastUpdate < 0.5 then
        if (not forceUpdate) then return end
    end
    lastUpdate = DotaTime()
    for i, _ in ipairs(tableBuildings[TEAM_RADIANT]) do
        GetHealth(TEAM_RADIANT, i, false)
    end
    for i, _ in ipairs(tableBuildings[TEAM_DIRE]) do
        GetHealth(TEAM_DIRE, i, false)
    end
end

function GetHealth(team, id, cacheOnly)
    cacheOnly = cacheOnly or true
    local seen = tableBuildings[team][id].LastSeenHealth
    if cacheOnly then return seen end
    if seen <= 0 then return -1 end
    local building = GetHandle(team, id)
    if building == nil then
        tableBuildings[team][id].LastSeenHealth = -1
        return -1
    end
    local health = building:GetHealth()
    if health > -1 then
        tableBuildings[team][id].LastSeenHealth = health
        return health
    else
        return seen
    end
end

function GetLocation(team, id)
    local result = tableBuildings[team][id].Vector
    return result
end

function GetHandle(team, id)
    local building = tableBuildings[team][id]
    if building.Type == TYPE_TOWER then
        return GetTower(team, building.ApiID)
    elseif building.Type == TYPE_MELEE then
        return GetBarracks(team, building.ApiID)
    elseif building.Type == TYPE_RANGED then
        return GetBarracks(team, building.ApiID)
    elseif building.Type == TYPE_SHRINE then
        return GetShrine(team, building.ApiID)
    elseif building.Type == TYPE_ANCIENT then
        return GetAncient(team)
    end
    return nil
end

function GetStandingBuildingIDs(team)
    local ids = {}
    for i, _ in ipairs(tableBuildings[team]) do
        if GetHealth(team, i) > 0 then
            ids[#ids+1] = i
        end
    end
    return ids
end

function GetType(team, id)
    return tableBuildings[team][id].Type
end

function GetDestroyableTowers(team)
    local ids = {}
    for _, id in pairs(towers) do
        if GetHealth(team, id) > 0 and GetHandle(team, id) ~= nil and (not GetHandle(team, id):IsInvulnerable()) then
            ids[#ids+1] = id
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

-- check tower dependencies (glyph doesn't matter)
function GetVulnerableBuildingIDs(team)
    local ids = {}
    -- TODO: use a method that isn't depending on exact order in tableBuildings
    for j = 0,6,3 do -- for all lanes
        for i = 1,3,1 do -- towers from t1 to t3
            if GetHealth(team, i+j) > 0 then
                ids[#ids+1] = i+j
                break
            end
        end
    end
    -- TODO: check shrines (outside base)
    -- TODO: check rax
    -- TODO: check t4s
    -- TODO: check throne
    return ids
end

for k,v in pairs( buildings_status ) do _G._savedEnv[k] = v end
