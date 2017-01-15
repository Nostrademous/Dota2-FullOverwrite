-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
local utils = require( GetScriptDirectory().."/utility" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
require( GetScriptDirectory().."/role" )
require( GetScriptDirectory().."/laning_generic" )
require( GetScriptDirectory().."/jungling_generic" )
require( GetScriptDirectory().."/retreat_generic" )
require( GetScriptDirectory().."/item_usage" )
require( GetScriptDirectory().."/jungle_status" )

local ACTION_NONE		= constants.ACTION_NONE
local ACTION_LANING		= constants.ACTION_LANING
local ACTION_RETREAT 	= constants.ACTION_RETREAT
local ACTION_FIGHT		= constants.ACTION_FIGHT
local ACTION_CHANNELING	= constants.ACTION_CHANNELING
local ACTION_MOVING		= constants.ACTION_MOVING

local X = { currentAction = ACTION_NONE, prevAction = ACTION_NONE, actionQueue = {}, abilityPriority = {} }

function X:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function X:getCurrentAction()
	return self.currentAction
end

function X:setCurrentAction(action)
	self.currentAction = action
end

function X:getPrevAction()
	return self.prevAction
end

function X:setPrevAction(action)
	self.prevAction = action
end

function X:getActionQueue()
	return self.actionQueue
end

function X:getAbilityPriority()
	return self.abilityPriority
end

function X:printInfo()
	print("PrevTime Value: "..self:getPrevTime());
	print("Addr actionQueue Table: ", self:getActionQueue());
	print("Addr abilityPriority Table: ", self:getAbilityPriority());
end

-------------------------------------------------------------------------------
-- ACTION MANAGEMENT - YOU SHOULDN'T NEED TO TOUCH THIS
-------------------------------------------------------------------------------

function X:PrintActionTransition(name)
	self:setCurrentAction(self:GetAction());
	
	if ( self:getCurrentAction() ~= self:getPrevAction() ) then
		print("["..name.."] Action Transition: "..self:getPrevAction().." --> "..self:getCurrentAction());
		self:setPrevAction(self:getCurrentAction());
	end
end

function X:AddAction(action)
	if action == ACTION_NONE then return end;
	
	local k = self:HasAction(action);
	if k then
		table.remove(self:getActionQueue(), k);
	end
	table.insert(self:getActionQueue(), 1, action);
end

function X:HasAction(action)
    for key, value in pairs(self:getActionQueue()) do
        if value == action then return key end
    end
    return false
end

function X:RemoveAction(action)
	
	--print("Removing Action".. action)
	
	if action == ACTION_NONE then return end;
	
	local k = self:HasAction(action);
	if k then
		table.remove(self:getActionQueue(), k);
	end
	
	local a = self:GetAction()
	--print("Next Action".. a)
	
	self:setCurrentAction(a);
end

function X:GetAction()
	if #self:getActionQueue() == 0 then
		return ACTION_NONE;
	end
	return self:getActionQueue()[1];
end

X.prevEnemyDump = -1000.0

function X:setHeroVar(var, value)
	gHeroVar.SetVar(self.pID, var, value)
end

function X:getHeroVar(var)
	return gHeroVar.GetVar(self.pID, var)
end

-------------------------------------------------------------------------------
-- MAIN THINK FUNCTION - DO NOT OVER-LOAD 
-------------------------------------------------------------------------------

function X:Think(bot)
	jungle_status.checkSpawnTimer()

	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end;
	
	if not self.Init then
		self.pID = bot:GetPlayerID() -- do this to reduce calls to bot:GetPlayerID() in the future
		gHeroVar.InitHeroVar(self.pID)
		self:setHeroVar("Name", utils.GetHeroName(bot))
		self:setHeroVar("LastCourierThink", -1000.0)
		self:setHeroVar("LastLevelUpThink", -1000.0)
		
		role.GetRoles()
		if role.RolesFilled() then
			self.Init = true
			
			for i = 1, 5, 1 do
				local hero = GetTeamMember( GetTeam(), i )
				if hero:GetUnitName() == bot:GetUnitName() then
					cLane, cRole = role.GetLaneAndRole(GetTeam(), i)
					self:setHeroVar("CurLane", cLane)
					self:setHeroVar("Role", cRole)
					break
				end
			end
		end
		print( self:getHeroVar("Name"), " initialized - Lane: ", self:getHeroVar("CurLane"), ", Role: ", self:getHeroVar("Role") )
	end
	
	--[[
		FIRST DECISIONS THAT DON'T AFFECT THE MY ACTION STATES
		:: Leveling Up Abilities, Buying Items (in most cases), Using Courier
	--]]
	-- LEVEL UP ABILITIES
	local checkLevel, newTime = utils.TimePassed(self:getHeroVar("LastLevelUpThink"), 2.0);
	if checkLevel then
		self:setHeroVar("LastLevelUpThink", newTime)
		if bot:GetAbilityPoints() > 0 then
			utils.LevelUp(bot, self:getAbilityPriority());
		end
	end

	-- DEBUG NOTIFICATION
	self:setCurrentAction(self:GetAction());
	self:PrintActionTransition(utils.GetHeroName(bot));
	
	---[[
	-- UPDATE GLOBAL INFO --
	--enemyData.UpdateEnemyInfo();
	
	-- DEBUG ENEMY DUMP
	--[[
	checkLevel, newTime = utils.TimePassed(self.prevEnemyDump, 5.0);
	if checkLevel then
		self.prevEnemyDump = newTime;
		enemyData.PrintEnemyInfo();
	end
	--]]
	
	-- NOW DECISIONS THAT MODIFY MY ACTION STATES
	---]]
		
	--AM I ALIVE
    if( not bot:IsAlive() ) then
		--print( "You are dead, nothing to do!!!");
		self:DoWhileDead(bot);
		return;
	end
	
	--AM I CHANNELING AN ABILITY/ITEM (i.e. TP Scroll, Ultimate, etc.)
	if ( bot:IsUsingAbility() or bot:IsChanneling() ) then
		self:DoWhileChanneling(bot);
		return;
	end
	
	-- DETERMINE MY SURROUNDING INFO --
	local RANGE = 1200
	
	--GET HEROES WITHIN XYZ UNIT RANGE
	local EnemyHeroes = bot:GetNearbyHeroes(RANGE, true, BOT_MODE_NONE);
	local AllyHeroes = bot:GetNearbyHeroes(RANGE, false, BOT_MODE_NONE);
	
	--GET TOWERS WITHIN XYZ UNIT RANGE
	local EnemyTowers = bot:GetNearbyTowers(RANGE, true);
	local AllyTowers = bot:GetNearbyTowers(RANGE, false);
	
	--GET CREEPS WITHIN XYZ UNIT RANGE
	local EnemyCreeps = bot:GetNearbyCreeps(RANGE, true);
	local AllyCreeps = bot:GetNearbyCreeps(RANGE, false);
	
	--FIXME: Is this the right place to do this???
	self:ConsiderAbilityUse()
	self:ConsiderItemUse()
	utils.CourierThink(bot)
	
	local safe = self:Determine_AmISafe(bot)
	
	if safe ~= 0 or self:GetAction() == ACTION_RETREAT then
		self:DoRetreat(bot, safe);
		return;
	end
	
	if ( self:Determine_AmIFighting(bot, EnemyHeroes, AllyHeroes) ) then
		self:DoFight(bot);
		return;
	end
	
	if ( self:Determine_DoAlliesNeedHelp(bot, EnemyHeroes, AllyHeroes) ) then
		self:DoDefendAlly(bot);
		return;
	end
	
	if ( self:Determine_ShouldIPushLane(bot, EnemyHeroes, EnemyCreeps, AllyCreeps) ) then
		self:DoPushLane(bot);
		return;
	end
	self:setHeroVar("ShouldPush", false)
	
	if ( self:Determine_ShouldIDefendLane(bot, EnemyHeroes, AllyHeroes, AllyTowers, EnemyCreeps, AllyCreeps) ) then
		self:DoDefendLane(bot);
		return;
	end
	
	if ( self:Determine_ShouldRoam(bot) ) then
		self:DoRoam(bot);
		return;
	end

	if ( self:Determine_ShouldJungle(bot) or self:GetAction() == ACTION_JUNGLING ) then
		self:DoJungle(bot);
		return;
	end
	
	if ( self:Determine_ShouldTeamRoshan(bot, EnemyHeroes, EnemyTowers) ) then
		self:DoRoshan(bot);
		return;
	end
	
	if ( self:Determine_ShouldGetRune(bot) ) then
		self:DoGetRune(bot);
		return;
	end
	
	if ( self:Determine_ShouldWard(bot) ) then
		self:DoWard(bot);
		return;
	end
	
	if ( self:Determine_ShouldLane(bot) or self:GetAction() == ACTION_LANING ) then
		self:DoLane(bot);
		return;
	end
	
	local loc = self:Determine_WhereToMove(bot);
	self:DoMove(bot, loc);
end

-------------------------------------------------------------------------------
-- FUNCTION DEFINITIONS - OVER-LOAD THESE IN HERO LUA IF YOU DESIRE
-------------------------------------------------------------------------------

function X:DoWhileDead(bot)
	self:MoveItemsFromStashToInventory(bot);
	local bb = self:ConsiderBuyback(bot);
	if (bb) then
		bot:Action_Buyback();
	end
end

function X:DoWhileChanneling(bot)
	-- TODO: Check Items like Glimmer Cape for activation if wanted
	return;
end

function X:ConsiderBuyback(bot)
	-- TODO: Write Buyback logic here
	if ( bot:HasBuyback() ) then
		return false; -- FIXME: for now always return false
	end
	return false;
end

function X:ConsiderAbilityUse()
	return;
end

function X:ConsiderItemUse()
	local timeInfo = item_usage.UseItems()
	if timeInfo ~= nil then
		print( "X:ConsiderItemUse() TimeInfo: ", timeInfo )
	end
end

function X:Determine_AmISafe(bot)	
	if bot:GetHealth()/bot:GetMaxHealth() > 0.9 and bot:GetMana()/bot:GetMaxMana() > 0.9 then
		if utils.IsTowerAttackingMe() then return 2 end
		if utils.IsCreepAttackingMe() then return 3 end
		self:setHeroVar("IsRetreating", false)
		return 0;
	end
	
	if bot:GetHealth()/bot:GetMaxHealth() > 0.65 and bot:GetMana()/bot:GetMaxMana() > 0.6 and GetUnitToLocationDistance(bot, GetLocationAlongLane(self:getHeroVar("CurLane"), 0)) > 6000 then
		if utils.IsTowerAttackingMe() then return 2 end
		if utils.IsCreepAttackingMe() then return 3 end
		self:setHeroVar("IsRetreating", false)
		return 0;
	end
	
	if bot:GetHealth()/bot:GetMaxHealth() > 0.8 and bot:GetMana()/bot:GetMaxMana() > 0.36 and GetUnitToLocationDistance(bot, GetLocationAlongLane(self:getHeroVar("CurLane"), 0)) > 6000 then
		if utils.IsTowerAttackingMe() then return 2 end
		if utils.IsCreepAttackingMe() then return 3 end
		self:setHeroVar("IsRetreating", false)
		return 0;
	end
	
	if self:getHeroVar("IsRetreating") ~= nil and self:getHeroVar("IsRetreating") == true then
		return 1;
	end
	
	local Enemies = bot:GetNearbyHeroes(1500, true, BOT_MODE_NONE);
	local Allies = bot:GetNearbyHeroes(1500, false, BOT_MODE_NONE);
	local Towers = bot:GetNearbyTowers(900, true);
	
	local nEn = 0;
	if Enemies ~= nil then
		nEn = #Enemies;
	end
	
	local nAl = 0;

	if Allies ~= nil then
		for _,ally in pairs(Allies) do
			if utils.NotNilOrDead(ally) then
				nAl = nAl + 1;
			end
		end
	end
	
	local nTo = 0;
	if Towers ~= nil then
		nTo = #Towers;
	end
	
	if (bot:GetHealth() < (bot:GetMaxHealth()*0.17*(nEn-nAl+1) + nTo*110)) or ((bot:GetHealth()/bot:GetMaxHealth()) < 0.33) or (bot:GetMana()/bot:GetMaxMana() < 0.07 and self:getPrevAction() == ACTION_LANING) then
		self:setHeroVar("IsRetreating", true)
		return 1;
	end
	
	if Allies == nil or #Allies < 2 then
		local MaxStun = 0;
		
		for _,enemy in pairs(Enemies) do
			if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth()>0.4 then
				MaxStun = Max(MaxStun, Max(enemy:GetStunDuration(true) , enemy:GetSlowDuration(true)/1.5) );
			end
		end
	
		local enemyDamage=0;
		for _,enemy in pairs(Enemies) do
			if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.4 then
				local damage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_ALL);
				enemyDamage = enemyDamage + damage;
			end
		end
		
		if 0.6*enemyDamage > bot:GetHealth() then
			self:setHeroVar("IsRetreating", true)
			return 1;
		end
	end
	
	if utils.IsTowerAttackingMe() then
		return 2
	end
	if utils.IsCreepAttackingMe() then
		return 3
	end
	
	self:setHeroVar("IsRetreating", false)
	return 0;
end

function X:Determine_AmIFighting(bot, EnemyHeroes, AllyHeroes)
	return false;
end

function X:Determine_DoAlliesNeedHelp(bot, EnemyHeroes, AllyHeroes)
	return false;
end

function X:Determine_ShouldIPushLane(bot, EnemyHeroes, EnemyCreeps, AllyCreeps)
	local EnemyTowers = bot:GetNearbyTowers(900, true)
	if EnemyTowers == nil or #EnemyTowers == 0 then 
		return false 
	end
		
	if #AllyCreeps >= #EnemyCreeps and #EnemyHeroes == 0 then
		local NearAC = 0
		for _,creep in pairs(AllyCreeps) do
			if GetUnitToUnitDistance(creep, EnemyTowers[1]) < 800 then
				NearAC = NearAC + 1
			end
		end
		
		if NearAC > 0 then
			--print(utils.GetHeroName(bot), " :: Pushing Tower")
			return true
		end
	end
	
	if ( EnemyTowers[1]:GetHealth() / EnemyTowers[1]:GetMaxHealth() ) < 0.1 then
		return true
	end
	return false
end

function X:Determine_ShouldIDefendLane(bot, EnemyHeroes, AllyHeroes, AllyTowers, EnemyCreeps, AllyCreeps)
	return false;
end

function X:Determine_ShouldRoam(bot)
	return false;
end

function X:Determine_ShouldJungle(bot)
	return self:getHeroVar("Role") == ROLE_JUNGLER;
end

function X:Determine_ShouldTeamRoshan(bot, EnemyHeroes, EnemyTowers)
	return false;
end

function X:Determine_ShouldGetRune(bot)
	return false; -- FIXME: write code to path to rune spots on proper timings
end

function X:Determine_ShouldWard(bot)
	return false;
end

function X:Determine_ShouldLane(bot)
	return self:getHeroVar("Role") ~= ROLE_JUNGLER;
end

function X:Determine_WhereToMove(bot)
	local loc = GetLocationAlongLane(self:getHeroVar("CurLane"), 0.5);
	local dist = GetUnitToLocationDistance(bot, loc);
	--print("Distance: " .. dist);
	if ( dist <= 1.0 ) then
		self:RemoveAction(ACTION_MOVING);
		return nil;
	end
	return loc;
end

function X:DoRetreat(bot, reason)
	if reason == 1 then
		if ( self:HasAction(ACTION_RETREAT) == false ) then
			print(utils.GetHeroName(bot), " STARTING TO RETREAT ")
			self:AddAction(ACTION_RETREAT)
			retreat_generic.OnStart(bot)
		end
		
		retreat_generic.Think(bot, self:RetreatAbility())
	elseif reason == 2 then
		if ( self:HasAction(ACTION_RETREAT) == false ) then
			print(utils.GetHeroName(bot), " STARTING TO RETREAT b/c of tower damage")
			self:AddAction(ACTION_RETREAT)
		end

		local mypos = bot:GetLocation();
		if self:getHeroVar("TargetOfRunAwayFromCreepOrTower") == nil then
			--set the target to go back
			local bInLane, cLane = utils.IsInLane()
			if bInLane then
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", GetLocationAlongLane(cLane,Max(utils.PositionAlongLane(bot, cLane)-0.04,0.0)))
			elseif ( GetTeam() == TEAM_RADIANT ) then
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] - 400, mypos[2] - 400))
			else
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] + 400, mypos[2] + 400))
			end
			
			local d = GetUnitToLocationDistance(bot, self:getHeroVar("TargetOfRunAwayFromCreepOrTower"));
			if(d > 200) then
				bot:Action_MoveToLocation(self:getHeroVar("TargetOfRunAwayFromCreepOrTower"));
			else
				self:RemoveAction(ACTION_RETREAT);
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", nil)
			end
			return
		else
			if(GetUnitToLocationDistance(bot, self:getHeroVar("TargetOfRunAwayFromCreepOrTower")) < 200) then
				-- we are far enough from tower,return to normal state.
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", nil)
				self:RemoveAction(ACTION_RETREAT);
				return
			end
			bot:Action_MoveToLocation(self:getHeroVar("TargetOfRunAwayFromCreepOrTower"))
		end
	elseif reason == 3 then
		if ( self:HasAction(ACTION_RETREAT) == false ) then
			print(utils.GetHeroName(bot), " STARTING TO RETREAT b/c of creep damage")
			self:AddAction(ACTION_RETREAT)
		end

		local mypos = bot:GetLocation();
		if self:getHeroVar("TargetOfRunAwayFromCreepOrTower") == nil then
			--set the target to go back
			local bInLane, cLane = utils.IsInLane()
			if bInLane then
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", GetLocationAlongLane(cLane,Max(utils.PositionAlongLane(bot, cLane)-0.015,0.0)))
			elseif ( GetTeam() == TEAM_RADIANT ) then
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] - 400, mypos[2] - 400))
			else
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] + 400, mypos[2] + 400))
			end
			
			local d = GetUnitToLocationDistance(bot, self:getHeroVar("TargetOfRunAwayFromCreepOrTower"));
			if(d > 200) then
				bot:Action_MoveToLocation(self:getHeroVar("TargetOfRunAwayFromCreepOrTower"));
			else
				self:RemoveAction(ACTION_RETREAT);
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", nil)
			end
			return
		else
			if(GetUnitToLocationDistance(bot, self:getHeroVar("TargetOfRunAwayFromCreepOrTower")) < 200) then
				-- we are far enough from tower,return to normal state.
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", nil)
				self:RemoveAction(ACTION_RETREAT);
				return
			end
			bot:Action_MoveToLocation(self:getHeroVar("TargetOfRunAwayFromCreepOrTower"))
		end
	else
		self:RemoveAction(ACTION_RETREAT);
	end
end

function X:DoFight(bot)
	return;
end

function X:DoDefendAlly(bot)
	return;
end

function X:DoPushLane(bot)
	self:setHeroVar("ShouldPush", true)
	
	local Towers = bot:GetNearbyTowers(750,true);
	if Towers==nil or #Towers==0 then
		return;
	end
	
	local tower=Towers[1];
	if tower == nil or (not tower:IsAlive()) then
		return;
	end
		
	if tower ~= nil then
		if GetUnitToUnitDistance(tower, bot) < bot:GetAttackRange() then
			bot:Action_AttackUnit(tower, false);
		else
			bot:Action_MoveToLocation(tower:GetLocation());
		end
		return;
	end
end

function X:DoDefendLane(bot)
	return;
end

function X:DoRoam(bot)
	return;
end

function X:DoJungle(bot)
	if ( self:HasAction(ACTION_JUNGLING) == false ) then
		print(utils.GetHeroName(bot), " STARTING TO JUNGLE ")
		self:AddAction(ACTION_JUNGLING);
		jungling_generic.OnStart(bot);
	end

	jungling_generic.Think(bot);
end

function X:DoRoshan(bot)
	return;
end

function X:DoGetRune(npcBot)
	-- grab a rune if we walk by it
	if (GetUnitToLocationDistance( npcBot , constants.RAD_BOUNTY_RUNE_SAFE) < 450 and
		GetRuneStatus( RUNE_BOUNTY_1 ) == RUNE_STATUS_AVAILABLE )
	then   
    	npcBot:Action_PickUpRune(RUNE_BOUNTY_1);
    elseif (GetUnitToLocationDistance( npcBot , constants.RAD_BOUNTY_RUNE_OFF) < 450 and
		GetRuneStatus( RUNE_BOUNTY_2 ) == RUNE_STATUS_AVAILABLE )
	then   
    	npcBot:Action_PickUpRune(RUNE_BOUNTY_2);
	elseif (GetUnitToLocationDistance( npcBot , constants.DIRE_BOUNTY_RUNE_SAFE) < 450 and
		GetRuneStatus( RUNE_BOUNTY_3 ) == RUNE_STATUS_AVAILABLE )
	then   
    	npcBot:Action_PickUpRune(RUNE_BOUNTY_3);
	elseif (GetUnitToLocationDistance( npcBot , constants.DIRE_BOUNTY_RUNE_OFF) < 450 and
		GetRuneStatus( RUNE_BOUNTY_4 ) == RUNE_STATUS_AVAILABLE )
	then    
    	npcBot:Action_PickUpRune(RUNE_BOUNTY_4);
    elseif (GetUnitToLocationDistance( npcBot , constants.POWERUP_RUNE_TOP) < 450 and
		GetRuneStatus( RUNE_POWERUP_1 ) == RUNE_STATUS_AVAILABLE )
	then    
    	npcBot:Action_PickUpRune(RUNE_POWERUP_1);
    elseif (GetUnitToLocationDistance( npcBot , constants.POWERUP_RUNE_BOT) < 450 and
		GetRuneStatus( RUNE_POWERUP_2 ) == RUNE_STATUS_AVAILABLE )
	then    
    	npcBot:Action_PickUpRune(RUNE_POWERUP_2);
    end
end

function X:DoWard(bot)
	return;
end

function X:DoLane(bot)
	if ( self:HasAction(ACTION_LANING) == false ) then
		print(utils.GetHeroName(bot), " STARTING TO LANE ")
		self:AddAction(ACTION_LANING);
		laning_generic.OnStart(bot);
	end
	
	laning_generic.Think(bot);
end

function X:DoMove(bot, loc)
	if loc then
		self:AddAction(ACTION_MOVING);
		bot:Action_AttackMove(loc); -- MoveToLocation is quantized and imprecise
	end
end

function X:RetreatAbility()
	return nil
end

function X:MoveItemsFromStashToInventory(bot)
	utils.MoveItemsFromStashToInventory(bot)
end

return X;