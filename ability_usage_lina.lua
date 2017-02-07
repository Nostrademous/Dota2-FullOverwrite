-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_lina", package.seeall )

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

local Abilities =   {
    "lina_light_strike_array",
    "lina_dragon_slave",
    "lina_fiery_soul",
    "lina_laguna_blade"
}

local castLSADesire = 0
local castDSDesire  = 0
local castLBDesire  = 0

local function comboDamage( bot, enemy, abilityLB, abilityLSA, abilityDS )
    if abilityLB:GetLevel() == 0 then return 0, 0 end
    
    local mana = bot:GetMana()
    
    local manaCostPartCombo = abilityLB:GetManaCost() + abilityDS:GetManaCost()
    if (mana < manaCostPartCombo) or (not abilityLB:IsFullyCastable()) or (not abilityDS:IsFullyCastable()) then return 0, 0 end
    
    local actualDmgPartCombo = 0
    if bot:HasScepter() then
        actualDmgPartCombo = abilityLB:GetAbilityDamage() + enemy:GetActualIncomingDamage(abilityDS:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
    else
        actualDmgPartCombo = enemy:GetActualIncomingDamage(abilityLB:GetAbilityDamage() + abilityDS:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
    end
    
    local manaCostFullCombo = manaCostPartCombo + abilityLSA:GetManaCost()
    if mana < manaCostFullCombo or not abilityLSA:IsFullyCastable() then return actualDmgPartCombo, 2 end
    if bot:HasScepter() then
        actualDmgFullCombo = abilityLB:GetAbilityDamage() + enemy:GetActualIncomingDamage(abilityDS:GetAbilityDamage() + abilityLSA:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
    else
        actualDmgFullCombo = enemy:GetActualIncomingDamage(abilityLB:GetAbilityDamage() + abilityDS:GetAbilityDamage() + abilityLSA:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
    end
    return actualDmgFullCombo, 3
end

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local npcBot = GetBot()
    if not npcBot:IsAlive() then return false end

    -- Check if we're already using an ability
    if ( npcBot:IsUsingAbility() or npcBot:IsChanneling() ) then return false end

    local abilityLSA = npcBot:GetAbilityByName( Abilities[1] )
    local abilityDS = npcBot:GetAbilityByName( Abilities[2] )
    local abilityLB = npcBot:GetAbilityByName( Abilities[4] )

    if ( #nearbyEnemyHeroes == 0 and #nearbyEnemyCreep == 0 ) then return false end

    if #nearbyEnemyHeroes == 1 and nearbyEnemyHeroes[1]:GetHealth() > 0 then
        local enemy = nearbyEnemyHeroes[1]
        local dmg, spells = comboDamage( npcBot, enemy, abilityLB, abilityLSA, abilityDS )
        if dmg > enemy:GetHealth() and not utils.IsTargetMagicImmune( enemy ) then
            setHeroVar("Target", {Obj=enemy, Id=enemy:GetPlayerID()})
            npcBot:SetActionQueueing(true)
            if spells == 2 then
                local nCastRange = abilityDS:GetCastRange()
                local dist = GetUnitToUnitDistance(npcBot, enemy)

                if dist < nCastRange then
                    utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
                    -- NOTE: cast point is 0.45, speed is 1200
                    local loc = enemy:GetExtrapolatedLocation(0.45 + dist/1200)
                    npcBot:Action_UseAbilityOnLocation( abilityDS, loc )
                    npcBot:Action_UseAbilityOnEntity( abilityLB, enemy )
                    npcBot:Action_AttackUnit( enemy, false )
                end
            elseif spells == 3 then
                local nRadius = abilityLSA:GetSpecialValueInt( "light_strike_array_aoe" )
                local nCastRange = abilityLSA:GetCastRange()
                local dist = GetUnitToUnitDistance(npcBot, enemy)

                if dist < (nCastRange + nRadius) then
                    utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
                    npcBot:Action_UseAbilityOnLocation( abilityLSA, enemy:GetExtrapolatedLocation(0.95) )
                    npcBot:Action_UseAbilityOnLocation( abilityDS, enemy:GetLocation() )
                    npcBot:Action_UseAbilityOnEntity( abilityLB, enemy )
                    npcBot:Action_AttackUnit( enemy, false )
                end
            end
            return true
        end
    end
    
    -- Consider using each ability
    castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLB, nearbyEnemyHeroes)

    local target = getHeroVar("Target")
    
    if utils.ValidTarget(target) then
        castLSADesire, castLSALocation = ConsiderLightStrikeArrayFighting(abilityLSA, target.Obj)
    else
        castLSADesire, castLSALocation = ConsiderLightStrikeArray(abilityLSA, nearbyEnemyHeroes)
    end

    if utils.ValidTarget(target) then
        castDSDesire, castDSLocation = ConsiderDragonSlaveFighting(abilityDS, target.Obj)
    else
        castDSDesire, castDSLocation = ConsiderDragonSlave(abilityDS)
    end

    if castLBDesire > castLSADesire and castLBDesire > castDSDesire then
        print ( "I Desired a LB Hit" )
        npcBot:Action_UseAbilityOnEntity( abilityLB, castLBTarget )
        return true
    end

    if castLSADesire > 0 then
        print ( "I Desired a LSA Hit" )
        npcBot:Action_UseAbilityOnLocation( abilityLSA, castLSALocation )
        return true
    end

    if castDSDesire > 0 then
        print ( "I Desired a DS Hit" )
        npcBot:Action_UseAbilityOnLocation( abilityDS, castDSLocation )
        return true
    end

    return false
end

----------------------------------------------------------------------------------------------------

local function CanCastLightStrikeArrayOnTarget( npcTarget )
    return npcTarget:IsHero() and not utils.IsTargetMagicImmune(npcTarget)
end

local function CanCastLagunaBladeOnTarget( npcTarget )
    return npcTarget:IsHero() and ( GetBot():HasScepter() or not npcTarget:IsMagicImmune() ) and not npcTarget:IsInvulnerable()
end

----------------------------------------------------------------------------------------------------

function ConsiderLightStrikeArrayFighting(abilityLSA, enemy)
    local npcBot = GetBot()

    if not abilityLSA:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, 0
    end;

    local nRadius = abilityLSA:GetSpecialValueInt( "light_strike_array_aoe" )
    local nCastRange = abilityLSA:GetCastRange()

    -- NOTE: LSA cast point is 0.45, hit delay is 0.50
    local locDelta = enemy:GetExtrapolatedLocation(0.95)
    local EnemyLocation = locDelta

    if enemy:IsStunned() or enemy:IsRooted() then
        EnemyLocation = enemy:GetLocation()
    end

    local d = GetUnitToLocationDistance(npcBot, EnemyLocation)

    if d < (nCastRange + nRadius) and not utils.IsTargetMagicImmune( enemy ) then
        return BOT_ACTION_DESIRE_HIGH, EnemyLocation
    end
    return BOT_ACTION_DESIRE_NONE, 0
end


function ConsiderLightStrikeArray(abilityLSA, nearbyEnemyHeroes)
    local npcBot = GetBot()

    -- Make sure it's castable
    if not abilityLSA:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- Get some of its values
    local nRadius = abilityLSA:GetSpecialValueInt( "light_strike_array_aoe" )
    local nCastRange = abilityLSA:GetCastRange()
    local nDamage = abilityLSA:GetAbilityDamage()

    --------------------------------------
    -- Global high-priorty usage
    --------------------------------------

    -- Check for a channeling enemy
    for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
        if npcEnemy:IsChanneling() and GetUnitToUnitDistance(npcBot, npcEnemy) < (nCastRange + nRadius + 200) then
            if CanCastLightStrikeArrayOnTarget( npcEnemy ) then
                return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
            end
        end
    end

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    -- If we're farming and can kill 3+ creeps with LSA
    local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, abilityLSA:GetCastPoint(), nDamage )

    if ( locationAoE.count >= 3 ) then
        return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
    end

    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
    for _,npcEnemy in pairs( nearbyEnemyHeroes ) do
        if GetUnitToUnitDistance(npcBot, npcEnemy) < (nCastRange + nRadius + 200) then
            -- FIXME: This logic will fail against Heartstopper Aura or Radiance probably making us LSA all the time
            --        as we take damage and are below 50% health
            if npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and (npcBot:GetHealth()/npcBot:GetMaxHealth()) < 0.5 then
                if CanCastLightStrikeArrayOnTarget( npcEnemy ) and abilityLSA:GetCastRange() > GetUnitToUnitDistance(npcBot, npcEnemy) then
                    -- NOTE: LSA cast point is 0.45, hit delay is 0.50
                    local locDelta = npcEnemy:GetExtrapolatedLocation(0.95)
                    return BOT_ACTION_DESIRE_MODERATE, locDelta
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

----------------------------------------------------------------------------------------------------

function ConsiderDragonSlaveFighting(abilityDS, enemy)
    local npcBot = GetBot()

    if ( not abilityDS:IsFullyCastable() ) then
        return BOT_ACTION_DESIRE_NONE, 0
    end;

    local nCastRange = abilityDS:GetCastRange()
    local d = GetUnitToUnitDistance(npcBot, enemy)

    if d < nCastRange and not utils.IsTargetMagicImmune( enemy ) then
        if utils.IsCrowdControlled(enemy) then
            return BOT_ACTION_DESIRE_HIGH, enemy:GetLocation()
        else
            -- NOTE: cast point is 0.45, speed is 1200
            local locDelta = enemy:GetExtrapolatedLocation(0.45 + d/1200)
            return BOT_ACTION_DESIRE_HIGH, locDelta
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function ConsiderDragonSlave(abilityDS)

    local npcBot = GetBot()

    if ( not abilityDS:IsFullyCastable() ) then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- Get some of its values
    local nRadius = abilityDS:GetSpecialValueInt( "dragon_slave_width_end" )
    local nCastRange = abilityDS:GetCastRange()
    local nDamage = abilityDS:GetAbilityDamage()
    --print("dragon_slave damage:" .. nDamage)

    -- If we're farming and can kill 2+ creeps with LSA when we have plenty mana
    local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, 0, nDamage )

    if ( locationAoE.count >= 2 ) then
        return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
    end

    -- If we're pushing or defending a lane and can hit 4+ creeps, go for it
    -- wasting mana banned!
    if getHeroVar("ShouldDefend") == true or (getHeroVar("ShouldPush") == true and ( npcBot:GetMana() / npcBot:GetMaxMana() >= 0.4 )) then
        local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, 0, 0 )

        if ( locationAoE.count >= 4 )
        then
            return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
        end
    end

    -- If we have plenty mana and high level DS
    if(npcBot:GetMana() / npcBot:GetMaxMana() > 0.6 and nDamage > 300) then
        local locationAoE = npcBot:FindAoELocation( true, true, npcBot:GetLocation(), nCastRange, nRadius, 0, 0 )

        -- hit heros
        if locationAoE.count >= 1 then
            return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end


----------------------------------------------------------------------------------------------------

function ConsiderLagunaBlade(abilityLB, nearbyEnemyHeroes)

    local npcBot = GetBot()

    -- Make sure it's castable
    if ( not abilityLB:IsFullyCastable() ) then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- Get some of its values
    local nCastRange = abilityLB:GetCastRange();
    local nDamage = abilityLB:GetSpecialValueInt( "damage" )
    local eDamageType = DAMAGE_TYPE_MAGICAL
    if npcBot:HasScepter() then
        eDamageType = DAMAGE_TYPE_PURE
    end

    -- If a mode has set a target, and we can kill them, do it
    if #nearbyEnemyHeroes > 0 then
        for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
            if GetUnitToUnitDistance(npcBot, npcEnemy) < (nCastRange + 200) and CanCastLagunaBladeOnTarget(npcEnemy) then
                if npcEnemy:GetActualIncomingDamage( nDamage, eDamageType ) > npcEnemy:GetHealth() then
                    return BOT_ACTION_DESIRE_MODERATE, npcEnemy
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0

end

for k,v in pairs( ability_usage_lina ) do _G._savedEnv[k] = v end