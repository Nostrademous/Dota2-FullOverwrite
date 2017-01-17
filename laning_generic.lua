-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

-------
_G._savedEnv = getfenv()
module( "laning_generic", package.seeall )
----------
local utils = require( GetScriptDirectory().."/utility")
----------

local CurLane = nil;
local EyeRange=1200;
local BaseDamage=50;
local AttackRange=150;
local AttackSpeed=0.6;
local LastTiltTime=0.0;

local DamageThreshold=1.0;
local MoveThreshold=1.0;

local BackTimerGen=-1000;

local ShouldPush = false;
local IsCore = nil;
local LanePos = nil;

local LaningStates={
	Start=0,
	Moving=1,
	WaitingForCS=2,
	CSing=3,
	WaitingForCreeps=4,
	MovingToPos=5,
	GetReadyForCS=6,
	GettingBack=7,
	MovingToLane=8
}

local LaningState=LaningStates.Start;

function OnStart(npcBot)
	npcBot.BackTimerGen = -1000;
	
	if not utils.HaveTeleportation(npcBot) then
		if DotaTime()>10 and npcBot:GetGold()>50 and GetUnitToLocationDistance(npcBot,GetLocationAlongLane(npcBot.CurLane,0.0))<700 and utils.NumberOfItems(npcBot)<=5 then
			npcBot:Action_PurchaseItem("item_tpscroll");
			return;
		end
	end
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
		return;
	end
		
	local dest=GetLocationAlongLane(npcBot.CurLane,GetLaneFrontAmount(GetTeam(),npcBot.CurLane,true)-0.04);
	if GetUnitToLocationDistance(npcBot,dest)>1500 then
		utils.InitPath(npcBot);
		npcBot.LaningState=LaningStates.MovingToLane;
	end
	
	--print(utils.GetHeroName(npcBot), " LANING OnStart Done")
end

-------------------------------

local function MovingToLane(npcBot)
	local dest = GetLocationAlongLane(npcBot.CurLane,GetLaneFrontAmount(GetTeam(), npcBot.CurLane, true) - 0.04);
	
	if GetUnitToLocationDistance(npcBot, dest) < 300 then
		LaningState = LaningStates.Moving;
		return;
	end
	
	utils.MoveSafelyToLocation(dest);
end

local function Start(npcBot)
	if CurLane ~= LANE_MID then
		npcBot:Action_MoveToLocation(GetLocationAlongLane(CurLane,0.17));
	else
		npcBot:Action_MoveToLocation(GetLocationAlongLane(CurLane,0.25));
	end
	local AllyCreeps = npcBot:GetNearbyCreeps(EyeRange,false);
	if (#AllyCreeps > 0) then
		LaningState = LaningStates.Moving
	end
end

local function Moving(npcBot)
	local frontier = GetLaneFrontAmount(GetTeam(), CurLane, true)
	
	local towerRange = 900.0
	local EnemyTowers = npcBot:GetNearbyTowers(towerRange, true)
	local noTower = true
	if #EnemyTowers > 0 and GetUnitToLocationDistance(npcBot, EnemyTowers[1]:GetLocation()) > towerRange then
		noTower = false
	end

	if frontier >= LanePos and (noTower or ShouldPush) then
		local target = GetLocationAlongLane(CurLane,Min(1.0,LanePos+0.03));---
		--print( " Going Forward :: MyLoc: ", npcBot:GetLocation()[1], ",", npcBot:GetLocation()[2], " TARGET: ", target[1], ",", target[2])
		npcBot:Action_MoveToLocation(target);
	else
		local target = GetLocationAlongLane(CurLane,Min(1.0,LanePos-0.03));---
		npcBot:Action_MoveToLocation(target);
	end
	
	local EnemyCreeps = npcBot:GetNearbyCreeps(EyeRange,true);
	
	local nCr = 0;
	
	for _,creep in pairs(EnemyCreeps) do
		if utils.NotNilOrDead(creep) and (string.find(creep:GetUnitName(),"melee")~=nil or string.find(creep:GetUnitName(),"range")~=nil or string.find(creep:GetUnitName(),"siege")~=nil) then
			nCr=nCr+1;
		end
	end
	
	if nCr > 0 then
		LaningState = LaningStates.MovingToPos;
	end
end

local function MovingToPos(npcBot)	
	local EnemyCreeps = npcBot:GetNearbyCreeps(EyeRange,true);
	
	local cpos = GetLaneFrontLocation(utils.GetOtherTeam(),CurLane,0.0);
	local bpos = GetLocationAlongLane(CurLane,LanePos-0.02);
	
	local dest = utils.VectorTowards(cpos, bpos, 550);
	if utils.IsMelee(npcBot) then
		dest = utils.VectorTowards(cpos, bpos, 250);
	end
	
	local rndtilt = RandomVector(150);
	
	dest = dest+rndtilt;
	
	npcBot:Action_MoveToLocation(dest);
	
	LaningState = LaningStates.CSing;
end

local function GetReadyForCS(npcBot)
end

local function WaitingForCS(npcBot)
end

local function GettingBack(npcBot)	
	local AllyCreeps = npcBot:GetNearbyCreeps(EyeRange,false);
	local AllyTowers = npcBot:GetNearbyTowers(EyeRange,false);
	
	if #AllyCreeps > 0 or LanePos < 0.18 then
		LaningState = LaningStates.Moving;
		return;
	end
	
	npcBot:Action_MoveToLocation(GetLocationAlongLane(CurLane,Max(LanePos-0.03,0.0)));
end

local function DenyNearbyCreeps(npcBot)

	local AllyCreeps = npcBot:GetNearbyCreeps(EyeRange,false);
	if AllyCreeps==nil or #AllyCreeps==0 then
		return false;
	end
	
	local WeakestCreep, WeakestCreepHealth = utils.GetWeakestCreep(AllyCreeps);
	
	if WeakestCreep == nil then
		return false;
	end

	AttackRange = npcBot:GetAttackRange() + npcBot:GetBoundingRadius();

	local eDamage = npcBot:GetEstimatedDamageToTarget(true, WeakestCreep, npcBot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL)
	if utils.IsMelee(npcBot) then
		damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (npcBot:GetAttackPoint() / (1 + npcBot:GetAttackSpeed()))
	else
		damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (npcBot:GetAttackPoint() / (1 + npcBot:GetAttackSpeed()) + GetUnitToUnitDistance(npcBot,WeakestCreep) / 1100)
	end
	
	if WeakestCreep ~= nil and damage > WeakestCreep:GetMaxHealth() then
		-- this occasionally will happen when a creep gets nuked by a target or AOE ability and takes
		-- a large amount of damage so it has a huge health drop delta, in that case just use eDamage
		damage = eDamage
	end
	
	if damage > WeakestCreep:GetHealth() and utils.GetDistance(npcBot:GetLocation(),WeakestCreep:GetLocation()) < AttackRange then
		npcBot:Action_AttackUnit(WeakestCreep,true);
		return true;
	end
	
	local approachScalar = 2.0
	if utils.IsMelee(npcBot) then
		approachScalar = 2.5
	end
	
	if WeakestCreepHealth < approachScalar*damage and utils.GetDistance(npcBot:GetLocation(),WeakestCreep:GetLocation()) > npcBot:GetAttackRange() then
		local dest = utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(CurLane,LanePos-0.03), AttackRange - 20 );
		npcBot:Action_MoveToLocation(dest);
		return true;
	end

	return false;
end

local function DenyCreeps(npcBot)

	local AllyCreeps = npcBot:GetNearbyCreeps(EyeRange,false);
	if AllyCreeps==nil or #AllyCreeps==0 then
		return false;
	end
	
	local WeakestCreep, WeakestCreepHealth = utils.GetWeakestCreep(AllyCreeps);
	
	if WeakestCreep==nil then
		return false;
	end

	AttackRange = npcBot:GetAttackRange() + npcBot:GetBoundingRadius();
	
	local eDamage = npcBot:GetEstimatedDamageToTarget(true, WeakestCreep, npcBot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL) 
	if utils.IsMelee(npcBot) then
		damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (npcBot:GetAttackPoint() / (1 + npcBot:GetAttackSpeed()))
	else
		damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (npcBot:GetAttackPoint() / (1 + npcBot:GetAttackSpeed()) + GetUnitToUnitDistance(npcBot,WeakestCreep) / 1100)
	end
	
	if WeakestCreep ~= nil and damage > WeakestCreep:GetMaxHealth() then
		-- this occasionally will happen when a creep gets nuked by a target or AOE ability and takes
		-- a large amount of damage so it has a huge health drop delta, in that case just use eDamage
		damage = eDamage
	end
		
	if damage > WeakestCreepHealth and utils.GetDistance(npcBot:GetLocation(),WeakestCreep:GetLocation()) < AttackRange then
		npcBot:Action_AttackUnit(WeakestCreep, true);
		return true;
	end
	
	local approachScalar = 2.0
	if utils.IsMelee(npcBot) then
		approachScalar = 2.5
	end
	
	if WeakestCreepHealth < approachScalar*damage and utils.GetDistance(npcBot:GetLocation(),WeakestCreep:GetLocation()) > AttackRange() then
		local dest=utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(CurLane,LanePos-0.03),AttackRange-20);
		
		npcBot:Action_MoveToLocation(dest);
		return true;
	end

	return false;
end

local function PushCS(npcBot, WeakestCreep, nAc, damage, AS)
	
	--[[
	if WeakestCreep:GetHealth() > damage and WeakestCreep:GetHealth() < (damage + 17*nAc*AS) and nAc>1 then
		return;
	end
	--]]
	
	npcBot:Action_AttackUnit(WeakestCreep, false);
end

local function CSing(npcBot)

	local AllyCreeps = npcBot:GetNearbyCreeps(EyeRange,false);
	local EnemyCreeps = npcBot:GetNearbyCreeps(EyeRange,true);
	
	if (AllyCreeps==nil) or (#AllyCreeps==0) then
		LaningState = LaningStates.GettingBack;
		return;
	end
	
	if (EnemyCreeps==nil) or (#EnemyCreeps==0) then
		LaningState = LaningStates.Moving;
		return;
	end	
	
	AttackRange = npcBot:GetAttackRange() + npcBot:GetBoundingRadius();
	AttackSpeed = npcBot:GetAttackPoint();
	
	local AlliedHeroes = npcBot:GetNearbyHeroes(EyeRange,false,BOT_MODE_NONE);
	local Enemies = npcBot:GetNearbyHeroes(EyeRange,true,BOT_MODE_NONE);
	
	local NoCoreAround = true;
	for _,hero in pairs(AlliedHeroes) do
		if utils.IsCore(hero) then
			NoCoreAround = false;
		end
	end
	
	if ShouldPush and (#Enemies > 0 or DotaTime() < (60*3)) then
		ShouldPush = false
	end

	if IsCore or (NoCoreAround and (Enemies == nil or #Enemies < 2)) then
		local WeakestCreep, WeakestCreepHealth = utils.GetWeakestCreep(EnemyCreeps);
		
		if WeakestCreep == nil then return end
		
		local nAc=0;
		if WeakestCreep ~= nil then
			for _,acreep in pairs(AllyCreeps) do
				if utils.NotNilOrDead(acreep) and GetUnitToUnitDistance(acreep,WeakestCreep) < 120 then
					nAc = nAc + 1;
				end
			end
		end
		
		local eDamage = npcBot:GetEstimatedDamageToTarget(true, WeakestCreep, npcBot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL) 
		if utils.IsMelee(npcBot) then
			damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (npcBot:GetAttackPoint() / (1 + npcBot:GetAttackSpeed()))
		else
			damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (npcBot:GetAttackPoint() / (1 + npcBot:GetAttackSpeed()) + GetUnitToUnitDistance(npcBot,WeakestCreep) / 1100)
		end
		
		if WeakestCreep ~= nil and damage > WeakestCreep:GetMaxHealth() then
			-- this occasionally will happen when a creep gets nuked by a target or AOE ability and takes
			-- a large amount of damage so it has a huge health drop delta, in that case just use eDamage
			damage = eDamage
		end
		
		if WeakestCreep ~= nil and WeakestCreepHealth < damage then
			npcBot:Action_AttackUnit(WeakestCreep, true);
			return;
		end
		
		if ShouldPush and WeakestCreep ~= nil then
			PushCS(npcBot, WeakestCreep, nAc, damage, AttackSpeed);
			return;
		end
		
		local approachScalar = 2.0
		if utils.IsMelee(npcBot) then
			approachScalar = 2.5
		end
		
		if (not ShouldPush) and WeakestCreepHealth < damage*approachScalar and GetUnitToUnitDistance(npcBot,WeakestCreep) > AttackRange then
			local dest = utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(CurLane,LanePos-0.03),AttackRange-20);
			npcBot:Action_MoveToLocation(dest);
			return;
		end
	
		if not ShouldPush then
			if DenyNearbyCreeps(npcBot) then
				return;
			end
		end
	elseif not NoCoreAround then
		-- we are not a Core, we are not pushing, deny only
		if not ShouldPush then
			if DenyCreeps(npcBot) then
				return;
			end
		end
	end
	
	LaningState = LaningStates.MovingToPos;
end

local function WaitingForCreeps(npcBot)
end

--------------------------------

local States = {
[LaningStates.Start]=Start,
[LaningStates.Moving]=Moving,
[LaningStates.WaitingForCS]=WaitingForCS,
[LaningStates.CSing]=CSing,
[LaningStates.MovingToPos]=MovingToPos,
[LaningStates.WaitingForCreeps]=WaitingForCreeps,
[LaningStates.GetReadyForCS]=GetReadyForCS,
[LaningStates.GettingBack]=GettingBack,
[LaningStates.MovingToLane]=MovingToLane
}

----------------------------------

local function Updates(npcBot)
	CurLane = npcBot.CurLane;
	LanePos = utils.PositionAlongLane(npcBot, CurLane);
	
	if npcBot.IsCore == nil then
		IsCore = utils.IsCore(npcBot);
	else
		IsCore = npcBot.IsCore;
	end
	
	if npcBot.LaningState ~= nil then
		LaningState = npcBot.LaningState;
	end
	
	if npcBot.MoveThreshold ~= nil then
		MoveThreshold = npcBot.MoveThreshold;
	end
	
	if npcBot.DamageThreshold ~= nil then
		DamageThreshold=npcBot.DamageThreshold;
	end
	
	if npcBot.ShouldPush ~= nil then
		ShouldPush = npcBot.ShouldPush;
	end
	
	if ( not npcBot:IsAlive() ) or ( LanePos < 0.15 and LaningState ~= LaningStates.Start ) then
		LaningState=LaningStates.Moving;
	end
end

local function GetBackGen(npcBot)
	if npcBot.BackTimerGen == nil then
		npcBot.BackTimerGen = -1000
		return false
	end
	
	if DotaTime() - npcBot.BackTimerGen < 1 then
		return true
	end
	
	local EnemyDamage = 0
	local Enemies = npcBot:GetNearbyHeroes(EyeRange,true,BOT_MODE_NONE)
	if Enemies==nil or #Enemies==0 then
		return false;
	end
	
	local AllyTowers=npcBot:GetNearbyTowers(600,false);
	if AllyTowers~=nil and #AllyTowers>0 and (#Enemies==nil or #Enemies<=3) then
		return false;
	end
	
	for _,enemy in pairs(Enemies) do
		if utils.NotNilOrDead(enemy) then
			local damage = enemy:GetEstimatedDamageToTarget(true,npcBot,4,DAMAGE_TYPE_ALL);
			EnemyDamage = EnemyDamage+damage;
		end
	end
	
	if EnemyDamage*0.7 > npcBot:GetHealth() then
		npcBot.BackTimerGen = DotaTime();
		return true;
	end
	
	if EnemyDamage > npcBot:GetHealth() and utils.IsAnyHeroAttackingMe(2.0) then
		npcBot.BackTimerGen = DotaTime();
		return true;
	end
	
	EnemyDamage=0;
	local TotStun=0;
	
	for _,enemy in pairs(Enemies) do
		if utils.NotNilOrDead(enemy) then
			TotStun = TotStun + Min(enemy:GetStunDuration(true)*0.85 + enemy:GetSlowDuration(true)*0.5,3);
		end
	end
	
	for _,enemy in pairs(Enemies) do
		if utils.NotNilOrDead(enemy) then
			local damage = enemy:GetEstimatedDamageToTarget(true,npcBot,TotStun,DAMAGE_TYPE_ALL);
			EnemyDamage = EnemyDamage+damage;
		end
	end
	
	if EnemyDamage > npcBot:GetHealth() then
		npcBot.BackTimerGen = DotaTime();
		return true;
	end
	
	npcBot.BackTimerGen = -1000;
	return false;
end

local function StayBack(npcBot)	
	local LaneFront = GetLaneFrontAmount(GetTeam(), npcBot.CurLane, true);
	-- FIXME: we need to Min or Max depending on Team the LaneFrontAmount() with furthest standing tower
	local LaneEnemyFront = 1.0 - GetLaneFrontAmount(utils.GetOtherTeam(), npcBot.CurLane, false);
	
	local BackPos = GetLocationAlongLane(npcBot.CurLane,Min(LaneFront-0.05,LaneEnemyFront-0.05)) + RandomVector(200);
	npcBot:Action_MoveToLocation(BackPos);
end

function Think(npcBot)
	Updates(npcBot);
	
	if npcBot:IsUsingAbility() or npcBot:IsChanneling() then
		return;
	end
	
	if GetBackGen(npcBot) and LaningState ~= LaningStates.MovingToLane then
		StayBack(npcBot);
		return;
	end
	
	--print(utils.GetHeroName(npcBot), " LaningState: ", LaningState);
	
	States[LaningState](npcBot);
	
	npcBot.LaningState = LaningState;
end


--------
for k,v in pairs( laning_generic ) do _G._savedEnv[k] = v end
