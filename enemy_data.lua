-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

local EnemyData = {}

-- GLOBAL ENEMY INFORMATION ARRAY
local UpdateFreq1 = 0.5
local UpdateFreq2 = 3.0

-------------------------------------------------------------------------------
-- FUNCTIONS - implement rudimentary atomic operation insurance
-------------------------------------------------------------------------------

function EnemyData.CheckAlive()
    local enemyIDs = GetTeamPlayers(utils.GetOtherTeam())
    
    for _, id in ipairs(enemyIDs) do
        if EnemyData[id] == nil then
            EnemyData[id] = {  Name = "", Time1 = -100, Time2 = -100, Obj = nil, Level = 1,
                               Alive = true, Health = -1, MaxHealth = -1, Mana = -1, Items = {},
                               PhysDmg2 = {}, MagicDmg2 = {}, PureDmg2 = {}, AllDmg2 = {},
                               PhysDmg10 = {}, MagicDmg10 = {}, PureDmg10 = {}, AllDmg10 = {}
                            }
        end
    
        -- update who is alive and who is dead
        if IsHeroAlive(id) then
            EnemyData[id].Alive = true
        else
            EnemyData[id].Alive = false
        end
        
        -- invalidate our object handle
        EnemyData[id].Obj = nil
    end
end

function EnemyData.GetNumAlive()
    local numAlive = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" and v.Alive then
            numAlive = numAlive + 1
        end
    end
    return numAlive
end

function EnemyData.UpdateEnemyInfo(timeFreq)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
    
    EnemyData.CheckAlive()
    
    local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES)
    for _, enemy in pairs(enemies) do
        local pid = enemy:GetPlayerID()

        EnemyData[pid].Name = utils.GetHeroName(enemy)
        EnemyData[pid].Obj = enemy
        EnemyData[pid].Level = enemy:GetLevel()

        if (RealTime() - EnemyData[pid].Time1) >= UpdateFreq1 then
            EnemyData[pid].Time1        = RealTime()
            EnemyData[pid].Health       = enemy:GetHealth()
            EnemyData[pid].MaxHealth    = enemy:GetMaxHealth()
            EnemyData[pid].Mana         = enemy:GetMana()
            EnemyData[pid].MaxMana      = enemy:GetMaxMana()
            EnemyData[pid].MoveSpeed    = enemy:GetCurrentMovementSpeed()
            EnemyData[pid].LocExtra1    = enemy:GetExtrapolatedLocation(0.5) -- 1/2 second
            EnemyData[pid].LocExtra2    = enemy:GetExtrapolatedLocation(3.0) -- 3 second

            if (RealTime() - EnemyData[pid].Time2) >= UpdateFreq2 then
                EnemyData[pid].Time2 = RealTime()
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
    end
end

local function GetEnemyFutureLocation(ePID, fTime)
    for k, v in pairs(EnemyData) do
        if type(k) == "number"  and k == ePID then
            if fTime <= 0.5 then
                return v.LocExtra1
            elseif fTime <= 3.0 then
                return v.LocExtra2
            else
                return nil
            end
        end
    end
    return nil
end

function EnemyData.PredictedLocation(targetID, fTime)
    if targetID == 0 or (targetID > 0 and not IsHeroAlive(targetID)) then return nil end

    return GetEnemyFutureLocation(targetID, fTime)
end

function EnemyData.GetEnemyDmgs(ePID, fDuration)
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
    local duration = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number"  and k == ePID then
            duration = v.SlowDur
            break
        end
    end
    return duration
end

function EnemyData.GetEnemyStunDuration(ePID)
    local duration = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number"  and k == ePID then
            duration = v.StunDur
            break
        end
    end
    return duration
end

function EnemyData.GetEnemyTeamSlowDuration()
    local duration = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            duration = duration + v.SlowDur
        end
    end
    return duration
end

function EnemyData.GetEnemyTeamStunDuration()
    local duration = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            duration = duration + v.StunDur
        end
    end
    return duration
end

function EnemyData.GetEnemyTeamNumSilences()
    local num = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            if v.HasSilence then
                num = num + 1
            end
        end
    end
    return num
end

function EnemyData.GetEnemyTeamNumTruestrike()
    local num = 0
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            if v.HasTruestrike then
                num = num + 1
            end
        end
    end
    return num
end

function EnemyData.PrintEnemyInfo()
    for k, v in pairs(EnemyData) do
        if type(k) == "number" then
            print("")
            print("     Name: ", v.Name)
            print("    Level: ", v.Level)
            print("Last Seen: ", v.Time1)
            print("   Health: ", v.Health)
            print("     Mana: ", v.Mana)

            local iStr = ""
            for k2, v2 in pairs(v.Items) do
                iStr = iStr .. v2 .. " "
            end
            print("    Items: { "..iStr.." }")
        end
    end
end

return EnemyData