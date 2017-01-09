-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- Some Functions have been copy/pasted from bot-scripting community members 
--- Including: PLATINUM_DOTA2, lenlrx
-------------------------------------------------------------------------------

U = {}

U.Lanes={[1]=LANE_BOT,[2]=LANE_MID,[3]=LANE_TOP};

U.Locations = {
["TopRune"]= Vector(-1767,1233),
["BotRune"]= Vector(2597,-2014),
["Rosh"]= Vector(-2328,1765),
["RadiantShop"]= Vector(-4739,1263),
["DireShop"]= Vector(4559,-1554),
["BotShop"]= Vector(7253,-4128),
["TopShop"]= Vector(-7236,4444),
["DireAncient"]= Vector(5517,4981),
["RadiantAncient"]= Vector(-5860,-5328),

["RadiantBase"]= Vector(-7200,-6666),
["RBT1"]= Vector(4896,-6140),
["RBT2"]= Vector(-128,-6244),
["RBT3"]= Vector(-3966,-6110),
["RMT1"]= Vector(-1663,-1510),
["RMT2"]= Vector(-3559,-2783),
["RMT3"]= Vector(-4647,-4135),
["RTT1"]= Vector(-6202,1831),
["RTT2"]= Vector(-6157,-860),
["RTT3"]= Vector(-6591,-3397),
["RadiantTopShrine"]= Vector(-4229,1299),
["RadiantBotShrine"]= Vector(622,-2555),
["RadiantBotRune"]= Vector(1276,-4129),
["RadiantTopRune"]= Vector(-4351,200),

["DireBase"]= Vector(7137,6548),
["DBT1"]= Vector(6215,-1639),
["DBT2"]= Vector(6242,400),
["DBT3"]= Vector(-6307,3043),
["DMT1"]= Vector(1002,330),
["DMT2"]= Vector(2477,2114),
["DMT3"]= Vector(4197,3756),
["DTT1"]= Vector(-4714,6016),
["DTT2"]= Vector(0,6020),
["DTT3"]= Vector(3512,5778),
["DireTopShrine"]= Vector(-139,2533),
["DireBotShrine"]= Vector(4173,-1613),
["DireBotRune"]= Vector(3471,295),
["DireTopRune"]= Vector(-2821,4147),

["RadiantEasyAndMedium"]={
Vector(3197,-4647),
Vector(680,-4420),
Vector(-1728,-3928)
},
["RadiantHard"]={
Vector(-780,-3291),
Vector(4527,-4259)
},
["DireEasyAndMedium"]={
Vector(-3082,5169),
Vector(-1617,4056),
Vector(1061,3489)
},
["DireHard"]={
Vector(-382,3572),
Vector(-4377,3825)
}
};

U.SIDE_SHOP_TOP = Vector(-7220,4430);
U.SIDE_SHOP_BOT = Vector(7249,-4113);
U.SECRET_SHOP_RADIANT = Vector(-4472,1328);
U.SECRET_SHOP_DIRE = Vector(4586,-1588);
U.ROSHAN = Vector(-2450, 1880);

function U.GetTowerLocation(side, lane, n) --0 radiant 1 dire
	if (side==0) then
		if (lane==LANE_TOP) then
			if (n==1) then
				return U.Locations["RTT1"];
			elseif (n==2) then
				return U.Locations["RTT2"];
			elseif (n==3) then
				return U.Locations["RTT3"];
			end
		elseif (lane==LANE_MID) then
			if (n==1) then
				return U.Locations["RMT1"];
			elseif (n==2) then
				return U.Locations["RMT2"];
			elseif (n==3) then
				return U.Locations["RMT3"];
			end
		elseif (lane==LANE_BOT) then
			if (n==1) then
				return U.Locations["RBT1"];
			elseif (n==2) then
				return U.Locations["RBT2"];
			elseif (n==3) then
				return U.Locations["RBT3"];
			end
		end
	elseif(side==1) then
		if (lane==LANE_TOP) then
			if (n==1) then
				return U.Locations["DTT1"];
			elseif (n==2) then
				return U.Locations["DTT2"];
			elseif (n==3) then
				return U.Locations["DTT3"];
			end
		elseif (lane==LANE_MID) then
			if (n==1) then
				return U.Locations["DMT1"];
			elseif (n==2) then
				return U.Locations["DMT2"];
			elseif (n==3) then
				return U.Locations["DMT3"];
			end
		elseif (lane==LANE_BOT) then
			if (n==1) then
				return U.Locations["DBT1"];
			elseif (n==2) then
				return U.Locations["DBT2"];
			elseif (n==3) then
				return U.Locations["DBT3"];
			end
		end
	end
	return nil;
end

function U.GetDistance(s, t)
	--print("S1: "..s[1]..", S2: "..s[2].." :: T1: "..t[1]..", T2: "..t[2]);
	return math.sqrt((s[1]-t[1])*(s[1]-t[1]) + (s[2]-t[2])*(s[2]-t[2]));
end

function U.GetHeroName(bot)
	local sName = bot:GetUnitName();
	return string.sub(sName, 15, string.len(sName));
end

function U.Fountain(team)
	if team==TEAM_RADIANT then
		return Vector(-7093,-6542);
	end
	return Vector(7015,6534);
end

function U.NotNilOrDead(unit)
	if unit==nil then
		return false;
	end
	if unit:IsAlive() then
		return true;
	end
	return false;
end

function U.GetOtherTeam()
	if GetTeam()==TEAM_RADIANT then
		return TEAM_DIRE;
	else
		return TEAM_RADIANT;
	end
end

function U.IsFacingLocation(hero, loc, delta)
	
	local face=hero:GetFacing();
	local move = loc - hero:GetLocation();
	
	move = move / (U.GetDistance(Vector(0,0),move));

	local moveAngle=math.atan2(move.y,move.x)/math.pi * 180;

	if moveAngle<0 then
		moveAngle=360+moveAngle;
	end
	local face=(face+360)%360;
	
	if (math.abs(moveAngle-face)<delta or math.abs(moveAngle+360-face)<delta or math.abs(moveAngle-360-face)<delta) then
		return true;
	end
	return false;
end

-- returns a VECTOR() with location being the center point of provided hero array
function U.GetCenter(Heroes)
	if Heroes==nil or #Heroes==0 then
		return nil;
	end
	
	local sum=Vector(0.0,0.0);
	local hn=0.0;
	
	for _,hero in pairs(Heroes) do
		if hero~=nil and hero:IsAlive() then
			sum=sum+hero:GetLocation();
			hn=hn+1;
		end
	end
	return sum/hn;
end

-- returns a VECTOR() with location being the center point of provided creep array
function U.GetCenterOfCreeps(creeps)
	local center=Vector(0,0);
	local n=0.0;
	local meleeW=2;
	if creeps==nil or #creeps==0 then
		return nil;
	end
	
	for _,creep in pairs(creeps) do
		if (string.find(creep:GetUnitName(),"melee")~=nil) then
			center = center + (creep:GetLocation())*meleeW;
			n=n+meleeW;
		else
			n=n+1;
			center = center + creep:GetLocation();
		end
	end
	if n==0 then
		return nil;
	end
	center=center/n;
	
	return center;
end

-- takes a "RANGE", returns hero handle and health value of that hero
-- FIXME - make it handle heroes that went invisible if we have detection
function U.GetWeakestHero(bot, r)
	local EnemyHeroes = bot:GetNearbyHeroes(r, true, BOT_MODE_NONE);
	
	if EnemyHeroes==nil or #EnemyHeroes==0 then
		return nil,10000;
	end
	
	local WeakestHero=nil;
	local LowestHealth=10000;
	
	for _,hero in pairs(EnemyHeroes) do
		if hero~=nil and hero:IsAlive() then
			if hero:GetHealth()<LowestHealth then
				LowestHealth=hero:GetHealth();
				WeakestHero=hero;
			end
		end
	end
	
	return WeakestHero, LowestHealth;
end

-- takes a "RANGE", returns creep handle and health value of that creep
function U.GetWeakestCreep(bot, r)	
	local EnemyCreeps = bot:GetNearbyCreeps(r,true);
	
	if EnemyCreeps==nil or #EnemyCreeps==0 then
		return nil,10000;
	end
	
	local WeakestCreep=nil;
	local LowestHealth=10000;
	
	for _,creep in pairs(EnemyCreeps) do
		if creep~=nil and creep:IsAlive() then
			if creep:GetHealth()<LowestHealth then
				LowestHealth=creep:GetHealth();
				WeakestCreep=creep;
			end
		end
	end
	
	return WeakestCreep, LowestHealth;
end

function U.TimePassed(prevTime, amount)
	if ( (GameTime() - prevTime) > amount ) then
		return true, GameTime();
	else
		return false, GameTime();
	end
end

function U.LevelUp(bot, AbilityPriority)
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end;
	
	local ability = bot:GetAbilityByName(AbilityPriority[1]);
	
	if ( ability == nil ) then
		print( " [" .. bot:GetUnitName() .. "] FAILED AT Leveling " .. AbilityPriority[1] );
		table.remove( AbilityPriority, 1 );
		return;
	end
	
	print( " [" .. bot:GetUnitName() .. "] Contemplating " .. ability:GetName() .. " " .. ability:GetLevel() .. "/" .. ability:GetMaxLevel() );
	if ( ability:CanAbilityBeUpgraded() ) then
		print( "Ability Can Be Upgraded" );
	end
	
	if ( ability:CanAbilityBeUpgraded() and ability:GetLevel() < ability:GetMaxLevel() ) then
		bot:Action_LevelAbility(AbilityPriority[1]);
		print( " [" .. bot:GetUnitName() .. "] Leveling " .. ability:GetName() );
		table.remove( AbilityPriority, 1 );
	end
end

function U.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[U.deepcopy(orig_key)] = U.deepcopy(orig_value)
        end
        setmetatable(copy, U.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function U.clone(org)
	return {unpack(org)}
end

return U;