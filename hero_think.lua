-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
------------------------------------------------------------------------------- 

_G._savedEnv = getfenv()
module( "hero_think", package.seeall )
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_usage" )

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local utils = require( GetScriptDirectory().."/utility" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

-- Consider incoming projectiles or nearby AOE and if we can evade.
-- This is of highest importance b/c if we are stunned/disabled we 
-- cannot do any of the other actions we might be asked to perform.
function ConsiderEvading(bot)
    local listProjectiles = GetLinearProjectiles()
    local listAOEAreas = GetAvoidanceZones()
    
    -- NOTE: a projectile will be a table with { "location", "ability", "velocity", "radius" }
    for _, projectile in pairs(listProjectiles) do
        --utils.myPrint("Ability: ", projectile.ability:GetName())
        --utils.myPrint("Velocity: ", projectile.velocity)
    end
    
    -- NOTE: an aoe will be table with { "location", "ability", "caster", "radius" }.
    setHeroVar("nearbyAOEs", {})
    for _, aoe in pairs(listAOEAreas) do
        if aoe.caster:GetTeam() ~= GetTeam() then
            utils.myPrint("Ability: ", aoe.ability:GetName())
            table.insert(getHeroVar("nearbyAOEs"), aoe)
        end
    end
    
    local aoes = getHeroVar("nearbyAOEs")
    if #aoes > 0 then
        for _, aoe in pairs(aoes) do
            if GetUnitToLocationDistance(bot, aoe.location) < aoe.radius then
                return BOT_MODE_DESIRE_ABSOLUTE
            end
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

-- Fight orchestration is done at a global Team level.
-- This just checks if we are given a fight target and a specific
-- action queue to execute as part of the fight.
function ConsiderAttacking(bot, nearbyEnemies, nearbyAllies)
    local target = getHeroVar("Target")
    if target and utils.ValidTarget(target) then
        if #nearbyAllies >= 3 then
            return BOT_MODE_DESIRE_HIGH
        else
            return BOT_MODE_DESIRE_MODERATE
        end
    end
    
    -- check 1v1 matchup
    --[[
    if #nearbyEnemies == 1 then
        local enemy = nearbyEnemies[1]
        if (bot:GetAttackDamage()*5 + bot:GetHealth()) > (enemy:GetAttackDamage()*5 + enemy:GetHealth()) then
            setHeroVar("Target", {Obj=enemy, Id=enemy:GetPlayerID()})
            return BOT_MODE_DESIRE_MODERATE
        end
    end
    --]]
    
    return BOT_MODE_DESIRE_NONE
end

-- Which Heroes should be present for Shrine heal is made at Team level.
-- This just tells us if we should be part of this event.
function ConsiderShrine(bot, playerAssignment, nearbyAllies)
    if bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
    
     if playerAssignment[bot:GetPlayerID()].UseShrine ~= nil then
        local useShrine = playerAssignment[bot:GetPlayerID()].UseShrine
        local numAllies = 0
        for _, ally in pairs(nearbyAllies) do
            if utils.InTable(useShrine.allies , ally:GetPlayerID()) then
                if GetUnitToUnitDistance(bot, ally) < 50 then
                    numAllies = numAllies + 1
                end
            end
        end
        
        if not getHeroVar("Shrine") then
            setHeroVar("Shrine", useShrine.shrine)
        end
        
        if numAllies == #useShrine.allies then
            setHeroVar("ShrineMode", {constants.SHRINE_USE, useShrine.allies})
            return BOT_MODE_DESIRE_ABSOLUTE
        end
        
        setHeroVar("ShrineMode", {constants.SHRINE_WAITING, useShrine.allies})
        return BOT_ACTION_DESIRE_VERYHIGH
     end
    
    return BOT_MODE_DESIRE_NONE
end

-- Determine if we should retreat. Team Fight Assignements can 
-- over-rule our desire though. It might be more important for us to die
-- in a fight but win the over-all battle. If no Team Fight Assignment, 
-- then it is up to the Hero to manage their safety from global and
-- tower/creep damage.
function ConsiderRetreating(bot, nearbyEnemies, nearbyETowers, nearbyAllies)

    local MaxStun = 3   
    for _, enemy in pairs(nearbyEnemies) do
        if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.25 then
            if getHeroVar("HasEscape") then
                MaxStun = MaxStun + enemy:GetStunDuration(true)
            else
                MaxStun = MaxStun + enemy:GetStunDuration(true) + 0.5*enemy:GetSlowDuration(true)
            end
        end
    end
    
    local allyTime = 0
    for _, ally in pairs(nearbyAllies) do
        if GetUnitToUnitDistance(bot, ally) < 1000 then
            allyTime = allyTime + ally:GetStunDuration(true) + 0.5*ally:GetSlowDuration(true)
        end
    end

    local enemyDamage = 0
    for _, enemy in pairs(nearbyEnemies) do
        if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.25 then
            local pDamage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun - allyTime, DAMAGE_TYPE_PHYSICAL)
            local mDamage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun - allyTime, DAMAGE_TYPE_MAGICAL)
            enemyDamage = enemyDamage + pDamage + mDamage + enemy:GetEstimatedDamageToTarget(true, bot, MaxStun - allyTime, DAMAGE_TYPE_PURE)
            --utils.myPrint("["..utils.GetHeroName(enemy).."]: Damage: ", enemyDamage)
        end
    end
    
    --utils.myPrint("ConsiderRetreat() :: MaxStun: ", MaxStun, ", Dmg: ", enemyDamage)

    if enemyDamage > 0 and enemyDamage > bot:GetHealth() then
        --utils.myPrint(" - Retreating - could die in perfect stun/slow overlap")
        if bot:GetHealth()/bot:GetMaxHealth() < 0.75 then
            setHeroVar("IsRetreating", true)
            setHeroVar("RetreatReason", constants.RETREAT_DANGER)
            return BOT_MODE_DESIRE_HIGH
        end
    end
    
    if bot:GetHealth()/bot:GetMaxHealth() > 0.9 and bot:GetMana()/bot:GetMaxMana() > 0.5 then
        if utils.IsTowerAttackingMe() then
            setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH 
        end
        return BOT_MODE_DESIRE_NONE
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.65 and bot:GetMana()/bot:GetMaxMana() > 0.6 and 
        GetUnitToLocationDistance(bot, GetLocationAlongLane(getHeroVar("CurLane"), 0)) > 6000 then
        if utils.IsTowerAttackingMe() then
            setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH 
        elseif utils.IsCreepAttackingMe() then
            local pushing = getHeroVar("ShouldPush")
            if not pushing then
                setHeroVar("RetreatReason", constants.RETREAT_CREEP)
                return BOT_MODE_DESIRE_LOW 
            end
        end
        return BOT_MODE_DESIRE_NONE
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.8 and bot:GetMana()/bot:GetMaxMana() > 0.36 and 
        GetUnitToLocationDistance(bot, GetLocationAlongLane(getHeroVar("CurLane"), 0)) > 6000 then
        if utils.IsTowerAttackingMe() then
            setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH
        elseif utils.IsCreepAttackingMe() then
            local pushing = getHeroVar("ShouldPush")
            if not pushing then
                setHeroVar("RetreatReason", constants.RETREAT_CREEP)
                return BOT_MODE_DESIRE_LOW 
            end
        end
        return BOT_MODE_DESIRE_NONE
    end

    local me = getHeroVar("Self")
    if ((bot:GetHealth()/bot:GetMaxHealth()) < 0.33 and me:getCurrentMode() ~= constants.MODE_JUNGLING) or
        (bot:GetMana()/bot:GetMaxMana() < 0.07 and me:getPrevMode() == constants.MODE_LANING and 
        not utils.IsCore()) then
        setHeroVar("IsRetreating", true)
        setHeroVar("RetreatReason", constants.RETREAT_FOUNTAIN)
        return BOT_MODE_DESIRE_NONE 
    end

    if utils.IsTowerAttackingMe() then
        if #nearbyETowers >= 1 then
            local eTower = nearbyETowers[1]
            if eTower:GetHealth()/eTower:GetMaxHealth() < 0.1 and not eTower:HasModifier("modifier_fountain_glyph") then
                return BOT_MODE_DESIRE_NONE
            end
        end
        setHeroVar("RetreatReason", constants.RETREAT_TOWER)
        return BOT_MODE_DESIRE_LOW  
    elseif utils.IsCreepAttackingMe() then
        local pushing = getHeroVar("ShouldPush")
        if not pushing then
            setHeroVar("RetreatReason", constants.RETREAT_CREEP)
            return BOT_MODE_DESIRE_LOW  
        end
    end

    return BOT_MODE_DESIRE_NONE
end

-- Courier usage is done at Team wide level. We can do our own 
-- shopping at secret/side shop if we are informed that the courier
-- will be unavailable to use for a certain period of time.
function ConsiderSecretAndSideShop(bot)
    if bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
    
    return BOT_MODE_DESIRE_NONE
end

-- The decision is made at Team level. 
-- This just checks if the Hero is part of the push, and if so, 
-- what lane.
function ConsiderPushingLane(bot, nearbyEnemies, nearbyETowers, nearbyECreeps, nearbyACreeps)
    -- don't push for at least first 3 minutes
    if DotaTime() < 3*60 then return BOT_MODE_DESIRE_NONE end

    if getHeroVar("Role") == constants.ROLE_JUNGLER and DotaTime() < 10*60 then
        return BOT_MODE_DESIRE_NONE
    end
    
    -- this is hero-specific push-lane determination
    if #nearbyETowers > 0 then
        if ( nearbyETowers[1]:GetHealth() / nearbyETowers[1]:GetMaxHealth() ) < 0.1 and
            not nearbyETowers[1]:HasModifier("modifier_fountain_glyph") then
            return BOT_MODE_DESIRE_HIGH
        else
            return BOT_MODE_DESIRE_NONE
        end
    end

    if #nearbyACreeps > 1 and #nearbyECreeps == 0 and #nearbyEnemies == 0 then
        return BOT_MODE_DESIRE_MODERATE
    end

    return BOT_MODE_DESIRE_NONE
end

-- The decision is made at Team level.
-- This just checks if the Hero is part of the defense, and 
-- where to go to defend if so.
function ConsiderDefendingLane(bot)
    local defInfo = getHeroVar("DoDefendLane")
    if defLane ~= nil then
        return BOT_MODE_DESIRE_VERYHIGH
    end
    return BOT_MODE_DESIRE_NONE
end

-- This is a localized lane decision. An ally defense can turn into an 
-- orchestrated Team level fight, but that will be determined at the 
-- Team level. If not a fight, then this is just a "buy my retreating
-- friend some time to go heal up / retreat".
function ConsiderDefendingAlly(bot)
    return BOT_MODE_DESIRE_NONE
end

-- Roaming decision are made at the Team level to keep all relevant
-- heroes informed of the upcoming kill opportunity. 
-- This just checks if this Hero is part of the Gank.
function ConsiderRoam(bot)
    if getHeroVar("Role") == ROLE_ROAMER or 
        (getHeroVar("Role") == ROLE_JUNGLER and getHeroVar("Self"):IsReadyToGank(bot)) then
        if ganking_generic.FindTarget(bot) then
            return BOT_MODE_DESIRE_HIGH
        end
    end
    return BOT_MODE_DESIRE_NONE
end

-- The decision if and who should get Rune is made Team wide.
-- This just checks if this Hero should get it.
function ConsiderRune(bot, playerAssignment)
    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then return BOT_MODE_DESIRE_NONE end
    
    if bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
    
    if playerAssignment[bot:GetPlayerID()].GetRune ~= nil then
        local runeInfo = playerAssignment[bot:GetPlayerID()].GetRune
        setHeroVar("RuneTarget", runeInfo[1])
        setHeroVar("RuneLoc", runeInfo[2])
        return BOT_MODE_DESIRE_HIGH 
    end
    
    return BOT_MODE_DESIRE_NONE
end

-- The decision to Roshan is done in TeamThink().
-- This just checks if this Hero should be part of the effort.
function ConsiderRoshan(bot)
    return BOT_MODE_DESIRE_NONE
end

-- Farming assignments are made Team Wide.
-- This just tells the Hero where he should Jungle.
function ConsiderJungle(bot, playerAssignment)
    if getHeroVar("Role") == constants.ROLE_JUNGLER then
        return BOT_MODE_DESIRE_MODERATE
    end
    return BOT_MODE_DESIRE_NONE
end

-- Laning assignments are made Team Wide for Pushing & Defending.
-- Laning assignments are initially determined at start of game/hero-selection.
-- This just tells the Hero which Lane he is supposed to be in.
function ConsiderLaning(bot, playerAssignment)
    if playerAssignment[bot:GetPlayerID()].Lane ~= nil then
        setHeroVar("CurLane", playerAssignment[bot:GetPlayerID()].Lane)
    end
    return BOT_MODE_DESIRE_VERYLOW 
end

-- Warding is done on a per-lane basis. This evaluates if this Hero
-- should ward, and where. (might be a team wide thing later)
function ConsiderWarding(bot, playerAssignment)
    if bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
    
    local me = getHeroVar("Self")
    
    -- we need to lane first before we know where to ward properly
    if me:getCurrentMode() ~= constants.MODE_LANING then return BOT_MODE_DESIRE_NONE end
    
    local WardCheckTimer = getHeroVar("WardCheckTimer")
    local bCheck = true
    local newTime = GameTime()
    if WardCheckTimer then
        bCheck, newTime = utils.TimePassed(WardCheckTimer, 1.0)
    end
    if bCheck then
        setHeroVar("WardCheckTimer", newTime)
        local ward = item_usage.HaveWard("item_ward_observer")
        if ward then
            local alliedMapWards = GetUnitList(UNIT_LIST_ALLIED_WARDS)
            if #alliedMapWards < 2 then --FIXME: don't hardcode.. you get more wards then you can use this way
                local wardLocs = utils.GetWardingSpot(getHeroVar("CurLane"))

                if wardLocs == nil or #wardLocs == 0 then return BOT_MODE_DESIRE_NONE end

                -- FIXME: Consider ward expiration time
                local wardLoc = nil
                for _, wl in ipairs(wardLocs) do
                    local bGoodLoc = true
                    for _, value in ipairs(alliedMapWards) do
                        if utils.GetDistance(value:GetLocation(), wl) < 1600 then
                            bGoodLoc = false
                        end
                    end
                    if bGoodLoc then
                        wardLoc = wl
                        break
                    end
                end

                if wardLoc ~= nil and utils.EnemiesNearLocation(bot, wardLoc, 2000) < 2 then
                    setHeroVar("WardLocation", wardLoc)
                    utils.InitPath()
                    return BOT_MODE_DESIRE_LOW 
                end
            end
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

for k,v in pairs( hero_think ) do _G._savedEnv[k] = v end
