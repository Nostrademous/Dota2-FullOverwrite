-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

local EnemyData = {}

-- GLOBAL ENEMY INFORMATION ARRAY

EnemyData.Lock = false

EnemyData.LastUpdate = -1000.0

-------------------------------------------------------------------------------
-- FUNCTIONS - implement rudimentary atomic operation insurance
-------------------------------------------------------------------------------
local function EnemyEntryValidAndAlive(entry)
    return entry.obj ~= nil and entry.last_seen ~= -1000.0 and entry.obj:GetHealth() ~= -1
end

function EnemyData.UpdateEnemyInfo(timeFreq)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
    local timeFreq = timeFreq or 0.5

    local bUpdate, newTime = utils.TimePassed(EnemyData.LastUpdate, timeFreq)
    if bUpdate then
        if ( EnemyData.Lock ) then return end
        EnemyData.Lock = true

        local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES)
        for _, enemy in pairs(enemies) do
            local pid = enemy:GetPlayerID()
            local name = utils.GetHeroName(enemy)

            if EnemyData[pid] == nil then
                EnemyData[pid] = { Name = name, Time = -100, Obj = nil, Level = 1, Health = -1, MaxHealth = -1, Mana = -1, Location = nil, Items = {},
                                    PhysDmg2 = {}, MagicDmg2 = {}, PureDmg2 = {}, AllDmg2 = {},
                                    PhysDmg10 = {}, MagicDmg10 = {}, PureDmg10 = {}, AllDmg10 = {}
                                 }
            end

            local tDelta = RealTime() - EnemyData[pid].Time
            -- throttle our update to once every 1 second for each enemy
            if tDelta >= timeFreq and enemy:GetHealth() ~= -1 then
                EnemyData[pid].Time = RealTime()
                EnemyData[pid].Obj = enemy
                EnemyData[pid].Level = enemy:GetLevel()
                EnemyData[pid].Health = enemy:GetHealth()
                EnemyData[pid].MaxHealth = enemy:GetMaxHealth()
                EnemyData[pid].Mana = enemy:GetMana()
                EnemyData[pid].MaxMana = enemy:GetMaxMana()
                EnemyData[pid].MoveSpeed = enemy:GetCurrentMovementSpeed()
                EnemyData[pid].Location = utils.deepcopy(enemy:GetLocation())
                for i = 0, 5, 1 do
                    local item = enemy:GetItemInSlot(i)
                    if item ~= nil then
                        EnemyData[pid].Items[i] = item:GetName()
                    end
                end

                EnemyData[pid].SlowDur = enemy:GetSlowDuration(false) -- FIXME: does this count abilities only, or Items too?
                EnemyData[pid].StunDur = enemy:GetStunDuration(false) -- FIXME: does this count abilities only, or Items too?
                EnemyData[pid].HasSilence = enemy:HasSilence(false) -- FIXME: does this count abilities only, or Items too?
                EnemyData[pid].HasTruestrike = enemy:IsUnableToMiss()

                local allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
                for _, ally in pairs(allies) do
                    EnemyData[pid].PhysDmg2[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 2.0, DAMAGE_TYPE_PHYSICAL)
                    EnemyData[pid].MagicDmg2[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 2.0, DAMAGE_TYPE_MAGICAL)
                    EnemyData[pid].PureDmg2[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 2.0, DAMAGE_TYPE_PURE)
                    EnemyData[pid].AllDmg2[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 2.0, DAMAGE_TYPE_ALL)
                    EnemyData[pid].PhysDmg10[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 10.0, DAMAGE_TYPE_PHYSICAL)
                    EnemyData[pid].MagicDmg10[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 10.0, DAMAGE_TYPE_MAGICAL)
                    EnemyData[pid].PureDmg10[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 10.0, DAMAGE_TYPE_PURE)
                    EnemyData[pid].AllDmg10[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 10.0, DAMAGE_TYPE_ALL)
                end
            end
        end
        -- update our timer
        EnemyData.LastUpdate = newTime
    end

    EnemyData.Lock = false
end

function EnemyData.GetEnemyDmgs(ePID, fDuration)
    if ( EnemyData.Lock ) then return 0 end
    EnemyData.Lock = true

    local physDmg2 = 0
    local magicDmg2 = 0
    local pureDmg2 = 0
    local allDmg2 = 0
    local physDmg10 = 0
    local magicDmg10 = 0
    local pureDmg10 = 0
    local allDmg10 = 0
    local pid = GetBot():GetPlayerID()
    for k, v in pairs(EnemyData) do
        if type(k) == "number"  and k == ePID then
            physDmg2    = v.PhysDmg2[pid] or 0
            magicDmg2   = v.MagicDmg2[pid] or 0
            pureDmg2    = v.PureDmg2[pid] or 0
            allDmg2     = v.AllDmg2[pid] or 0
            physDmg10   = v.PhysDmg10[pid] or 0
            magicDmg10  = v.MagicDmg10[pid] or 0
            pureDmg10   = v.PureDmg10[pid] or 0
            allDmg10    = v.AllDmg10[pid] or 0
            break
        end
    end

    EnemyData.Lock = false

    local totalDmg2 = physDmg2 + magicDmg2 + pureDmg2
    local totalDmg10 = physDmg10 + magicDmg10 + pureDmg10
    --utils.myPrint(" 2s - AllDmg: ", allDmg2, " <> TotalDmg: ", totalDmg2, ", PhysDmg: ", physDmg2, ", MagicDmg: ", magicDmg2, ", pureDmg: ", pureDmg2)
    --utils.myPrint("10s - AllDmg: ", allDmg10, " <> TotalDmg: ", totalDmg10, ", PhysDmg: ", physDmg10, ", MagicDmg: ", magicDmg10, ", pureDmg: ", pureDmg10)

    if fDuration <= 2.0 then
        return physDmg2, magicDmg2, pureDmg2
    end
    return physDmg10, magicDmg10, pureDmg10
end

function EnemyData.GetEnemySlowDuration(ePID)
    if ( EnemyData.Lock ) then return 0 end
    EnemyData.Lock = true

    local duration = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number"  and k == ePID then
            duration = v.SlowDur
            break
        end
    end

    EnemyData.Lock = false

    return duration
end

function EnemyData.GetEnemyStunDuration(ePID)
    if ( EnemyData.Lock ) then return 0 end
    EnemyData.Lock = true

    local duration = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number"  and k == ePID then
            duration = v.StunDur
            break
        end
    end

    EnemyData.Lock = false

    return duration
end

function EnemyData.GetEnemyTeamSlowDuration()
    if ( EnemyData.Lock ) then return 0 end
    EnemyData.Lock = true

    local duration = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            duration = duration + v.SlowDur
        end
    end

    EnemyData.Lock = false

    return duration
end

function EnemyData.GetEnemyTeamStunDuration()
    if ( EnemyData.Lock ) then return 0 end
    EnemyData.Lock = true

    local duration = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            duration = duration + v.StunDur
        end
    end

    EnemyData.Lock = false

    return duration
end

function EnemyData.GetEnemyTeamNumSilences()
    if ( EnemyData.Lock ) then return 0 end
    EnemyData.Lock = true

    local num = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            if v.HasSilence then
                num = num + 1
            end
        end
    end

    EnemyData.Lock = false

    return num
end

function EnemyData.GetEnemyTeamNumTruestrike()
    if ( EnemyData.Lock ) then return 0 end
    EnemyData.Lock = true

    local num = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            if v.HasTruestrike then
                num = num + 1
            end
        end
    end

    EnemyData.Lock = false

    return num
end

function EnemyData.PrintEnemyInfo()

    if ( EnemyData.Lock ) then return end
    EnemyData.Lock = true

    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            print("")
            print("     Name: ", v.Name)
            print("    Level: ", v.Level)
            print("Last Seen: ", v.Time)
            print("   Health: ", v.Health)
            print("     Mana: ", v.Mana)
            if v.Location then
                print(" Location: <", v.Location[1]..", "..v.Location[2]..", "..v.Location[3]..">")
            else
                print(" Location: <UNKNOWN>")
            end
            local iStr = ""
            for k2, v2 in pairs(v.Items) do
                iStr = iStr .. v2 .. " "
            end
            print("    Items: { "..iStr.." }")
        end
    end

    EnemyData.Lock = false
end

return EnemyData