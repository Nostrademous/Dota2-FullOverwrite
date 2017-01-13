-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

U = {}

U.lastCourierThink = -1000.0
U.creeps = nil
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

U.RadiantSafeSpots={
	Vector(4088,-3919),
	Vector(5153,-3784),
	Vector(2810,-5053),
	Vector(2645,-3814),
	Vector(724,-3003),
	Vector(1037,-5629),
	Vector(1271,-4128),
	Vector(-989,-5559),
	Vector(-780,-3919),
	Vector(-128,-2523),
	Vector(-2640,-2200),
	Vector(-1284,-962),
	Vector(-2032,364),
	Vector(-3545,-892),
	Vector(-5518,-1450),
	Vector(-4301,377),
	Vector(-5483,1633),
	Vector(-6152,-5664),
	Vector(-6622,-3666),
	Vector(-6413,-1651),
	Vector(-4814,-4242),
	Vector(-3379,-3073),
	Vector(-4283,-6091),
	Vector(-2441,-6056),
	Vector(5722,-2602),
	Vector(4595,-1540)
}

U.DireSafeSpots={
	Vector(-1912,2412),
	Vector(-4405,4735),
	Vector(-2840,4194),
	Vector(-1319,4735),
	Vector(-980,3330),
	Vector(776,4229),
	Vector(11,2405),
	Vector(324,670),
	Vector(1480,1760),
	Vector(2236,3217),
	Vector(3079,1812),
	Vector(1958,-116),
	Vector(3375,242),
	Vector(3636,-1023),
	Vector(4957,1812),
	Vector(4914,434),
	Vector(5487,-1729),
	Vector(6026,5585),
	Vector(6339,3631),
	Vector(6113,1782),
	Vector(4653,4154),
	Vector(3219,2916),
	Vector(4070,5821),
	Vector(2036,5637),
	Vector(-3715,2246)
}

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

function U.VectorTowards(s,t,d)
	local f=t-s;
	f=f / U.GetDistance(f,Vector(0,0));
	return s+(f*d);
end

function U.GetHeroName(bot)
	local sName = bot:GetUnitName();
	return string.sub(sName, 15, string.len(sName));
end

function U.IsCore(hero)
	if hero.Role == constants.ROLE_HARDCARRY 
		or hero.Role == constants.ROLE_MID
		or hero.Role == constants.ROLE_OFFLANE then
		return true;
	end
	return false;
end

function U.IsMelee(hero)
	--NOTE: Monkey King is considered Melee with a range of 300, typical melee heroes are range 150
	if hero:GetAttackRange() < 320.0 then return true end
	return false
end

function U.PartyChat(msg)
	local bot = GetBot()
	bot:Action_Chat(msg, false)
end

function U.AllChat(msg)
	local bot = GetBot()
	bot:Action_Chat(msg, true)
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

function U.PositionAlongLane(npcBot, lane)
	local bestPos=0.0;
	local pos=0.0;
	local closest=0.0;
	local dis=20000.0;
	
	while (pos<1.0) do
		local thisPos = GetLocationAlongLane(lane, pos);
		if (U.GetDistance(thisPos,npcBot:GetLocation()) < dis) then
			dis=U.GetDistance(thisPos,npcBot:GetLocation());
			bestPos=pos;
		end
		pos = pos+0.01;
	end
	
	return bestPos;
end

function U.MoveSafelyToLocation(npcBot, dest)
	if npcBot.NextHop==nil or #(npcBot.NextHop)==0 or npcBot.PathfindingWasInitiated==nil or (not npcBot.PathfindingWasInitiated) then
		--print(npcBot.NextHop,npcBot.PathfindingWasInitiated);
		U.InitPathFinding(npcBot);
		npcBot:Action_Chat("Path finding has been initiated", false);
	end
	
	local safeSpots=nil;
	local safeDist=2000;
	if dest==nil then
		print("PathFinding: No destination was specified");
		return;
	end

	if GetTeam()==TEAM_RADIANT then
		safeSpots=U.RadiantSafeSpots;
	else
		safeSpots=U.DireSafeSpots;
	end
	
	if npcBot.FinalHop==nil then
		npcBot.FinalHop=false;
	end
	
	
	local s=nil;
	local si=-1;
	local mindisS=100000;
	
	local t=nil;
	local ti=-1;
	local mindisT=100000;
	
	local CurLoc=npcBot:GetLocation();
	
	for i,spot in pairs(safeSpots) do
		if U.GetDistance(spot,CurLoc)<mindisS then
			s=spot;
			si=i;
			mindisS=U.GetDistance(spot,CurLoc);
		end
		
		if U.GetDistance(spot,dest)<mindisT then
			t=spot;
			ti=i;
			mindisT=U.GetDistance(spot,dest);
		end
	end
	
	if s==nil or t==nil then
		npcBot:Action_Chat('Something is wrong with path finding.',true);
		return;
	end
	
	if GetUnitToLocationDistance(npcBot,dest)<safeDist or npcBot.FinalHop or mindisS+mindisT>GetUnitToLocationDistance(npcBot,dest) then
		npcBot:Action_MoveToLocation(dest);
		npcBot.FinalHop=true;
		return;
	end
	
	if si==ti then
		npcBot.FinalHop=true;
		npcBot:Action_MoveToLocation(dest);
		return;
	end
	
	if GetUnitToLocationDistance(npcBot,s)<500 and npcBot.LastHop==nil then
		npcBot.LastHop=si;
	end
	
	if mindisS>safeDist or npcBot.LastHop==nil then
		npcBot:Action_MoveToLocation(s);
		return;
	end
	
	if GetUnitToLocationDistance(npcBot,safeSpots[npcBot.NextHop[npcBot.LastHop][ti]])<500 then
		npcBot.LastHop=npcBot.NextHop[npcBot.LastHop][ti];
	end
	
	local newT=npcBot.NextHop[npcBot.LastHop][ti];
	
	npcBot:Action_MoveToLocation(safeSpots[newT]);
end

function U.IsHeroAttackingMe(hero, fTime)
	if (hero == nil) or (not hero:IsAlive()) then return false end
	
	local fTime = fTime or 2.0
	local npcBot = GetBot()
	
	if npcBot:WasRecentlyDamagedByAnyHero(hero, fTime) then
		return true
	end
	return false
end

function U.IsAnyHeroAttackingMe(fTime)
	local fTime = fTime or 2.0
	local npcBot = GetBot()
	
	if npcBot:WasRecentlyDamagedByAnyHero(fTime) then
		return true
	end
	return false
end

function U.IsTowerAttackingMe(fTime)
	local fTime = fTime or 2.0
	local npcBot = GetBot()
	
	if npcBot:WasRecentlyDamagedByTower(fTime) then
		return true
	end
	return false
end

function U.IsCreepAttackingMe(fTime)
	local fTime = fTime or 2.0
	local npcBot = GetBot()
	
	if npcBot:WasRecentlyDamagedByCreep(fTime) then
		return true
	end
	return false
end

function U.IsInLane()
	local npcBot = GetBot()
	
	local mindis = 10000
	npcBot.RetreatLane = npcBot.CurLane
	npcBot.RetreatPos = npcBot.LanePos
	
	for i=1,3,1 do
		local thisl = U.PositionAlongLane(npcBot, U.Lanes[i])
		local thisdis = U.GetDistance(GetLocationAlongLane(U.Lanes[i], thisl), npcBot:GetLocation())
		if thisdis < mindis then
			npcBot.RetreatLane = U.Lanes[i]
			npcBot.RetreatPos = thisl
			mindis = thisdis
		end
	end
	
	if mindis > 1500 then
		npcBot.IsInLane = false
	else
		npcBot.IsInLane = true
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

function U.CreepGC()
    -- does it works? i don't know
    --print("CreepGC");
    local swp_table = {}
    for handle,time_health in pairs(self["creeps"])
    do
        local rm = false;
        for t,_ in pairs(time_health)
        do
            if(GameTime() - t > 60) then
                rm = true;
            end
            break;
        end
        if not rm then
            swp_table[handle] = time_health;
        end
    end

    U.creeps = swp_table;
end

function U.UpdateCreepHealth(creep)
    if U.creeps == nil then
        U.creeps = {};
    end

    if(U.creeps[creep] == nil) then
        U.creeps[creep] = {};
    end
    if(creep:GetHealth() < creep:GetMaxHealth()) then
        U.creeps[creep][GameTime()] = creep:GetHealth();
    end

    if(#U.creeps > 1000) then
        self:CreepGC();
    end
end

local function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0                 -- iterator variable
    local iter = function ()    -- iterator function
       i = i + 1
       if a[i] == nil then return nil
       else return a[i], t[a[i]]
       end
    end
    return iter
end

local function sortFunc(a , b)
    if a < b then 
        return true
    end
end

function U.GetCreepHealthDeltaPerSec(creep)
    if U.creeps == nil then
        U.creeps = {};
    end

    if(U.creeps[creep] == nil) then
        return 10000000;
    else
        for _time,_health in pairsByKeys(U.creeps[creep],sortFunc)
        do
            -- only Consider very recent datas
            if(GameTime() - _time < 3) then
                local e = (_health - creep:GetHealth()) / (GameTime() - _time);
                return e;
            end
        end
        return 10000000;
    end

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
function U.GetWeakestCreep(creeps)	
	local WeakestCreep=nil;
	local LowestHealth=10000;
	
	for _,creep in pairs(creeps) do
		U.UpdateCreepHealth(creep)
		if creep:IsAlive() then
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

function U.InitPathFinding(npcBot)

	-- keeps the path for my pathfinding
	npcBot.NextHop={};
	npcBot.PathfindingWasInitiated=false;
	-- creating the graph

	local SafeDist=2000;
	local safeSpots={};
	if GetTeam()==TEAM_RADIANT then
		safeSpots=U.RadiantSafeSpots;
	else
		safeSpots=U.DireSafeSpots;
	end
	
	
	--initialization
	local inf=100000;
	local dist={};
	npcBot.NextHop={}
	
	print("Inits are done");
	for u,uv in pairs(safeSpots) do
		local q=true;
		dist[u]={};
		npcBot.NextHop[u]={};
		for v,vv in pairs(safeSpots) do
			if U.GetDistance(uv,vv)>SafeDist then
				dist[u][v]=inf;
			else
				q=false;
				dist[u][v]=U.GetDistance(uv,vv);
			end
			npcBot.NextHop[u][v]=v;
		end
		if q then
			print("There is an isolated vertex in safespots");
		end
	end
	
	--floyd algorithm (path is saved in NextHop)
	for k,_ in pairs(safeSpots) do
		for u,_ in pairs(safeSpots) do
			for v,_ in pairs(safeSpots) do
				if dist[u][v]>dist[u][k]+dist[k][v] then
					dist[u][v]=dist[u][k]+dist[k][v];
					npcBot.NextHop[u][v]=npcBot.NextHop[u][k];
				end
			end
		end
	end

	npcBot.PathfindingWasInitiated=true;
end

function U.InitPath(npcBot)
	npcBot.FinalHop=false;
	npcBot.LastHop=nil;
end

function U.IsItemAvailable(item_name)
    local npcBot = GetBot();

	local item = U.HaveItem(npcBot, item_name)
	if item ~= nil then
		if item:IsFullyCastable() then
			return item
		end
	end
    return nil;
end

--important items for delivery
function U.HasImportantItem()
	 local npcBot = GetBot();

    for i = 9, 14, 1 do
        local item = npcBot:GetItemInSlot(i);
		if item ~= nil then
			if string.find(item:GetName(),"recipe") ~= nil or string.find(item:GetName(),"item_boots") ~= nil or string.find(item:GetName(),"item_bottle") then
				return true;
			end
			
			if(item:GetName()=="item_ward_observer" and item:GetCurrentCharges() > 1) then
				return true;
			end
		end
    end
	
    return false;
end

function U.CourierThink(npcBot)
	local checkLevel, newTime = U.TimePassed(U.lastCourierThink, 1.0);
	
	if not checkLevel then return end
	U.lastCourierThink = newTime
	
	if npcBot:IsAlive() and (npcBot:GetStashValue() > 500 or npcBot:GetCourierValue() > 0 or U.HasImportantItem()) and IsCourierAvailable() then
		--print("got item");
		npcBot:Action_CourierDeliver();
		return;
	end
end

function U.NumberOfItems(bot)
	local n = 0;
	
	for i = 0, 5, 1 do
        local item = bot:GetItemInSlot(i);
		if item ~= nil then
			n = n+1;
		end
    end
	
	return n;
end

function U.NumberOfItemsInBackpack(bot)
	local n = 0;
	
	for i = 6, 8, 1 do
        local item = bot:GetItemInSlot(i);
		if item ~= nil then
			n = n+1;
		end
    end
	
	return n;
end

function U.NumberOfItemsInStash(bot)
	if bot:GetStashValue() == 0 then return 0 end
	
	local n = 0;
	
	for i = 9, 14, 1 do
        local item = bot:GetItemInSlot(i);
		if item ~= nil then
			n = n+1;
		end
    end
	
	return n;
end

function U.HaveItem(npcBot, item_name)
    local slot = npcBot:FindItemSlot(item_name)
	if slot >= 0 then
		local slot_type = npcBot:GetItemSlotType(slot)
		if slot_type == ITEM_SLOT_TYPE_MAIN then
			return npcBot:GetItemInSlot(slot);
		elseif slot_type == ITEM_SLOT_TYPE_BACKPACK then
			print("FIXME: Implement swapping BACKPACK to MAIN INVENTORY of item: ", item_name);
			return nil;
		elseif slot_type == ITEM_SLOT_TYPE_STASH then
			if npcBot:HasModifier("modifier_fountain_aura") then
				print("FIXME: Implement swapping STASH to MAIN INVENTORY of item: ", item_name);
			end
			return nil;
		else
			print("ERROR: condition should not be hit: ", item_name);
		end
	end
	
    return nil;
end

function U.MoveItemsFromStashToInventory(bot)
	if NumberOfItemsInStash == 0 then return end
	
	local invSpaces = 6 - U.NumberOfItems(bot)
	for i = 9, 14, 1 do
		local item = bot:GetItemInSlot(i)
		if item ~= nil then
			if invSpaces == 0 then break end
			bot:Action_SwapItems(i, 6-invSpaces)
			invSpaces = invSpaces - 1
		end
	end
	
	local backSpaces = 3 - U.NumberOfItemsInBackpack(bot)
	for i = 9, 14, 1 do
		local item = bot:GetItemInSlot(i)
		if item ~= nil then
			if backSpaces == 0 then break end
			bot:Action_SwapItems(i, 9-backSpaces)
			backSpaces = backSpaces - 1
		end
	end
end

function U.HaveTeleportation(npcBot)
	if U.GetHeroName(npcBot) == "furion" then
		return true
	end

	if U.HaveItem(npcBot, "item_tpscroll") ~= nil 
		or U.HaveItem(npcBot, "item_travel_boots_1") ~= nil
		or U.HaveItem(npcBot, "item_travel_boots_2") ~= nil then
		return true
	end
	return false
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