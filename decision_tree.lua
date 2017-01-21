-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/role" )
require( GetScriptDirectory().."/laning_generic" )
require( GetScriptDirectory().."/jungling_generic" )
require( GetScriptDirectory().."/retreat_generic" )
require( GetScriptDirectory().."/ganking_generic" )
require( GetScriptDirectory().."/item_usage" )
require( GetScriptDirectory().."/jungle_status" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

enemyData = require( GetScriptDirectory().."/enemy_data" )

local ACTION_NONE		= constants.ACTION_NONE
local ACTION_LANING		= constants.ACTION_LANING
local ACTION_RETREAT 	= constants.ACTION_RETREAT
local ACTION_FIGHT		= constants.ACTION_FIGHT
local ACTION_CHANNELING	= constants.ACTION_CHANNELING
local ACTION_MOVING		= constants.ACTION_MOVING
local ACTION_SECRETSHOP	= constants.ACTION_SECRETSHOP
local ACTION_RUNEPICKUP = constants.ACTION_RUNEPICKUP
local ACTION_ROSHAN		= constants.ACTION_ROSHAN
local ACTION_DEFENDALLY	= constants.ACTION_DEFENDALLY
local ACTION_DEFENDLANE	= constants.ACTION_DEFENDLANE
local ACTION_WARD		= constants.ACTION_WARD

local X = { currentAction = ACTION_NONE, prevAction = ACTION_NONE, actionStack = {}, abilityPriority = {} }

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

function X:getActionStack()
	return self.actionStack
end

function X:getAbilityPriority()
	return self.abilityPriority
end

function X:printInfo()
	print("PrevTime Value: "..self:getPrevTime());
	print("Addr actionStack Table: ", self:getActionStack());
	print("Addr abilityPriority Table: ", self:getAbilityPriority());
end

-------------------------------------------------------------------------------
-- ACTION MANAGEMENT - YOU SHOULDN'T NEED TO TOUCH THIS
-------------------------------------------------------------------------------

function X:PrintActionTransition(name)
	self:setCurrentAction(self:GetAction());
	
	--[[
	if self:getPrevAction() == ACTION_FIGHT then
		self:RemoveAction(ACTION_FIGHT)
		self:setHeroVar("Target", nil)
	end
	--]]
	
	if ( self:getCurrentAction() ~= self:getPrevAction() ) then
		print("["..name.."] Action Transition: "..self:getPrevAction().." --> "..self:getCurrentAction());
		self:setPrevAction(self:getCurrentAction());
	end
end

function X:AddAction(action)
	if action == ACTION_NONE then return end;
	
	local k = self:HasAction(action);
	if k then
		table.remove(self:getActionStack(), k);
	end
	table.insert(self:getActionStack(), 1, action);
end

function X:HasAction(action)
    for key, value in pairs(self:getActionStack()) do
        if value == action then return key end
    end
    return false
end

function X:RemoveAction(action)
	
	--print("Removing Action".. action)
	
	if action == ACTION_NONE then return end;
	
	local k = self:HasAction(action);
	if k then
		table.remove(self:getActionStack(), k);
	end
	
	local a = self:GetAction()
	--print("Next Action".. a)
	
	self:setCurrentAction(a);
end

function X:GetAction()
	if #self:getActionStack() == 0 then
		return ACTION_NONE;
	end
	return self:getActionStack()[1];
end

function X:setHeroVar(var, value)
	gHeroVar.SetVar(self.pID, var, value)
end

function X:getHeroVar(var)
	return gHeroVar.GetVar(self.pID, var)
end

-------------------------------------------------------------------------------
-- MAIN THINK FUNCTION - DO NOT OVER-LOAD 
-------------------------------------------------------------------------------

function X:DoInit(bot)
	gHeroVar.SetGlobalVar("PrevEnemyDataDump", -1000.0)
	
	--print( "Initializing PlayerID: ", bot:GetPlayerID() )
	if GetTeamMember( GetTeam(), 1 ) == nil or GetTeamMember( GetTeam(), 5 ) == nil then return end
	
	self.pID = bot:GetPlayerID() -- do this to reduce calls to bot:GetPlayerID() in the future
	gHeroVar.InitHeroVar(self.pID)
	
	self:setHeroVar("Self", self)
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
	
	self:DoHeroSpecificInit(bot)
end

function X:DoHeroSpecificInit(bot)
	return
end

function X:Think(bot)
	if ( GetGameState() == GAME_STATE_TEAM_SHOWCASE ) then
		if not self.Init then
			self:DoInit(bot)
		end
	end

	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
	
	-- check if jungle respawn timer was hit to repopulate our table
	jungle_status.checkSpawnTimer()
	
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
	self:setCurrentAction(self:GetAction())
	self:PrintActionTransition(utils.GetHeroName(bot))
	
	---[[
	-- UPDATE GLOBAL INFO --
	enemyData.UpdateEnemyInfo()
	
	-- DEBUG ENEMY DUMP
	-- Dump enemy info every 15 seconds
	checkLevel, newTime = utils.TimePassed(gHeroVar.GetGlobalVar("PrevEnemyDataDump"), 15.0)
	if checkLevel then
		gHeroVar.SetGlobalVar("PrevEnemyDataDump", newTime)
		enemyData.PrintEnemyInfo()
	end
		
	--AM I ALIVE
    if( not bot:IsAlive() ) then
		--print( "You are dead, nothing to do!!!");
		local bRet = self:DoWhileDead(bot)
		if bRet then return end
	end
	
	--AM I CHANNELING AN ABILITY/ITEM (i.e. TP Scroll, Ultimate, etc.)
	if bot:IsChanneling() then
		local bRet = self:DoWhileChanneling(bot)
		if bRet then return end
	end
	
	-- Check if our bot was trying to harass with an ability using Out of Range Casting variable
	-- Give them 2.0 seconds to use it or fall through to further logic
	local oorC = self:getHeroVar("OutOfRangeCasting")
	if bot:GetCurrentActionType() == BOT_ACTION_TYPE_USE_ABILITY and ( oorc ~= nil and (oorC-GameTime()) < 2.0 ) then
		print("CLEARING OORC ABILITY USE")
		bot:Action_ClearActions() 
		return
	end
	
	--FIXME: Is this the right place to do this???
	utils.CourierThink(bot)
	-- FIXME - right place?
	self:ConsiderItemUse()
	
	------------------------------------------------
	-- NOW DECISIONS THAT MODIFY MY ACTION STATES --
	------------------------------------------------
	
	local safe = self:Determine_AmISafe(bot)
	if safe ~= 0 or self:GetAction() == ACTION_RETREAT then
		local bRet = self:DoRetreat(bot, safe)
		if bRet then return end
	end
	
	local bRet = self:ConsiderAbilityUse()
	if bRet then return end
	
	if ( self:Determine_ShouldIFighting(bot) or self:GetAction() == ACTION_FIGHT ) then
		local bRet = self:DoFight(bot)
		if bRet then return end
	end
	
	if ( self:Determine_ShouldGetRune(bot) or self:GetAction() == ACTION_RUNEPICKUP ) then
		local bRet = self:DoGetRune(bot)
		if bRet then return end
	end
	
	if ( self:GetAction() == ACTION_SECRETSHOP ) then
		return
	end
	
	if ( self:Determine_DoAlliesNeedHelp(bot) ) then
		local bRet = self:DoDefendAlly(bot)
		if bRet then return end
	end
	
	if ( self:Determine_ShouldTeamRoshan(bot) or self:GetAction() == ACTION_ROSHAN ) then
		local bRet = self:DoRoshan(bot)
		if bRet then return end
	end
	
	if ( self:Determine_ShouldIPushLane(bot) ) then
		local bRet = self:DoPushLane(bot)
		if bRet then return end
	end
	
	if ( self:Determine_ShouldIDefendLane(bot) ) then
		local bRet = self:DoDefendLane(bot)
		if bRet then return end
	end

	if ( self:Determine_ShouldGank(bot)  or self:GetAction() == ACTION_GANKING ) then
		local bRet = self:DoGank(bot)
		if bRet then return end
	end

	if ( self:Determine_ShouldRoam(bot) ) then
		local bRet = self:DoRoam(bot)
		if bRet then return end
	end

	if ( self:Determine_ShouldJungle(bot) or self:GetAction() == ACTION_JUNGLING ) then
		local bRet = self:DoJungle(bot)
		if bRet then return end
	end
	
	if ( self:Determine_ShouldWard(bot) or self:GetAction() == ACTION_WARD ) then
		local bRet = self:DoWard(bot)
		if bRet then return end
	end
	
	if ( self:Determine_ShouldLane(bot) or self:GetAction() == ACTION_LANING ) then
		local bRet = self:DoLane(bot)
		if bRet then return end
	end
	
	local loc = self:Determine_WhereToMove(bot)
	local bRet = self:DoMove(bot, loc)
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
	return true
end

function X:DoWhileChanneling(bot)
	-- FIXME: Check Items like Glimmer Cape for activation if wanted
	return true
end

function X:ConsiderBuyback(bot)
	-- FIXME: Write Buyback logic here
	if ( bot:HasBuyback() ) then
		return false -- FIXME: for now always return false
	end
	return false
end

-- BELOW -- Pure Abstract Function - Designed for Overload
function X:ConsiderAbilityUse()
	return false
end

function X:ConsiderItemUse()
	local timeInfo = item_usage.UseItems()
	if timeInfo ~= nil then
		print( "X:ConsiderItemUse() TimeInfo: ", timeInfo )
	end
end

function X:Determine_AmISafe(bot)	
	if bot:GetHealth()/bot:GetMaxHealth() > 0.9 and bot:GetMana()/bot:GetMaxMana() > 0.9 then
		if utils.IsTowerAttackingMe() then 
			return 2
		end
		if utils.IsCreepAttackingMe() then
			if self:getHeroVar("Target") == nil then
				return 3
			end
		end
		self:setHeroVar("IsRetreating", false)
		return 0
	end
	
	if bot:GetHealth()/bot:GetMaxHealth() > 0.65 and bot:GetMana()/bot:GetMaxMana() > 0.6 and GetUnitToLocationDistance(bot, GetLocationAlongLane(self:getHeroVar("CurLane"), 0)) > 6000 then
		if utils.IsTowerAttackingMe() then
			return 2
		end
		if utils.IsCreepAttackingMe() then
			if self:getHeroVar("Target") == nil then
				return 3
			end
		end
		self:setHeroVar("IsRetreating", false)
		return 0
	end
	
	if bot:GetHealth()/bot:GetMaxHealth() > 0.8 and bot:GetMana()/bot:GetMaxMana() > 0.36 and GetUnitToLocationDistance(bot, GetLocationAlongLane(self:getHeroVar("CurLane"), 0)) > 6000 then
		if utils.IsTowerAttackingMe() then
			return 2
		end
		if utils.IsCreepAttackingMe() then
			if self:getHeroVar("Target") == nil then
				return 3
			end
		end
		self:setHeroVar("IsRetreating", false)
		return 0
	end
	
	if self:getHeroVar("IsRetreating") ~= nil and self:getHeroVar("IsRetreating") == true then
		return 1
	end
	
	local Enemies = bot:GetNearbyHeroes(1500, true, BOT_MODE_NONE);
	local Allies = bot:GetNearbyHeroes(1500, false, BOT_MODE_NONE);
	local Towers = bot:GetNearbyTowers(900, true);
	
	local nEn = 0
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

	if ((bot:GetHealth()/bot:GetMaxHealth()) < 0.33 and self:GetAction() ~= ACTION_JUNGLING) or 
		(bot:GetMana()/bot:GetMaxMana() < 0.07 and self:getPrevAction() == ACTION_LANING) then
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
		if self:getHeroVar("Target") == nil then
			return 3
		end
	end
	
	self:setHeroVar("IsRetreating", false)
	return 0;
end

function X:Determine_ShouldIFighting(bot)
	local weakestHero, myDamage, score = utils.FindTarget(1200)
	
	if utils.NotNilOrDead(weakestHero) then
		local bFight = myDamage > weakestHero:GetHealth() and score > 1
		
		if bFight then
			if self:HasAction(ACTION_FIGHT) == false then
				print(utils.GetHeroName(bot), " - Fighting ", utils.GetHeroName(weakestHero))
				self:AddAction(ACTION_FIGHT)
				self:setHeroVar("Target", weakestHero)
			end
			
			if weakestHero ~= getHeroVar("Target") then
				print(utils.GetHeroName(bot), " - Fight Change - Fighting ", utils.GetHeroName(weakestHero))
				self:setHeroVar("Target", weakestHero)
			end
		end
		
		return bFight
	end
	
	if getHeroVar("Target") ~= nil then
		if (not utils.NotNilOrDead(weakestHero)) or (not weakestHero:CanBeSeen()) then
			print(utils.GetHeroName(bot), " - Stopping my fight... lost hero")
			self:RemoveAction(ACTION_FIGHT)
			self:setHeroVar("Target", nil)
			return false
		end
		
		if (GameTime() - bot:GetLastAttackTime()) > 3.0 or bot:GetAttackTarget() ~= getHeroVar("Target") then
			print(utils.GetHeroName(bot), " - Stopping my fight... done chasing")
			self:RemoveAction(ACTION_FIGHT)
			self:setHeroVar("Target", nil)
			return false
		end
	end
	
	return false
end

function X:Determine_DoAlliesNeedHelp(bot)
	return false;
end

function X:Determine_ShouldIPushLane(bot)
	-- DETERMINE MY SURROUNDING INFO --
	local RANGE = 1200
	
	--GET HEROES WITHIN XYZ UNIT RANGE
	local EnemyHeroes = bot:GetNearbyHeroes(RANGE, true, BOT_MODE_NONE);
	--local AllyHeroes = bot:GetNearbyHeroes(RANGE, false, BOT_MODE_NONE);
	
	--GET TOWERS WITHIN XYZ UNIT RANGE
	local EnemyTowers = bot:GetNearbyTowers(RANGE, true);
	local AllyTowers = bot:GetNearbyTowers(RANGE, false);
	
	--GET CREEPS WITHIN XYZ UNIT RANGE
	local EnemyCreeps = bot:GetNearbyCreeps(RANGE, true);
	local AllyCreeps = bot:GetNearbyCreeps(RANGE, false);

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

function X:Determine_ShouldIDefendLane(bot)
	return false
end

function X:Determine_ShouldGank(bot)
	return getHeroVar("Role") == ROLE_ROAMER or (getHeroVar("Role") == ROLE_JUNGLER and getHeroVar("Self"):IsReadyToGank(bot))
end

function X:IsReadyToGank(bot)
    return false
end

function X:Determine_ShouldRoam(bot)
	return false
end

function X:Determine_ShouldJungle(bot)
	local bRoleJungler = self:getHeroVar("Role") == ROLE_JUNGLER
	--FIXME: Implement other reasons when/why we would want to jungle
	return bRoleJungler
end

function X:Determine_ShouldTeamRoshan(bot)
	if (false) then -- FIXME: Implement
		if self:HasAction(ACTION_ROSHAN) == false then
			print(utils.GetHeroName(bot), " - Going to Fight Roshan")
			self:AddAction(ACTION_ROSHAN)
		end
	end
	return false
end

function X:Determine_ShouldGetRune(bot)
	if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then return false end
	
	for _,r in pairs(constants.RuneSpots) do
		local loc = GetRuneSpawnLocation(r)
		if utils.GetDistance(bot:GetLocation(), loc) < 1000 and GetRuneStatus(r) == RUNE_STATUS_AVAILABLE then
			if self:HasAction(ACTION_RUNEPICKUP) == false then
				print(utils.GetHeroName(bot), " STARTING TO GET RUNE ")
				self:AddAction(ACTION_RUNEPICKUP)
				setHeroVar("RuneTarget", r)
			end
		end
	end
	
	local bRet = self:DoGetRune(bot) -- grab a rune if we near one as we jungle
	if bRet then return bRet end
end

function X:Determine_ShouldWard(bot)
	if (false) then -- FIXME: Implement
		if self:HasAction(ACTION_WARD) == false then
			print(utils.GetHeroName(bot), " - Going to place Wards")
			self:AddAction(ACTION_WARD)
		end
	end
	return false
end

function X:Determine_ShouldLane(bot)
	local notJungler = self:getHeroVar("Role") ~= ROLE_JUNGLER
	return notJungler
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
		retreat_generic.Think(bot)
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
			return false
		else
			if(GetUnitToLocationDistance(bot, self:getHeroVar("TargetOfRunAwayFromCreepOrTower")) < 200) then
				-- we are far enough from tower,return to normal state.
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", nil)
				self:RemoveAction(ACTION_RETREAT);
				return false
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
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", GetLocationAlongLane(cLane,Max(utils.PositionAlongLane(bot, cLane)-0.03,0.0)))
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
			return false
		else
			if(GetUnitToLocationDistance(bot, self:getHeroVar("TargetOfRunAwayFromCreepOrTower")) < 200) then
				-- we are far enough from tower,return to normal state.
				self:setHeroVar("TargetOfRunAwayFromCreepOrTower", nil)
				self:RemoveAction(ACTION_RETREAT);
				return false
			end
			bot:Action_MoveToLocation(self:getHeroVar("TargetOfRunAwayFromCreepOrTower"))
		end
	else
		self:RemoveAction(ACTION_RETREAT)
		return false
	end
	return true
end

function X:DoFight(bot)
	local target = self:getHeroVar("Target")
	if utils.NotNilOrDead(target) then
		local Towers = bot:GetNearbyTowers(750, true)
		if Towers ~= nil and #Towers == 0 then
			if target:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
				item_usage.UseMovementItems()
				bot:Action_MoveToUnit(target)
			else
				bot:Action_AttackUnit(target, false)
			end
			return true
		else
			local towerDmgToMe = 0
			local myDmgToTarget = bot:GetEstimatedDamageToTarget( true, target, 4.0, DAMAGE_TYPE_ALL )
			for _, tow in pairs(Towers) do
				if GetUnitToLocationDistance( bot, tow:GetLocation() ) < 750 then
					towerDmgToMe = towerDmgToMe + tow:GetEstimatedDamageToTarget( false, bot, 4.0, DAMAGE_TYPE_PHYSICAL )
				end
			end
			if myDmgToTarget > target:GetHealth() and towerDmgToMe < (bot:GetHealth() + 100) then
				--print(utils.GetHeroName(bot), " - we are tower diving for the kill")
				if target:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
					bot:Action_MoveToUnit(target)
				else
					bot:Action_AttackUnit(target, false)
				end
				return true
			else
				self:RemoveAction(ACTION_FIGHT)
				self:setHeroVar("Target", nil)
				return false
			end
		end
	else
		self:RemoveAction(ACTION_FIGHT)
		self:setHeroVar("Target", nil)
	end
	return false
end

function X:DoDefendAlly(bot)
	return true
end

function X:DoPushLane(bot)
	self:setHeroVar("ShouldPush", true)
	
	local Towers = bot:GetNearbyTowers(750,true);
	if Towers==nil or #Towers==0 then
		return false
	end
	
	local tower=Towers[1];
	if tower == nil or (not tower:IsAlive()) then
		return false
	end
		
	if tower ~= nil then
		if GetUnitToUnitDistance(tower, bot) < bot:GetAttackRange() then
			bot:Action_AttackUnit(tower, false);
		else
			bot:Action_MoveToLocation(tower:GetLocation());
		end
		return true
	end
	return false
end

function X:DoDefendLane(bot)
	return true
end

function X:DoGank(bot)
	local ret = ganking_generic.Think(bot)

	if ret then
    if ( self:HasAction(ACTION_GANKING) == false ) then
			print(utils.GetHeroName(bot), " STARTING TO GANK ")
			self:AddAction(ACTION_GANKING);
			ganking_generic.OnStart(bot);
		end
	end

	return ret
end

function X:DoRoam(bot)
	return true
end

function X:DoJungle(bot)
	if ( self:HasAction(ACTION_JUNGLING) == false ) then
		print(utils.GetHeroName(bot), " STARTING TO JUNGLE ")
		self:AddAction(ACTION_JUNGLING);
		jungling_generic.OnStart(bot);
	end
	
	jungling_generic.Think(bot)
	
	return true
end

function X:DoRoshan(bot)
	--FIXME: Implement Roshan fight and clear action stack when he dead
	self:RemoveAction(ACTION_ROSHAN)
	return true
end

function X:DoGetRune(bot)
	local rt = getHeroVar("RuneTarget")
	if rt ~= nil and GetRuneStatus(rt) ~= RUNE_STATUS_MISSING then
		bot:Action_PickUpRune(getHeroVar("RuneTarget"))
		return true
	end
	setHeroVar("RuneTarget", nil)
	self:RemoveAction(ACTION_RUNEPICKUP)
	return false
end

function X:DoWard(bot)
	self:RemoveAction(ACTION_WARD)
	return true
end

function X:DoLane(bot)
	if ( self:HasAction(ACTION_LANING) == false ) then
		print(utils.GetHeroName(bot), " STARTING TO LANE ")
		self:AddAction(ACTION_LANING)
		laning_generic.OnStart(bot)
	end
	
	laning_generic.Think(bot)
	
	return true
end

function X:DoMove(bot, loc)
	if loc then
		self:AddAction(ACTION_MOVING);
		bot:Action_MoveToLocation(loc)
	end
	return true
end

function X:MoveItemsFromStashToInventory(bot)
	utils.MoveItemsFromStashToInventory(bot)
end

function X:DoCleanCamp(bot, neutrals)
	bot:Action_AttackUnit(neutrals[1], true)
end

function X:GetMaxClearableCampLevel(bot)
	return constants.CAMP_ANCIENT
end

function X:HarassLaneEnemies(bot)
	return
end

return X;
