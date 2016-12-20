_G._savedEnv = getfenv()
module( "fsm", package.seeall )
----------------------------------------------------------------------------------------------------

require( GetScriptDirectory().."/locations" )

STATE_IDLE 					= "STATE_IDLE";
STATE_ATTACKING_CREEP 		= "STATE_ATTACKING_CREEP";
STATE_ATTACKING_TOWER 		= "STATE_ATTACKING_TOWER";
STATE_KILL 					= "STATE_KILL";
STATE_RETREAT 				= "STATE_RETREAT";
STATE_GOTO_COMFORT_POINT 	= "STATE_GOTO_COMFORT_POINT";
STATE_FIGHTING 				= "STATE_FIGHTING";
STATE_RUN_AWAY 				= "STATE_RUN_AWAY";

BOT_SPECIFIC_ATTACK_CREEPS 	= "BOT_SPECIFIC :: ATTACK_CREEPS";

StateMachine = {};
StateMachine["State"] 					= STATE_IDLE;
StateMachine[STATE_IDLE] 				= StateIdle;
StateMachine[STATE_ATTACKING_CREEP] 	= StateAttackingCreep;
StateMachine[STATE_ATTACKING_TOWER] 	= StateAttackingTower;
StateMachine[STATE_RETREAT] 			= StateRetreat;
StateMachine[STATE_GOTO_COMFORT_POINT] 	= StateGotoComfortPoint;
StateMachine[STATE_FIGHTING] 			= StateFighting;
StateMachine[STATE_RUN_AWAY] 			= StateRunAway;

RetreatHPThreshold = 0.3;
RetreatMPThreshold = 0.2;

function StateIdle(bot)
    if(bot:IsAlive() == false) then
        return STATE_IDLE;
    end

    local creeps = bot:GetNearbyCreeps(1000, true);
    local pt = GetComfortPoint(creeps, bot);

    local ShouldFight = false;

    local NearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes ) do
            if(bot:WasRecentlyDamagedByHero(npcEnemy, 1)) then
                -- got the enemy who attacks me, kill him!--
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            elseif(GetUnitToUnitDistance(bot, npcEnemy) < 500) then
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            end
        end
    end
	
    if( ShouldRetreat(bot) ) then
        return STATE_RETREAT;
    elseif( IsTowerAttackingMe(bot) ) then
        return STATE_RUN_AWAY;
    elseif( bot:GetAttackTarget() ~= nil ) then
        if( bot:GetAttackTarget():IsHero() ) then
            return STATE_FIGHTING;
        end
    elseif( ShouldFight ) then
        return STATE_FIGHTING;
    elseif( #creeps > 0 and pt ~= nil ) then
        local mypos = bot:GetLocation();
        
        local d = GetUnitToLocationDistance(bot, pt);
        if(d > 200) then
            return STATE_GOTO_COMFORT_POINT;
        else
            return STATE_ATTACKING_CREEP;
        end
    end

    target = GetLocationAlongLane(2, 0.55);
    bot:Action_AttackMove(target);
	return STATE_IDLE;
end

function StateAttackingCreep(bot)
    if(bot:IsAlive() == false) then
        return STATE_IDLE;
    end

    local creeps = bot:GetNearbyCreeps(1000,true);
    local pt = GetComfortPoint(creeps, bot);

    local ShouldFight = false;

    local NearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(bot:WasRecentlyDamagedByHero(npcEnemy, 1)) then
                -- got the enemy who attacks me, kill him!--
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            elseif(GetUnitToUnitDistance(bot, npcEnemy) < 500) then
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            end
        end
    end

    if( ShouldRetreat(bot) ) then
        return STATE_RETREAT;
    elseif( IsTowerAttackingMe(bot) ) then
        return STATE_RUN_AWAY;
    elseif( ShouldFight ) then
        return STATE_FIGHTING;
    elseif( #creeps > 0 and pt ~= nil ) then
        local mypos = bot:GetLocation();
        local d = GetUnitToLocationDistance(bot, pt);
        if(d > 200) then
            return STATE_GOTO_COMFORT_POINT;
        else
            return BOT_SPECIFIC_ATTACK_CREEPS; --ConsiderAttackCreeps(bot);
        end
    else
        return STATE_IDLE;
    end
	
	return STATE_ATTACKING_CREEP;
end

function StateAttackingTower(bot)
	if(bot:IsAlive() == false) then
        return STATE_IDLE;
    end
	
	if( ShouldRetreat(bot) ) then
        return STATE_RETREAT;
	end
	
	return STATE_IDLE;
end

function StateRetreat(bot)
    if(bot:IsAlive() == false) then
        return STATE_IDLE;
    end

	locations.GoToFountain(bot);

    if(bot:GetHealth() == bot:GetMaxHealth() and bot:GetMana() == bot:GetMaxMana()) then
        return STATE_IDLE;
    end
	return STATE_RETREAT;
end

function StateGotoComfortPoint(bot)
    if(bot:IsAlive() == false) then
        return STATE_IDLE;
    end

    local creeps = bot:GetNearbyCreeps(1000, true);
    local pt = GetComfortPoint(creeps, bot);

    if( ShouldRetreat(bot) ) then
        return STATE_RETREAT;
    elseif( IsTowerAttackingMe(bot) ) then
        return STATE_RUN_AWAY;
    elseif( #creeps > 0 and pt ~= nil ) then
        local mypos = bot:GetLocation();
        
        local d = GetUnitToLocationDistance(bot, pt);
        if(d > 200) then
            --print("mypos "..mypos[1]..mypos[2]);
            --print("comfort_pt "..pt[1]..pt[2]);
            bot:Action_MoveToLocation(pt);
        else
            return STATE_ATTACKING_CREEP;
        end
    end
	return STATE_GOTO_COMFORT_POINT;
end

function StateFighting(bot)
	return STATE_IDLE;
end

function StateRunAway(bot)
    if(bot:IsAlive() == false) then
        TargetOfRunAwayFromTower = nil;
		return STATE_IDLE;
    end

    if( ShouldRetreat(bot) ) then
		TargetOfRunAwayFromTower = nil;
        return STATE_RETREAT;
    end

    local mypos = bot:GetLocation();

    if(TargetOfRunAwayFromTower == nil) then
        --set the target to go back
		if ( GetTeam() == TEAM_RADIANT ) then
			TargetOfRunAwayFromTower = Vector(mypos[1] - 400,mypos[2] - 400);
		else
			TargetOfRunAwayFromTower = Vector(mypos[1] + 400,mypos[2] + 400);
		end
        bot:Action_MoveToLocation(TargetOfRunAwayFromTower);
        return STATE_RUN_AWAY;
    else
        if(GetUnitToLocationDistance(bot,TargetOfRunAwayFromTower) < 100) then
            -- we are far enough from tower,return to normal state.
            TargetOfRunAwayFromTower = nil;
            return STATE_IDLE;
        end
    end
	return STATE_RUN_AWAY;
end

function GetComfortPoint(creeps, bot)

    local mypos = bot:GetLocation();
    local x_pos_sum = 0;
    local y_pos_sum = 0;
    local count = 0;
    for creep_k,creep in pairs(creeps)
    do
        local creep_name = creep:GetUnitName();
        local meleepos = string.find( creep_name, "melee");
        --if(meleepos ~= nil) then
        if(true) then
            creep_pos = creep:GetLocation();
            x_pos_sum = x_pos_sum + creep_pos[1];
            y_pos_sum = y_pos_sum + creep_pos[2];
            count = count + 1;
        end
    end

    local avg_pos_x = x_pos_sum / count;
    local avg_pos_y = y_pos_sum / count;

    if(count > 0) then
        -- I assume ComfortPoint is 600 from the avg point 
        --print("avg_pos : " .. avg_pos_x .. " , " .. avg_pos_y);
		if ( GetTeam() == TEAM_RADIANT ) then
			return Vector(avg_pos_x - 600 / 1.414, avg_pos_y - 600 / 1.414);
		else
			return Vector(avg_pos_x + 600 / 1.414, avg_pos_y + 600 / 1.414);
		end
    else
        return nil;
    end;
end

function ShouldRetreat(bot)
    return bot:GetHealth()/bot:GetMaxHealth() < RetreatHPThreshold or 
	bot:GetMana()/bot:GetMaxMana() < RetreatMPThreshold;
end

function IsTowerAttackingMe(bot)
    local NearbyTowers = bot:GetNearbyTowers(1000, true);
    if(#NearbyTowers > 0) then
        for _,tower in pairs( NearbyTowers ) do
            if(GetUnitToUnitDistance(tower, bot) < 900 ) then
                print("Attacked by tower");
                return true;
            end
        end
    else
        return false;
    end
end

function ConsiderAttackCreeps(bot)
    -- there are creeps try to attack them --
    --print("ConsiderAttackCreeps");
    local EnemyCreeps = bot:GetNearbyCreeps(1000, true);

    -- Check if we're already using an ability
	if ( bot:IsUsingAbility() ) then return STATE_ATTACKING_CREEP end;

	--[[
    local abilityLSA = bot:GetAbilityByName( "lina_light_strike_array" );
	local abilityDS = bot:GetAbilityByName( "lina_dragon_slave" );
	local abilityLB = bot:GetAbilityByName( "lina_laguna_blade" );

    -- Consider using each ability
    
	local castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLB);
	local castLSADesire, castLSALocation = ConsiderLightStrikeArray(abilityLSA);
	local castDSDesire, castDSLocation = ConsiderDragonSlave(abilityDS);

    if ( castLBDesire > castLSADesire and castLBDesire > castDSDesire ) 
	then
        LastEnemyToBeAttacked = nil;
		bot:Action_UseAbilityOnEntity( abilityLB, castLBTarget );
		return;
	end

	if ( castLSADesire > 0 ) 
	then
        LastEnemyToBeAttacked = nil;
		bot:Action_UseAbilityOnLocation( abilityLSA, castLSALocation );
		return;
	end

	if ( castDSDesire > 0 ) 
	then
        LastEnemyToBeAttacked = nil;
		bot:Action_UseAbilityOnLocation( abilityDS, castDSLocation );
		return;
	end
	
    --print("desires: " .. castLBDesire .. " " .. castLSADesire .. " " .. castDSDesire);
	
	--]]

    --If we dont cast ability, just try to last hit.

    local lowest_hp = 100000;
    local weakest_creep = nil;
    for creep_k,creep in pairs(EnemyCreeps) do 
        --bot:GetEstimatedDamageToTarget
        local creep_name = creep:GetUnitName();
        --print(creep_name);
        if(creep:IsAlive()) then
             local creep_hp = creep:GetHealth();
             if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
             end
         end
    end

    if(weakest_creep ~= nil) then
		expectedDmg = 1.7*bot:GetEstimatedDamageToTarget(false, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL);
		--print( "Dmg: ", bot:GetEstimatedDamageToTarget(false, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL) );
        if(bot:GetAttackTarget() == nil and lowest_hp < expectedDmg ) then
            bot:Action_AttackUnit(weakest_creep, false);
            return STATE_ATTACKING_CREEP;
        end
        weakest_creep = nil;
        
    end

	local AllyCreeps = bot:GetNearbyCreeps(1000, false);
    for creep_k,creep in pairs(AllyCreeps) do 
        local creep_name = creep:GetUnitName();
        if(creep:IsAlive()) then
             local creep_hp = creep:GetHealth();
             if(lowest_hp > creep_hp) then
                 lowest_hp = creep_hp;
                 weakest_creep = creep;
             end
         end
    end

    if(weakest_creep ~= nil) then
		expectedDmg = 1.7*bot:GetEstimatedDamageToTarget(false, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL);
		--print( "Dmg: ", bot:GetEstimatedDamageToTarget(false, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL) );
        if( bot:GetAttackTarget() == nil and 
        lowest_hp < expectedDmg or 
        (lowest_hp > expectedDmg and (weakest_creep:GetHealth() / weakest_creep:GetMaxHealth()) < 0.5)) then
            Attacking_creep = weakest_creep;
            bot:Action_AttackUnit(Attacking_creep, false);
            return STATE_ATTACKING_CREEP;
        end
        weakest_creep = nil; 
    end

    -- nothing to do , try to attack heros
    local NearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes ) do
            if(bot:GetAttackTarget() == nil) then
                bot:Action_AttackUnit(npcEnemy, false);
                return STATE_FIGHTING;
            end
        end
    end
	
	-- nothing to do , try to attack tower
	local NearbyTowers = bot:GetNearbyTowers(1000, true);
    if( #NearbyTowers > 0 and #AllyCreeps > 0 ) then
        for _,tower in pairs( NearbyTowers) do
             if(bot:GetAttackTarget() == nil) then
                bot:Action_AttackUnit(tower, false);
                print("Attacking tower");
                return STATE_ATTACKING_TOWER;
            end
        end
    end
	return STATE_ATTACKING_CREEP;
end

----------------------------------------------------------------------------------------------------
for k,v in pairs( fsm ) do	_G._savedEnv[k] = v end