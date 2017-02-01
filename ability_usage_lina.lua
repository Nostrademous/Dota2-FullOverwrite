-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_lina", package.seeall )
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

function AbilityUsageThink()
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local npcBot = GetBot()
    if not npcBot:IsAlive() then return false end

    -- Check if we're already using an ability
    if ( npcBot:IsUsingAbility() or npcBot:IsChanneling() ) then return false end

    local abilityLSA = npcBot:GetAbilityByName( Abilities[1] )
    local abilityDS = npcBot:GetAbilityByName( Abilities[2] )
    local abilityLB = npcBot:GetAbilityByName( Abilities[4] )

    local EnemyHeroes = npcBot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    local EnemyCreeps = npcBot:GetNearbyCreeps(1200, true)

    if ( #EnemyHeroes == 0 and #EnemyCreeps == 0 ) then return false end

    -- Consider using each ability
    castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLB)

    local target = getHeroVar("Target")
    if target.Obj ~= nil then
        castLSADesire, castLSALocation = ConsiderLightStrikeArrayFighting(abilityLSA, target.Obj)
    else
        castLSADesire, castLSALocation = ConsiderLightStrikeArray(abilityLSA)
    end

    if target.Obj ~= nil then
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

function CanCastLightStrikeArrayOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

function CanCastDragonSlaveOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

function CanCastLagunaBladeOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and npcTarget:IsHero() and ( GetBot():HasScepter() or not npcTarget:IsMagicImmune() ) and not npcTarget:IsInvulnerable();
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

    if d < (nCastRange + nRadius) and CanCastLightStrikeArrayOnTarget( enemy ) then
        return BOT_ACTION_DESIRE_HIGH, EnemyLocation
    end
    return BOT_ACTION_DESIRE_NONE, 0
end


function ConsiderLightStrikeArray(abilityLSA)

    local npcBot = GetBot();

    -- Make sure it's castable
    if not abilityLSA:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, 0;
    end;


    -- Get some of its values
    local nRadius = abilityLSA:GetSpecialValueInt( "light_strike_array_aoe" )
    local nCastRange = abilityLSA:GetCastRange()
    local nDamage = abilityLSA:GetAbilityDamage()

    --------------------------------------
    -- Global high-priorty usage
    --------------------------------------

    -- Check for a channeling enemy
    local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + nRadius + 200, true, BOT_MODE_NONE );
    for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
        if npcEnemy:IsChanneling() then
            return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
        end
    end

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    -- If we're farming and can kill 3+ creeps with LSA
    local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, abilityLSA:GetCastPoint(), nDamage );

    if ( locationAoE.count >= 3 ) then
        return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
    end

    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
    local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + nRadius + 200, true, BOT_MODE_NONE );
    for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
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

    return BOT_ACTION_DESIRE_NONE, 0
end

----------------------------------------------------------------------------------------------------

function ConsiderDragonSlaveFighting(abilityDS, enemy)
    local npcBot = GetBot();

    if ( not abilityDS:IsFullyCastable() ) then
        return BOT_ACTION_DESIRE_NONE, 0;
    end;

    local nCastRange = abilityDS:GetCastRange();

    local d = GetUnitToUnitDistance(npcBot,enemy);

    if d < nCastRange and CanCastDragonSlaveOnTarget(enemy) then
        if enemy:IsStunned() or enemy:IsRooted() then
            return BOT_ACTION_DESIRE_HIGH, enemy:GetLocation()
        else
            -- NOTE: cast point is 0.45, speed is 1200
            local dist = GetUnitToUnitDistance(npcBot, enemy)
            local locDelta = enemy:GetExtrapolatedLocation(0.45 + dist/1200)
            return BOT_ACTION_DESIRE_HIGH, locDelta
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0;
end

function ConsiderDragonSlave(abilityDS)

    local npcBot = GetBot();

    if ( not abilityDS:IsFullyCastable() ) then
        return BOT_ACTION_DESIRE_NONE, 0;
    end;

    -- Get some of its values
    local nRadius = abilityDS:GetSpecialValueInt( "dragon_slave_width_end" );
    local nCastRange = abilityDS:GetCastRange();
    local nDamage = abilityDS:GetAbilityDamage();
    --print("dragon_slave damage:" .. nDamage);

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    -- If we're farming and can kill 2+ creeps with LSA when we have plenty mana
    local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, 0, nDamage );

    if ( locationAoE.count >= 2 ) then
        return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
    end

    -- If we're pushing or defending a lane and can hit 4+ creeps, go for it
    -- wasting mana banned!
    if npcBot.ShouldPush and ( npcBot:GetMana() / npcBot:GetMaxMana() >= 0.5 ) then
        local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, 0, 0 );

        if ( locationAoE.count >= 5 )
        then
            return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
        end
    end

    -- If we have plenty mana and high level DS
    if(npcBot:GetMana() / npcBot:GetMaxMana() > 0.6 and nDamage > 300) then
        local locationAoE = npcBot:FindAoELocation( true, true, npcBot:GetLocation(), nCastRange, nRadius, 0, 0 );

        -- hit heros
        if locationAoE.count >= 1 then
            return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0;
end


----------------------------------------------------------------------------------------------------

function ConsiderLagunaBlade(abilityLB)

    local npcBot = GetBot();

    -- Make sure it's castable
    if ( not abilityLB:IsFullyCastable() ) then
        return BOT_ACTION_DESIRE_NONE, 0;
    end

    -- Get some of its values
    local nCastRange = abilityLB:GetCastRange();
    local nDamage = abilityLB:GetSpecialValueInt( "damage" );
    local eDamageType = DAMAGE_TYPE_MAGICAL
    if npcBot:HasScepter() then
        eDamageType = DAMAGE_TYPE_PURE
    end

    -- If a mode has set a target, and we can kill them, do it
    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + 200, true, BOT_MODE_NONE );
    if NearbyEnemyHeroes ~= nil then
        for _,npcEnemy in pairs( NearbyEnemyHeroes ) do
            if CanCastLagunaBladeOnTarget( npcEnemy ) then
                if npcEnemy:GetActualDamage( nDamage, eDamageType ) > npcEnemy:GetHealth() then
                    return BOT_ACTION_DESIRE_MODERATE, npcEnemy
                end
            end
        end
    end

    --[[
    -- If we're in a teamfight, use it on the scariest enemy
    local tableNearbyAttackingAlliedHeroes = npcBot:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK );
    if ( #tableNearbyAttackingAlliedHeroes >= 2 )
    then

        local npcMostDangerousEnemy = nil;
        local nMostDangerousDamage = 0;

        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE );
        for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
        do
            if ( CanCastLagunaBladeOnTarget( npcEnemy ) )
            then
                local nDamage = npcEnemy:GetEstimatedDamageToTarget( false, npcBot, 3.0, DAMAGE_TYPE_ALL );
                if ( nDamage > nMostDangerousDamage )
                then
                    nMostDangerousDamage = nDamage;
                    npcMostDangerousEnemy = npcEnemy;
                end
            end
        end

        if ( npcMostDangerousEnemy ~= nil )
        then
            return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy;
        end
    end
    ]]

    return BOT_ACTION_DESIRE_NONE, 0;

end

for k,v in pairs( ability_usage_lina ) do _G._savedEnv[k] = v end