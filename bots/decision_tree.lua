
require( GetScriptDirectory().."/locations" )

ACTION_RETREAT 		= "ACTION_RETREAT";

local X = {} --{ ActionQueue = {} }

local RetreatHPThreshold = 0.2
local RetreatMPThreshold = 0.2

local prevAction = "NONE";

function X:ActionTransition()
	--[[
	if ( ( #X:ActionQueue > 0 and prevAction ~= X:ActionQueue[1] )or ( #X:ActionQueue == 0 and prevAction ~= "NONE" ) ) then
		local sAction = "NONE";
		if ( #X:ActionQueue > 0 ) then
			sAction = X:ActionQueue[1];
		end
		print( "Action Transition: " .. prevAction .. " --> " .. sAction );
	end
	--]]
end

function X:AddAction(action)
	--[[
	for _,v in pairs(X:ActionQueue) do
		if v == action then
			return;
		end
	end
	table.insert(X:ActionQueue, action);
	--]]
end

function X:RemoveAction(action)
	--if X:ActionQueue[1] == action then
		--	table.remove(X:ActionQueue, 1);
	--end
end

function X:Think(bot)
	X:ActionTransition();

	--AM I ALIVE
    if( bot:IsAlive() == false ) then
		print( "You are dead, nothing to do!!!");
	end
	
	--AM I CHANNELING AN ABILITY/ITEM (i.e. TP Scroll, Ultimate, etc.)
	if ( bot:IsUsingAbility() ) then return end;
	
	--AM I LOW HEALTH/MANA
	if ( X:ShouldRetreat(bot) ) then
		X:Retreat(bot);
	end
	
	--LOGIC TO DECIDE IF I AM ABOUT TO BE GANKED
	
	--GET CREEPS WITHIN 1000 UNIT RANGE
	local EnemyCreeps = bot:GetNearbyCreeps(1000, true);
	local AllyCreeps = bot:GetNearbyCreeps(1000, false);
	
	--LOGIC TO DECIDE IF I AM BEING ATTACKED
	--BY ENEMY HERO
	--BY TOWER
	bTowerAttacked, tower = X:IsTowerAttackingMe(bot);
	if ( bTowerAttacked and tower ~= nil ) then
		X:RunAwayFromTower(bot, tower);
		return;
	end
	--BY CREEPS
	
	--ARE ENEMY CREEPS AROUND WITHOUT FRIENDLY CREEPS PRESENT - PULL BACK UNLESS PUSHING
	
	--ARE ENEMY CREEPS AROUND (NOT ATTACKING ME) - FARM
	if( #EnemyCreeps > 0 and #AllyCreeps > 0 ) then
		local mypos = bot:GetLocation();
		local enemy_crp, enemy_crp_health = X:GetWeakestCreep(EnemyCreeps);
		
		if ( enemy_crp ~= nil ) then
			local d = GetUnitToLocationDistance(bot, enemy_crp:GetLocation());
			if( d > bot:GetAttackRange() ) then
				bot:Action_MoveToLocation(enemy_crp:GetLocation());
				return;
			else
				if ( X:ConsiderAttackCreep(bot, enemy_crp, enemy_crp_health) ) then return end;
			end
		end
	end
	
	--ARE FRIENDLY CREEPS AROUND (ENGAGED WITH ENEMY CREEPS) - DENY
	
	--We should go somewhere
	--LOGIC TO DECIDE WHERE TO GO
	
	--ATTACK MOVE THERE
	
	--DEFAULT ACTION - MOVE DOWN MIDDLE TO ENEMY RAX
	local target_loc = GetLocationAlongLane(2, 0.95);
	--print( "Moving to Location: " .. target_loc[1] .. ", " .. target_loc[2] );
    bot:Action_AttackMove(target_loc);
end

function X:Retreat(bot)
	local target_loc = locations.RAD_FOUNTAIN;
	if ( GetTeam() == TEAM_DIRE ) then 
		target_loc = locations.DIRE_FOUNTAIN;
	end
	bot:Action_MoveToLocation(target_loc);
	
	if(bot:GetHealth() == bot:GetMaxHealth() and bot:GetMana() == bot:GetMaxMana()) then
		X:RemoveAction(ACTION_RETREAT);
    end
end

function X:ConsiderAttackCreep(bot, creep, creep_health)
	if(creep ~= nil) then
		expectedDmg = 2.0*bot:GetEstimatedDamageToTarget(false, creep, 1.0, DAMAGE_TYPE_PHYSICAL);
		--print( "Dmg: ", bot:GetEstimatedDamageToTarget(false, creep, 1.0, DAMAGE_TYPE_PHYSICAL) );
		if(bot:GetAttackTarget() == nil and creep_health < expectedDmg ) then
			bot:Action_AttackUnit(creep, false);
			return true;
		end
		weakest_creep = nil;
	end
	return false;
end

function X:GetWeakestCreep(creeps)
    local lowest_hp = 100000;
    local weakest_creep = nil;
    for creep_k,creep in pairs(creeps)
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
	return weakest_creep, lowest_hp
end

function X:IsTowerAttackingMe(bot)
    local NearbyTowers = bot:GetNearbyTowers(1000, true);
	if(#NearbyTowers > 0) then
		for _,tower in pairs( NearbyTowers ) do
			if(GetUnitToUnitDistance(tower, bot) < 900 ) then
				print("Attacked by tower");
				return true, tower;
			end
		end
	end
	return false, nil;
end

function X:RunAwayFromTower(bot, tower)
	local mypos = bot:GetLocation();
	if ( GetTeam() == TEAM_RADIANT ) then
		TargetOfRunAwayFromTower = Vector(mypos[1] - 400, mypos[2] - 400);
	else
		TargetOfRunAwayFromTower = Vector(mypos[1] + 400, mypos[2] + 400);
	end
	bot:Action_MoveToLocation(TargetOfRunAwayFromTower);
end

function X:ShouldRetreat(bot)
    local bRetreat = (bot:GetHealth()/bot:GetMaxHealth() < RetreatHPThreshold) or (bot:GetMana()/bot:GetMaxMana() < RetreatMPThreshold);
	if ( bRetreat ) then
		X:AddAction(ACTION_RETREAT);
	end
	return bRetreat;
end

return X