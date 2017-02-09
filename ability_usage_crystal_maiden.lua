-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_crystal_maiden", package.seeall )

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_usage" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local Abilities ={
    "crystal_maiden_crystal_nova",
    "crystal_maiden_frostbite",
    "crystal_maiden_brilliance_aura",
    "crystal_maiden_freezing_field"
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()
    
    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end
    
    if not bot:IsAlive() then return false end

    -- Check if we're already using an ability
    if bot:IsUsingAbility() or bot:IsChanneling() then return false end

    if UseUlt(bot, nearbyEnemyHeroes) or UseW(bot, nearbyEnemyHeroes) or UseQ(bot, nearbyEnemyHeroes, nearbyAlliedHeroes) then return true end
    
    return false
end

function UseQ(bot, nearbyEnemyHeroes, nearbyAlliedHeroes)
    if not abilityQ:IsFullyCastable() then
        return false
    end
    
    local coreNear = false
    for _, ally in pairs(nearbyAlliedHeroes) do
        if utils.IsCore(ally) then
            coreNear = true
            break
        end
    end
    
    local currManaPerct = bot:GetMana()/bot:GetMaxMana()
    local nRadius = abilityQ:GetSpecialValueInt( "radius" )
    local nDamage = abilityQ:GetSpecialValueInt( "nova_damage" )
    local nCastRange = abilityQ:GetCastRange()
    
    -- If there is no Core ally around and we can kill 2+ creeps
    if not CoreNear and currManaPerct >= 0.25 then
        local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, nDamage )
        if locationAoE.count >= 2 then
            bot:Action_UseAbilityOnLocation(abilityQ, locationAoE.targetloc)
            return true
        end
    end
    
    ------------ RETREATING -----------------------
    if getHeroVar("IsRetreating") and (#nearbyEnemyHeroes > 1 or not abilityW:IsFullyCastable()) then
        for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
            if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and GetUnitToUnitDistance(bot, npcEnemy) < (nCastRange+200) then
                if not utils.IsTargetMagicImmune( npcEnemy )then
                    bot:Action_UseAbilityOnLocation(abilityQ, npcEnemy:GetLocation())
                    return true
                end
            end
        end
    end
    
    ------------ PUSH OR DEFEND TOWER ----------------
    if getHeroVar("ShouldDefend") == true or ( getHeroVar("ShouldPush") == true and currManaPerct >= 0.4 ) then
        local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0 )

        if locationAoE.count >= 4 then
            bot:Action_UseAbilityOnLocation(abilityQ, locationAoE.targetloc)
            return true
        end
    end
    
    --------- CHASING --------------------------------
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        if bot:GetMana() >= (abilityQ:GetMana() + abilityW:GetMana()) then
            bot:Action_UseAbilityOnLocation(abilityQ, target.Obj:GetLocation())
        end
    end
    
    -- If we have plenty mana and high level
    if currManaPerct > 0.6 and abilityQ:GetLevel() >= 3 then
        local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0 )
        -- hit 1+ heros
        if locationAoE.count >= 1 then
            bot:Action_UseAbilityOnLocation(abilityQ, locationAoE.targetloc)
            return true
        end
    end

    return false
end

function UseW(bot, nearbyEnemyHeroes)
    if not abilityW:IsFullyCastable() then
        return false
    end
    
    local nDamage = abilityW:GetSpecialValueInt("hero_damage_tooltip")
    local nCastRange = abilityW:GetCastRange()
    
    ------------ RETREATING -----------------------
    if getHeroVar("IsRetreating") and (#nearbyEnemyHeroes == 1 or not abilityQ:IsFullyCastable()) then
        for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
            if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and GetUnitToUnitDistance(bot, npcEnemy) < (nCastRange + 200) then
                if not utils.IsTargetMagicImmune( npcEnemy )then
                    bot:Action_UseAbilityOnEntity(abilityW, npcEnemy)
                    return true
                end
            end
        end
    end
    
    --------- CHASING & LANE HARASSMENT --------------------------------
    local target = getHeroVar("Target")
    -- if we don't have a valid target
    if not utils.ValidTarget(target) then
        local currManaPerct = bot:GetMana()/bot:GetMaxMana()
        local bestTarget = nil
        if #nearbyEnemyHeroes > 0 then
            for _, enemy in pairs( nearbyEnemyHeroes ) do
                if not utils.IsTargetMagicImmune( enemy ) and GetUnitToUnitDistance(bot, enemy) <= nCastRange then
                    if enemy:GetActualIncomingDamage( nDamage, DAMAGE_TYPE_MAGICAL ) > enemy:GetHealth() then
                        bestTarget = enemy
                        break
                    elseif enemy:IsChanneling() then
                        bestTarget = enemy
                        break
                    elseif bestTarget and bestTarget:GetHealth() > enemy:GetHealth() then
                        bestTarget = enemy
                    elseif bestTarget == nil and currManaPerct >= 0.6 then
                        bestTarget = enemy
                    end
                end
            end
        end
        if bestTarget and not utils.IsCrowdControlled(bestTarget) then
            bot:Action_UseAbilityOnEntity( abilityW, bestTarget )
            return true
        end
    else
        if not utils.IsCrowdControlled(target.Obj) and not utils.IsTargetMagicImmune(target.Obj) then
            bot:Action_UseAbilityOnEntity( abilityW, bestTarget )
            return true
        end
    end
    
    return false
end

function UseUlt(bot, nearbyEnemyHeroes)
    if not abilityR:IsFullyCastable() then
        return false
    end
    
    local nRadius = abilityR:GetSpecialValueInt("radius")
    
    local enemiesInRange = {}
    local numSlowStun = 0
    for _, enemy in pairs(nearbyEnemyHeroes) do
        if GetUnitToUnitDistance( bot, enemy ) < nRadius and not utils.IsTargetMagicImmune(enemy) then
            table.insert(enemiesInRange, enemy)
            if utils.IsCrowdControlled(enemy) then
                numSlowStun = numSlowStun + 1
            end
        end
    end
    
    ------------ DEFEND TOWER ----------------
    if getHeroVar("ShouldDefend") and #enemiesInRange >= 2 then
        bot:Action_UseAbility(abilityR)
        return true
    end
    
    --------- CHASING --------------------------------
    local target = getHeroVar("Target")
    -- if we don't have a valid target
    if utils.ValidTarget(target) and (#enemiesInRange >= 3 or numSlowStun > 1) then
        bot:Action_UseAbility(abilityR)
        return true
    end
    
    return false
end

for k,v in pairs( ability_usage_crystal_maiden ) do _G._savedEnv[k] = v end