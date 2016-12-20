
require( GetScriptDirectory().."/global_vars" )
require( GetScriptDirectory().."/fsm" )
--require( GetScriptDirectory().."/locations" )
--require( GetScriptDirectory().."/ability_item_usage_viper" );

local curr_lvl = 0
local prevTime = 0
local prevState = "none";

local StateMachine = {};
StateMachine["State"] 					= fsm.STATE_IDLE;

local SKILL_Q = "viper_poison_attack";
local SKILL_W = "viper_nethertoxin";
local SKILL_E = "viper_corrosive_skin";
local SKILL_R = "viper_viper_strike"; 

-- FIXME: includes "" at talent levels for future easy adds
-- NOTE: "" will need to stay for levels where we can't level anything (e.g. 17)
local BotAbilityPriority = {
	SKILL_Q,    SKILL_W,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_R,    SKILL_W,    SKILL_Q,    SKILL_Q,    "-1",
    SKILL_Q,    SKILL_R,    SKILL_E,    SKILL_E,    "-1",
    SKILL_E,    "-1",       SKILL_R,    "-1",       "-1",
    "-1",       "-1",       "-1",       "-1",       "-1"
};

function ThinkLvlupAbility(bot)

	local sNextAbility = BotAbilityPriority[1];
	
	if sNextAbility ~= "-1" then
		bot:Action_LevelAbility( sNextAbility );
	end
	
	table.remove( BotAbilityPriority, 1 );
end

function Think()
	
    local npcBot = GetBot();
	if ( not npcBot ) then return; end
	
	local checkLevel, newTime = global_vars.TimePassed(prevTime, 1.0);
	if checkLevel then
		local cLvl = global_vars.GetHeroLevel( npcBot );
		if ( cLvl > curr_lvl ) then
			ThinkLvlupAbility(npcBot);
			curr_lvl = curr_lvl + 1;
		end
	end
	
	StateMachine.State = fsm.StateMachine[StateMachine.State](npcBot);
	if ( StateMachine.State == fsm.BOT_SPECIFIC_ATTACK_CREEPS ) then
		StateMachine.State = ConsiderAttackCreeps();
	end

    if(prevState ~= StateMachine.State) then
        print("STATE: "..prevState);
        prevState = StateMachine.State;
    end
end

function ConsiderAttackCreeps()
	local bot = GetBot();
	
    -- there are creeps try to attack them --
    print("ConsiderAttackCreeps");
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
