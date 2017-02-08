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

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()
    if not bot:IsAlive() then return false end

    -- Check if we're already using an ability
    if bot:IsUsingAbility() or bot:IsChanneling() then return false end

    if UseUlt(bot, nearbyEnemyHeroes) or UseW(bot, nearbyEnemyHeroes) or UseQ(bot, nearbyAlliedHeroes) then return true end
    
    return false
end

function UseQ(bot, nearbyAlliedHeroes)
    local ability = bot:GetAbilityByName(Abilities[1])

    if not ability:IsFullyCastable() then
        return false
    end
    
    local coreNear = false
    for _, ally in ipairs(nearbyAlliedHeroes) do
        if utils.IsCore(ally) then
            coreNear = true
            break
        end
    end
    
    local currManaPerct = bot:GetMana()/bot:GetMaxMana()
    local nRadius = ability:GetSpecialValueInt( "radius" )
    local nDamage = ability:GetSpecialValueInt( "nova_damage" )
    
    -- If there is no Core ally around and we can kill 2+ creeps
    local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), ability:GetCastRange(), nRadius, 0, nDamage )
    if locationAoE.count >= 2 and (not coreNear) and currManaPerct >= 0.25 then
        bot:Action_UseAbilityOnLocation(ability, locationAoE.targetloc)
        return true
    end
    
    -- If we're pushing or defending a lane and can hit 4+ creeps, go for it
    if getHeroVar("ShouldDefend") == true or ( getHeroVar("ShouldPush") == true and currManaPerct >= 0.4 ) then
        local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), ability:GetCastRange(), nRadius, 0, 0 )

        if locationAoE.count >= 4 then
            bot:Action_UseAbilityOnLocation(ability, locationAoE.targetloc)
            return true
        end
    end
    
    -- If we have plenty mana and high level
    if currManaPerct > 0.6 and ability:GetLevel() >= 3 then
        local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), ability:GetCastRange(), nRadius, 0, 0 )
        -- hit 1+ heros
        if locationAoE.count >= 1 then
            bot:Action_UseAbilityOnLocation(ability, locationAoE.targetloc)
            return true
        end
    end

    return false
end

function UseW(bot, nearbyEnemyHeroes)
    local ability = bot:GetAbilityByName(Abilities[2])

    if not ability:IsFullyCastable() then
        return false
    end
    
    local nDamage = ability:GetSpecialValueInt("hero_damage_tooltip")
    
    local target = getHeroVar("Target")

    -- if we don't have a valid target
    if not utils.ValidTarget(target) then
        local currManaPerct = bot:GetMana()/bot:GetMaxMana()
        local bestTarget = nil
        if #nearbyEnemyHeroes > 0 then
            for _, enemy in pairs( nearbyEnemyHeroes ) do
                if not utils.IsTargetMagicImmune( enemy ) and GetUnitToUnitDistance(bot, enemy) < (ability:GetCastRange() + 250) then
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
            bot:Action_UseAbilityOnEntity( ability, bestTarget )
            return true
        end
    else
        if not utils.IsCrowdControlled(target.Obj) and not utils.IsTargetMagicImmune(target.Obj) then
            bot:Action_UseAbilityOnEntity( ability, bestTarget )
            return true
        end
    end
    
    return false
end

function UseUlt(bot, nearbyEnemyHeroes)
    local ability = bot:GetAbilityByName(Abilities[4])

    if not ability:IsFullyCastable() then
        return false
    end
    
    --FIXME: Implement
    
    --item_usage.UseGlimmerCape(bot)
    
    return false
end

for k,v in pairs( ability_usage_crystal_maiden ) do _G._savedEnv[k] = v end