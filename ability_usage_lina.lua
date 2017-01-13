-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_lina", package.seeall )

local Abilities =	{
	"lina_light_strike_array",
	"lina_dragon_slave",
	"lina_fiery_soul",
	"lina_laguna_blade"
}

local PerformingUltCombo = 0
local comboTarget = nil

function AbilityUsageThink()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
	
	local npcBot = GetBot()
	
	-- Check if we're already using an ability
	if ( npcBot:IsUsingAbility() or npcBot:IsChanneling() ) then return end;

	abilityLSA = npcBot:GetAbilityByName( Abilities[1] );
	abilityDS = npcBot:GetAbilityByName( Abilities[2] );
	abilityLB = npcBot:GetAbilityByName( Abilities[4] );
	
	-- do combo
	if PerformingUltCombo > 0 or ConsiderUltCombo() then
		if comboTarget == nil then comboTarget = UseUltCombo() end
		
		if PerformingUltCombo == 1 and CanCastLightStrikeArrayOnTarget( comboTarget ) then
			npcBot:Action_UseAbilityOnLocation( abilityLSA, comboTarget:GetExtrapolatedLocation(abilityLSA:GetCastPoint()) )
			print ( "Hit them with LSA ..." )
			PerformingUltCombo = 2
			return
		else
			PerformingUltCombo = 0
			comboTarget = nil
			return
		end
		
		if comboTarget == nil or not comboTarget:IsAlive() then
			print ( "They died! or disappeared ???" )
			PerformingUltCombo = 0
			comboTarget = nil
		end
		
		if PerformingUltCombo == 2 and CanCastDragonSlaveOnTarget( comboTarget ) and comboTarget:IsStunned() then
			npcBot:Action_UseAbilityOnLocation( abilityDS, comboTarget:GetLocation() )
			print ( "And Hit them with DS ..." )
			PerformingUltCombo = 3
			return
		else
			PerformingUltCombo = 0
			comboTarget = nil
			return
		end
		
		if PerformingUltCombo == 3 and CanCastLagunaBladeOnTarget( comboTarget ) then
			npcBot:Action_UseAbilityOnEntity( abilityLB, comboTarget )
			print ( "And FINISH THEM with LB!!!!" )
			PerformingUltCombo = 0
			comboTarget = nil
			return
		else
			PerformingUltCombo = 0
			comboTarget = nil
			return
		end
		
		return
	end

	local EnemyHeroes = npcBot:GetNearbyHeroes(1200, true, BOT_MODE_NONE);
	local EnemyCreeps = npcBot:GetNearbyCreeps(1200, true);
	
	if ( #EnemyHeroes == 0 and #EnemyCreeps == 0 ) then return end
	
	-- Consider using each ability
	castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLB);
	castLSADesire, castLSALocation = ConsiderLightStrikeArray(abilityLSA);
	castDSDesire, castDSLocation = ConsiderDragonSlave(abilityDS);

	if castLBDesire > castLSADesire and castLBDesire > castDSDesire then
		npcBot:Action_UseAbilityOnEntity( abilityLB, castLBTarget );
		return;
	end

	if castLSADesire > 0 then
		npcBot:Action_UseAbilityOnLocation( abilityLSA, castLSALocation );
		return;
	end

	if castDSDesire > 0 then
		npcBot:Action_UseAbilityOnLocation( abilityDS, castDSLocation );
		return;
	end
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

function UseUltCombo()
	local npcBot = GetBot()
	
	local WeakestEnemy = nil
	local LowestHP = 10000.0
	
	local aq = npcBot:GetAbilityByName(Abilities[1])
	local aw = npcBot:GetAbilityByName(Abilities[2])
	local ar = npcBot:GetAbilityByName(Abilities[4])
	
	local nCastRange = aw:GetCastRange()
	local nRadius = abilityLSA:GetSpecialValueInt( "light_strike_array_aoe" )
	
	local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + nRadius, true, BOT_MODE_NONE )
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
		if npcEnemy ~= nil and npcEnemy:IsAlive() then	
			if LowestHP > npcEnemy:GetHealth() and npcEnemy:GetHealth() > 0 then
				WeakestEnemy = npcEnemy
				LowestHP = npcEnemy:GetHealth()
			end
		end
	end
	
	if WeakestEnemy == nil or LowestHP < 1 then
		return;
	end
	
	local comboDmg = WeakestEnemy:GetActualDamage( aw:GetAbilityDamage(), aw:GetDamageType() )
	comboDmg = comboDmg + WeakestEnemy:GetActualDamage( aq:GetAbilityDamage(), aq:GetDamageType() )
	local arDT = ar:GetDamageType()
	if npcBot:HasScepter() then arDT = DAMAGE_TYPE_PURE end
	comboDmg = comboDmg + WeakestEnemy:GetActualDamage( ar:GetAbilityDamage(), arDT )
	
	if LowestHP < comboDmg then
		print( "Lina Comboing for ", WeakestEnemy:GetUnitName() )
		PerformingUltCombo = 1
		return WeakestEnemy
	end
end

function ConsiderUltCombo()
	local npcBot = GetBot()
	
	if PerformingUltCombo > 0 then PerformingUltCombo = 0 end
	
	local aq = npcBot:GetAbilityByName(Abilities[1]);
	local aw = npcBot:GetAbilityByName(Abilities[2]);
	local ar = npcBot:GetAbilityByName(Abilities[4]);
	
	if aq:GetLevel() < 1 or aw:GetLevel() < 1 or ar:GetLevel() < 1 then
		return false
	end
	
	if not ( aq:IsFullyCastable() and aw:IsFullyCastable() and ar:IsFullyCastable() ) then
		return false
	end
	
	if ( aq:GetManaCost() + aw:GetManaCost() + ar:GetManaCost() ) > npcBot:GetMana() then
		return false
	end
	
	return true;
end

function ConsiderLightStrikeArrayFighting(abilityLSA, enemy)
    local npcBot = GetBot();

	if not abilityLSA:IsFullyCastable() then 
		return BOT_ACTION_DESIRE_NONE, 0;
	end;

	local nCastRange = abilityLSA:GetCastRange();

	local EnemyLocation = enemy:GetExtrapolatedLocation(abilityLSA:GetCastPoint())

	local d = GetUnitToLocationDistance(npcBot,EnemyLocation);

	if d < nCastRange and CanCastLightStrikeArrayOnTarget( enemy ) then
		return BOT_ACTION_DESIRE_MODERATE, EnemyLocation;
	end
	return BOT_ACTION_DESIRE_NONE, 0;
end


function ConsiderLightStrikeArray(abilityLSA)

	local npcBot = GetBot();

	-- Make sure it's castable
	if ( not abilityLSA:IsFullyCastable() ) 
	then 
		return BOT_ACTION_DESIRE_NONE, 0;
	end;


	-- Get some of its values
	local nRadius = abilityLSA:GetSpecialValueInt( "light_strike_array_aoe" );
	local nCastRange = abilityLSA:GetCastRange();
	local nDamage = abilityLSA:GetAbilityDamage();

	--------------------------------------
	-- Global high-priorty usage
	--------------------------------------

	-- Check for a channeling enemy
	local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + nRadius + 200, true, BOT_MODE_NONE );
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
		if npcEnemy:IsChanneling() then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetExtrapolatedLocation(abilityLSA:GetCastPoint());
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
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if ( npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) ) 
		then
			if ( CanCastLightStrikeArrayOnTarget( npcEnemy ) ) 
			then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetExtrapolatedLocation(abilityLSA:GetCastPoint());
			end
		end
	end

	-- If we're going after someone
	local npcTarget = npcBot:GetTarget();

	if ( npcTarget ~= nil ) then
		if ( CanCastLightStrikeArrayOnTarget( npcTarget ) ) then
			return BOT_ACTION_DESIRE_HIGH, npcTarget:GetExtrapolatedLocation(abilityLSA:GetCastPoint());
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0;
end

----------------------------------------------------------------------------------------------------

function ConsiderDragonSlaveFighting(abilityDS,enemy)
    local npcBot = GetBot();

    if ( not abilityDS:IsFullyCastable() ) then 
		return BOT_ACTION_DESIRE_NONE, 0;
	end;

	local nCastRange = abilityDS:GetCastRange();

	local d = GetUnitToUnitDistance(npcBot,enemy);

	if(d < nCastRange and CanCastDragonSlaveOnTarget(enemy))then
		return BOT_ACTION_DESIRE_MODERATE, enemy:GetExtrapolatedLocation(abilityDS:GetCastPoint());
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

	-- If we're going after someone
	local npcTarget = npcBot:GetTarget();

	if npcTarget ~= nil then
		if CanCastDragonSlaveOnTarget( npcTarget ) then
			return BOT_ACTION_DESIRE_MODERATE, npcTarget:GetExtrapolatedLocation(abilityDS:GetCastPoint());
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
					return BOT_ACTION_DESIRE_HIGH, npcEnemy;
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