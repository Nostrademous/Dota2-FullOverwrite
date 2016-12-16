
----------------------------------------------------------------------------------------------------


local function AbilityUsageThink()

	local npcBot = GetBot();

	local LocationMetaTable = getmetatable(npcBot:GetLocation());

    --[[
    for k,v in pairs(LocationMetaTable)
	do
	    print(k);
	end
	print("---------------------");
    
	--[[
	Length2D
	unm
	Dot
	Normalized
	Length
	Cross
	mul
	newindex
	len
	add
	eq
	sub
	div
	tostring
	index
	--]]

	--print(npcBot:GetLocation()[1].." " .. npcBot:GetLocation()[2])
	--]]

	local LocationAlongLaneMetatable = getmetatable(GetLocationAlongLane(3,2));

    for k,v in pairs(LocationAlongLaneMetatable)
	do
	    print(k);
	end
	print(GetLocationAlongLane(2,10));
	print("---------------------");

	

	-- Check if we're already using an ability
	if ( npcBot:IsUsingAbility() ) then return end;

	abilityLSA = npcBot:GetAbilityByName( "lina_light_strike_array" );
	abilityDS = npcBot:GetAbilityByName( "lina_dragon_slave" );
	abilityLB = npcBot:GetAbilityByName( "lina_laguna_blade" );

	-- Consider using each ability
	castLBDesire, castLBTarget = ConsiderLagunaBlade();
	castLSADesire, castLSALocation = ConsiderLightStrikeArray();
	castDSDesire, castDSLocation = ConsiderDragonSlave();

	if ( castLBDesire > castLSADesire and castLBDesire > castDSDesire ) 
	then
		npcBot:Action_UseAbilityOnEntity( abilityLB, castLBTarget );
		return;
	end

	if ( castLSADesire > 0 ) 
	then
		npcBot:Action_UseAbilityOnLocation( abilityLSA, castLSALocation );
		return;
	end

	if ( castDSDesire > 0 ) 
	then
		npcBot:Action_UseAbilityOnLocation( abilityDS, castDSLocation );
		return;
	end

	middle_point = npcBot:GetLocation();
	middle_point[1] = 0.0;
	middle_point[2] = 0.0;


	npcBot:Action_AttackMove(middle_point);
	

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

function ConsiderLightStrikeArrayFighting(abilityLSA,enemy)
    local npcBot = GetBot();

	if ( not abilityLSA:IsFullyCastable() ) 
	then 
		return BOT_ACTION_DESIRE_NONE, 0;
	end;

	local nCastRange = abilityLSA:GetCastRange();

	local EnemyLocation = predictPosition(enemy,1);

	local d = GetUnitToLocationDistance(npcBot,EnemyLocation);

	if (d < nCastRange and CanCastLightStrikeArrayOnTarget( enemy ) ) 
	then
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
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if ( npcEnemy:IsChanneling() ) 
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation();
		end
	end

	--------------------------------------
	-- Mode based usage
	--------------------------------------

	-- If we're farming and can kill 3+ creeps with LSA
	if (true) then
		local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, 0, nDamage );

		if ( locationAoE.count >= 3 ) then
			return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
		end
	end

	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if (true ) 
	then
		local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + nRadius + 200, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) ) 
			then
				if ( CanCastLightStrikeArrayOnTarget( npcEnemy ) ) 
				then
					return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetLocation();
				end
			end
		end
	end

	-- If we're going after someone
	if ( true) 
	then
		local npcTarget = npcBot:GetTarget();

		if ( npcTarget ~= nil ) 
		then
			if ( CanCastLightStrikeArrayOnTarget( npcTarget ) )
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget:GetLocation();
			end
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
		return BOT_ACTION_DESIRE_MODERATE, enemy:GetLocation();
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
	if ( true) then
		local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, 0, nDamage );

		if ( locationAoE.count >= 2 ) then
			return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
		end
	end

	-- If we're pushing or defending a lane and can hit 4+ creeps, go for it
	-- wasting mana banned!
	if (false) 
	then
		local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), nCastRange, nRadius, 0, 0 );

		if ( locationAoE.count >= 5 ) 
		then
			return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
		end
	end

	-- If we're going after someone
	if (true) 
	then
		local npcTarget = npcBot:GetTarget();

		if ( npcTarget ~= nil ) 
		then
			if ( CanCastDragonSlaveOnTarget( npcTarget ) )
			then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetLocation();
			end
		end
	end

	-- If we have plenty mana and high level DS
	if(npcBot:GetMana() / npcBot:GetMaxMana() > 0.6 and nDamage > 300) then
        local locationAoE = npcBot:FindAoELocation( true, true, npcBot:GetLocation(), nCastRange, nRadius, 0, 0 );

		-- hit heros
		if ( locationAoE.count >= 1 ) 
		then
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
	local eDamageType = npcBot:HasScepter() and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL;

	-- If a mode has set a target, and we can kill them, do it
	local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + 200, true, BOT_MODE_NONE );
	if(NearbyEnemyHeroes ~= nil) then
	    for _,npcEnemy in pairs( NearbyEnemyHeroes )
		do
			if (CanCastLagunaBladeOnTarget( npcEnemy ) )
			then
				if ( npcEnemy:GetActualDamage( nDamage, eDamageType ) > npcEnemy:GetHealth() )
				then
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

function predictPosition(hero,t)
    -- prediction by hero:GetVelocity(); is not good
    local ret = hero:GetLocation();
	local v = hero:GetVelocity();
	ret[1] = ret[1] + t * v[1];
	ret[2] = ret[2] + t * v[2];
	return hero:GetLocation();
end