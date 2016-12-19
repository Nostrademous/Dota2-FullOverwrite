--[[
    StateMachine is a table
    the key "STATE" stores the STATE of Lina 
    other key value pairs: key is the string of state value is the function of the State. 

    each frame DOTA2 will call Think()
    Then Think() will call the function of current state.
]]

require( GetScriptDirectory().."/global_vars" )
require( GetScriptDirectory().."/locations" )
require( GetScriptDirectory().."/ability_item_usage_lina" );

STATE_IDLE = "STATE_IDLE";
STATE_ATTACKING_CREEP = "STATE_ATTACKING_CREEP";
STATE_KILL = "STATE_KILL";
STATE_RETREAT = "STATE_RETREAT";
STATE_FARMING = "STATE_FARMING";
STATE_GOTO_COMFORT_POINT = "STATE_GOTO_COMFORT_POINT";
STATE_FIGHTING = "STATE_FIGHTING";
STATE_RUN_AWAY = "STATE_RUN_AWAY";

LinaRetreatHPThreshold = 0.3;
LinaRetreatMPThreshold = 0.2;

local curr_lvl = 0

STATE = STATE_IDLE;

function StateIdle(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000, true);
    local pt = GetComfortPoint(creeps);

    local ShouldFight = false;

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(npcBot:WasRecentlyDamagedByHero(npcEnemy,1)) then
                -- got the enemy who attacks me, kill him!--
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            elseif(GetUnitToUnitDistance(npcBot,npcEnemy) < 500) then
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            end
        end
    end

    if( ShouldRetreat() ) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif( IsTowerAttackingMe() ) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    elseif( npcBot:GetAttackTarget() ~= nil ) then
        if( npcBot:GetAttackTarget():IsHero() ) then
            EnemyToKill = npcBot:GetAttackTarget();
            --print("auto attacking: "..npcBot:GetAttackTarget():GetUnitName());
            StateMachine.State = STATE_FIGHTING;
            return;
        end
    elseif( ShouldFight ) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif( #creeps > 0 and pt ~= nil ) then
        local mypos = npcBot:GetLocation();
        
        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 200) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
        return;
    end

    target = GetLocationAlongLane(2, 0.95);
    npcBot:Action_AttackMove(target);
    

end

function StateAttackingCreep(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000,true);
    local pt = GetComfortPoint(creeps);

    local ShouldFight = false;

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(npcBot:WasRecentlyDamagedByHero(npcEnemy,1)) then
                -- got the enemy who attacks me, kill him!--
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            elseif(GetUnitToUnitDistance(npcBot,npcEnemy) < 500) then
                EnemyToKill = npcEnemy;
                ShouldFight = true;
                break;
            end
        end
    end


    if( ShouldRetreat() ) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif( IsTowerAttackingMe() ) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif( ShouldFight ) then
        StateMachine.State = STATE_FIGHTING;
        return;
    elseif( #creeps > 0 and pt ~= nil ) then
        local mypos = npcBot:GetLocation();
        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 200) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            ConsiderAttackCreeps();
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end
end

function StateRetreat(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    home_pos = locations.RAD_FOUNTAIN;
	if ( GetTeam() == TEAM_DIRE ) then
		home_pos = locations.DIRE_FOUNTAIN;
	end
	
    npcBot:Action_MoveToLocation(home_pos);

    if(npcBot:GetHealth() == npcBot:GetMaxHealth() and npcBot:GetMana() == npcBot:GetMaxMana()) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end

function StateGotoComfortPoint(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000, true);
    local pt = GetComfortPoint(creeps);

    if( ShouldRetreat() ) then
        StateMachine.State = STATE_RETREAT;
        return;
    elseif( IsTowerAttackingMe() ) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif( #creeps > 0 and pt ~= nil ) then
        local mypos = npcBot:GetLocation();
        
        local d = GetUnitToLocationDistance(npcBot,pt);
        if(d > 200) then
            --print("mypos "..mypos[1]..mypos[2]);
            --print("comfort_pt "..pt[1]..pt[2]);
            npcBot:Action_MoveToLocation(pt);
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end

end

function StateFighting(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    if(IsTowerAttackingMe() and npcBot:GetHealth() < EnemyToKill:GetHealth()) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif(not EnemyToKill:CanBeSeen() or not EnemyToKill:IsAlive()) then
        -- lost enemy 
        print("lost enemy");
        StateMachine.State = STATE_IDLE;
        return;
    else
        if ( npcBot:IsUsingAbility() ) then return end;

        local abilityLSA = npcBot:GetAbilityByName( "lina_light_strike_array" );
        local abilityDS = npcBot:GetAbilityByName( "lina_dragon_slave" );
        local abilityLB = npcBot:GetAbilityByName( "lina_laguna_blade" );

        -- Consider using each ability
        
        local castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLB);
        local castLSADesire, castLSALocation = ConsiderLightStrikeArrayFighting(abilityLSA,EnemyToKill);
        local castDSDesire, castDSLocation = ConsiderDragonSlaveFighting(abilityDS,EnemyToKill);

        if ( castLBDesire > 0 ) 
        then
            LastEnemyToBeAttacked = nil;
            npcBot:Action_UseAbilityOnEntity( abilityLB, castLBTarget );
            return;
        end

        if ( castLSADesire > 0 ) 
        then
            LastEnemyToBeAttacked = nil;
            npcBot:Action_UseAbilityOnLocation( abilityLSA, castLSALocation );
            return;
        end

        if ( castDSDesire > 0 ) 
        then
            LastEnemyToBeAttacked = nil;
            npcBot:Action_UseAbilityOnLocation( abilityDS, castDSLocation );
            return;
        end

        if(not abilityLSA:IsFullyCastable() and 
        not abilityDS:IsFullyCastable() or EnemyToKill:IsMagicImmune()) then
            local extraHP = 0;
            if(abilityLB:IsFullyCastable()) then
                local LBnDamage = abilityLB:GetSpecialValueInt( "damage" );
                local LBeDamageType = npcBot:HasScepter() and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL;
                extraHP = EnemyToKill:GetActualDamage(LBnDamage,LBeDamageType);
            end

            if(EnemyToKill:GetHealth() - extraHP > npcBot:GetHealth()) then
                StateMachine.State = STATE_RUN_AWAY;
                return;
            end
        end


        if(npcBot:GetAttackTarget() ~= EnemyToKill) then
            npcBot:Action_AttackUnit(EnemyToKill,false);
        end

    end
end

function StateRunAway(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        TargetOfRunAwayFromTower = nil;
        return;
    end

    if(ShouldRetreat()) then
        StateMachine.State = STATE_RETREAT;
        TargetOfRunAwayFromTower = nil;
        return;
    end

    local mypos = npcBot:GetLocation();

    if(TargetOfRunAwayFromTower == nil) then
        --set the target to go back
        TargetOfRunAwayFromTower = Vector(mypos[1] - 400,mypos[2] - 400);
        npcBot:Action_MoveToLocation(TargetOfRunAwayFromTower);
        return;
    else
        if(GetUnitToLocationDistance(npcBot,TargetOfRunAwayFromTower) < 100) then
            -- we are far enough from tower,return to normal state.
            TargetOfRunAwayFromTower = nil;
            StateMachine.State = STATE_IDLE;
            return;
        end
    end
end 

StateMachine = {};
StateMachine["State"] = STATE_IDLE;
StateMachine[STATE_IDLE] = StateIdle;
StateMachine[STATE_ATTACKING_CREEP] = StateAttackingCreep;
StateMachine[STATE_RETREAT] = StateRetreat;
StateMachine[STATE_GOTO_COMFORT_POINT] = StateGotoComfortPoint;
StateMachine[STATE_FIGHTING] = StateFighting;
StateMachine[STATE_RUN_AWAY] = StateRunAway;

local SKILL_Q = "lina_dragon_slave";
local SKILL_W = "lina_light_strike_array";
local SKILL_E = "lina_fiery_soul";
local SKILL_R = "lina_laguna_blade"; 

-- FIXME: includes "" at talent levels for future easy adds
-- NOTE: "" will need to stay for levels where we can't level anything (e.g. 17)
local BotAbilityPriority = {
	SKILL_Q,    SKILL_E,    SKILL_Q,    SKILL_W,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    "-1",
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    "-1",
    SKILL_W,    "-1",       SKILL_R,    "-1",       "-1",
    "-1",       "-1",       "-1",       "-1",       "-1"
};

function ThinkLvlupAbility(bot)

	local sNextAbility = BotAbilityPriority[1];
	
	if sNextAbility ~= "-1" then
		bot:Action_LevelAbility( sNextAbility );
	end
	
	table.remove( BotAbilityPriority, 1 );
end

PrevState = "none";

local prevTime = 0

function Think()
	--[[
	rt = RealTime();
	if ( rt ) then print( "RT: ", rt ); end
	dt = DotaTime();
	if ( dt ) then print( "DT: ", dt ); end
	gt = GameTime();
	if ( gt ) then print( "GT: ", gt ); end
	--]]
	
    -- Think this item( ... )
    --update
    local npcBot = GetBot();
    --print(GetLocationAlongLane(2,0.9));
	
	local checkLevel, newTime = global_vars.TimePassed(prevTime, 1.0);
	if checkLevel then
		prevTime = newTime;
		local cLvl = global_vars.GetHeroLevel( npcBot );
		if ( cLvl > curr_lvl ) then
			ThinkLvlupAbility(npcBot);
			curr_lvl = curr_lvl + 1;
		end
	end
	
    StateMachine[StateMachine.State](StateMachine);

    if(PrevState ~= StateMachine.State) then
        print("STATE: "..StateMachine.State);
        PrevState = StateMachine.State;
    end
	
end

function ConsiderAttackCreeps()
    -- there are creeps try to attack them --
    --print("ConsiderAttackCreeps");
    local npcBot = GetBot();

    local EnemyCreeps = npcBot:GetNearbyCreeps(1000, true);
    local AllyCreeps = npcBot:GetNearbyCreeps(1000, false);

    -- Check if we're already using an ability
	if ( npcBot:IsUsingAbility() ) then return end;

    local abilityLSA = npcBot:GetAbilityByName( "lina_light_strike_array" );
	local abilityDS = npcBot:GetAbilityByName( "lina_dragon_slave" );
	local abilityLB = npcBot:GetAbilityByName( "lina_laguna_blade" );

    -- Consider using each ability
    
	local castLBDesire, castLBTarget = ConsiderLagunaBlade(abilityLB);
	local castLSADesire, castLSALocation = ConsiderLightStrikeArray(abilityLSA);
	local castDSDesire, castDSLocation = ConsiderDragonSlave(abilityDS);

    if ( castLBDesire > castLSADesire and castLBDesire > castDSDesire ) 
	then
        LastEnemyToBeAttacked = nil;
		npcBot:Action_UseAbilityOnEntity( abilityLB, castLBTarget );
		return;
	end

	if ( castLSADesire > 0 ) 
	then
        LastEnemyToBeAttacked = nil;
		npcBot:Action_UseAbilityOnLocation( abilityLSA, castLSALocation );
		return;
	end

	if ( castDSDesire > 0 ) 
	then
        LastEnemyToBeAttacked = nil;
		npcBot:Action_UseAbilityOnLocation( abilityDS, castDSLocation );
		return;
	end

    --print("desires: " .. castLBDesire .. " " .. castLSADesire .. " " .. castDSDesire);

    --If we dont cast ability, just try to last hit.

    local lowest_hp = 100000;
    local weakest_creep = nil;
    for creep_k,creep in pairs(EnemyCreeps)
    do 
        --npcBot:GetEstimatedDamageToTarget
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
		expectedDmg = 1.7*npcBot:GetEstimatedDamageToTarget(false, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL);
		--print( "Dmg: ", npcBot:GetEstimatedDamageToTarget(false, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL) );
        if(npcBot:GetAttackTarget() == nil and lowest_hp < expectedDmg ) then
            npcBot:Action_AttackUnit(weakest_creep, false);
            StateMachine.State = STATE_ATTACKING_CREEP;
            return;
        end
        weakest_creep = nil;
        
    end

    for creep_k,creep in pairs(AllyCreeps)
    do 
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
		expectedDmg = 1.7*npcBot:GetEstimatedDamageToTarget(false, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL);
		--print( "Dmg: ", npcBot:GetEstimatedDamageToTarget(false, weakest_creep, 1.0, DAMAGE_TYPE_PHYSICAL) );
        if( npcBot:GetAttackTarget() == nil and 
        lowest_hp < expectedDmg or 
        (lowest_hp > expectedDmg and (weakest_creep:GetHealth() / weakest_creep:GetMaxHealth()) < 0.5)) then
            Attacking_creep = weakest_creep;
            npcBot:Action_AttackUnit(Attacking_creep, false);
            StateMachine.State = STATE_ATTACKING_CREEP;
            return;
        end
        weakest_creep = nil;
        
    end

    -- nothing to do , try to attack heros
    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes ) do
            if(npcBot:GetAttackTarget() == nil) then
                npcBot:Action_AttackUnit(npcEnemy, false);
                return;
            end
        end
    end
	
	-- nothing to do , try to attack tower
	local NearbyTowers = npcBot:GetNearbyTowers(1000, true);
    if( #NearbyTowers > 0 and #AllyCreeps > 0 ) then
        for _,tower in pairs( NearbyTowers) do
             if(npcBot:GetAttackTarget() == nil) then
                npcBot:Action_AttackUnit(tower, false);
                print("Attacking tower");
                return;
            end
        end
    end
    
end

function GetComfortPoint(creeps)
    local npcBot = GetBot();
    local mypos = npcBot:GetLocation();
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
        return Vector(avg_pos_x - 600 / 1.414, avg_pos_y - 600 / 1.414);
    else
        return nil;
    end;
end


function TryToUpgradeAbility(AbilityName)
    local npcBot = GetBot();
    local ability = npcBot:GetAbilityByName(AbilityName);
    if ability:CanAbilityBeUpgraded() then
        ability:UpgradeAbility();
        return true;
    end
    return false;
end

-- How to get iTree handles?
function IsItemAvailable(item_name)
    local npcBot = GetBot();
    -- query item code by Hewdraw
    for i = 0, 5, 1 do
        local item = npcBot:GetItemInSlot(i);
        if(item and item:IsFullyCastable() and item:GetName() == item_name) then
            return item;
        end
    end
    return nil;
end

function ShouldRetreat()
    local npcBot = GetBot();
    return npcBot:GetHealth()/npcBot:GetMaxHealth() 
    < LinaRetreatHPThreshold or npcBot:GetMana()/npcBot:GetMaxMana() 
    < LinaRetreatMPThreshold;
end

function IsTowerAttackingMe()
    local npcBot = GetBot();
    local NearbyTowers = npcBot:GetNearbyTowers(1000, true);
    if(#NearbyTowers > 0) then
        for _,tower in pairs( NearbyTowers)
        do
            if(GetUnitToUnitDistance(tower,npcBot) < 900) then
                print("Attacked by tower");
                return true;
            end
        end
    else
        return false;
    end
end