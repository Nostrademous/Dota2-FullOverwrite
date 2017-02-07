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
require( GetScriptDirectory().."/buildings_status" )
require( GetScriptDirectory().."/fighting" )
require( GetScriptDirectory().."/global_game_state" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )

local ACTION_NONE       = constants.ACTION_NONE
local ACTION_LANING     = constants.ACTION_LANING
local ACTION_RETREAT    = constants.ACTION_RETREAT
local ACTION_FIGHT      = constants.ACTION_FIGHT
local ACTION_CHANNELING = constants.ACTION_CHANNELING
local ACTION_JUNGLING   = constants.ACTION_JUNGLING
local ACTION_MOVING     = constants.ACTION_MOVING
local ACTION_SPECIALSHOP = constants.ACTION_SPECIALSHOP
local ACTION_RUNEPICKUP = constants.ACTION_RUNEPICKUP
local ACTION_ROSHAN     = constants.ACTION_ROSHAN
local ACTION_DEFENDALLY = constants.ACTION_DEFENDALLY
local ACTION_DEFENDLANE = constants.ACTION_DEFENDLANE
local ACTION_WARD       = constants.ACTION_WARD
local ACTION_GANKING    = constants.ACTION_GANKING

local gStuck = false -- for detecting getting stuck in trees or whatever

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
    self:setCurrentAction(self:GetAction())

    if ( self:getCurrentAction() ~= self:getPrevAction() ) then
        local target = self:getHeroVar("Target")
        if utils.ValidTarget(target) then
            utils.myPrint("Action Transition: "..self:getPrevAction().." --> "..self:getCurrentAction(), " :: Target: ", utils.GetHeroName(target.Obj))
        elseif target.Id > 0 then
            utils.myPrint("Action Transition: "..self:getPrevAction().." --> "..self:getCurrentAction(), " :: TargetID: ", target.Id)
        else
            utils.myPrint("Action Transition: "..self:getPrevAction().." --> "..self:getCurrentAction())
        end
        self:setPrevAction(self:getCurrentAction())
    end
end

function X:AddAction(action)
    if action == ACTION_NONE then return end

    local k = self:HasAction(action)
    if k then
        table.remove(self:getActionStack(), k)
    end
    table.insert(self:getActionStack(), 1, action)
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

    local k = self:HasAction(action)
    if k then
        table.remove(self:getActionStack(), k)
    end

    local a = self:GetAction()
    --print("Next Action".. a)

    self:setCurrentAction(a)
end

function X:GetAction()
    if #self:getActionStack() == 0 then
        return ACTION_NONE
    end
    return self:getActionStack()[1]
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
    gHeroVar.SetGlobalVar("PrevEnemyUpdateTime", -1000.0)
    gHeroVar.SetGlobalVar("PrevEnemyDataDump", -1000.0)

    --print( "Initializing PlayerID: ", bot:GetPlayerID() )
    local allyList = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    if #allyList ~= 5 then return end

    self.pID = bot:GetPlayerID() -- do this to reduce calls to bot:GetPlayerID() in the future
    gHeroVar.InitHeroVar(self.pID)

    self:setHeroVar("Self", self)
    self:setHeroVar("Name", utils.GetHeroName(bot))
    self:setHeroVar("WorldUpdateTime", -1000.0)
    self:setHeroVar("LastCourierThink", -1000.0)
    self:setHeroVar("LastLevelUpThink", -1000.0)
    self:setHeroVar("LastStuckCheck", -1000.0)
    self:setHeroVar("StuckCounter", 0)
    self:setHeroVar("LastLocation", Vector(0, 0, 0))
    self:setHeroVar("LaneChangeTimer", -1000.0)
    self:setHeroVar("Target", {Obj=nil, Id=0})
    self:setHeroVar("GankTarget", {Obj=nil, Id=0})

    role.GetRoles()
    if role.RolesFilled() then
        self.Init = true

        for i = 1,5,1 do
            local hero = GetTeamMember( i )
            if hero:GetUnitName() == bot:GetUnitName() then
                cLane, cRole = role.GetLaneAndRole(GetTeam(), i)
                self:setHeroVar("CurLane", cLane)
                self:setHeroVar("Role", cRole)
                break
            end
        end
    end
    utils.myPrint(" initialized - Lane: ", self:getHeroVar("CurLane"), ", Role: ", self:getHeroVar("Role"))

    self:DoHeroSpecificInit(bot)
end

function X:DoHeroSpecificInit(bot)
    return
end

-- LOCAL VARIABLES THAT WE WILL NEED FOR THIS FRAME
local updateFrequency    = 0.03

local EyeRange           = 1200
local nearbyEnemyHeroes  = {}
local nearbyAlliedHeroes = {}
local nearbyEnemyCreep   = {}
local nearbyAlliedCreep  = {}
local nearbyEnemyTowers  = {}
local nearbyAlliedTowers = {}

function X:Think(bot)
    if ( GetGameState() == GAME_STATE_PRE_GAME ) then
        if not self.Init then
            self:DoInit(bot)
        end
    end

    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
    
    local bUpdate, newTime = utils.TimePassed(self:getHeroVar("WorldUpdateTime"), updateFrequency)
    if bUpdate then
        self:setHeroVar("WorldUpdateTime", newTime)
        nearbyEnemyHeroes   = bot:GetNearbyHeroes(EyeRange, true, BOT_MODE_NONE)
        nearbyAlliedHeroes  = bot:GetNearbyHeroes(EyeRange, false, BOT_MODE_NONE)
        nearbyEnemyCreep    = bot:GetNearbyLaneCreeps(EyeRange, true)
        nearbyAlliedCreep   = bot:GetNearbyLaneCreeps(EyeRange, false)
        nearbyEnemyTowers   = bot:GetNearbyTowers(EyeRange, true)
        nearbyAlliedTowers  = bot:GetNearbyTowers(EyeRange, false)
        
        local setTarget = self:getHeroVar("Target")
        if setTarget.Id > 0 and not utils.ValidTarget(setTarget) then
            for _, v in pairs(nearbyEnemyHeroes) do
                if setTarget.Id == v:GetPlayerID() then
                    utils.myPrint("Updated my Target after re-aquire")
                    setTarget.Obj = v
                    break
                end
            end
        end
        
        local gankTarget = self:getHeroVar("GankTarget")
        if gankTarget.Id > 0 and not utils.ValidTarget(gankTarget) then
            for _, v in pairs(nearbyEnemyHeroes) do
                if gankTarget.Id == v:GetPlayerID() then
                    utils.myPrint("Updated my GankTarget after re-aquire")
                    gankTarget.Obj = v
                    break
                end
            end
        end
    end

    -- TEST STUFF
    --[[
    local gulHandles = GetUnitList(UNIT_LIST_ENEMY_HEROES);
    local gnhHandles = bot:GetNearbyHeroes(1500, true, BOT_MODE_NONE);

    for _, aaa in ipairs(gnhHandles) do
        if not utils.InTable(gulHandles, aaa) then
            print("GNH Info");
            print("-----------------------------");
            for _, enemy_handle_gnh in pairs(gnhHandles) do
                local gt = GameTime();
                local eh = tostring(enemy_handle_gnh);
                local en = enemy_handle_gnh:GetUnitName();
                print(gt .. ": " .. en .. " " .. eh);
            end

            print("");

            print("GUL Info");
            print("-----------------------------");
            for _, enemy_handle_gul in pairs(gulHandles) do
                local gt = GameTime();
                local eh = tostring(enemy_handle_gul);
                local en = enemy_handle_gul:GetUnitName();
                print(gt .. ": " .. en .. " " .. eh);
            end
        end
    end
    --]]
    
    -- check if jungle respawn timer was hit to repopulate our table
    jungle_status.checkSpawnTimer()
    buildings_status.Update()

    --[[
        FIRST DECISIONS THAT DON'T AFFECT THE MY ACTION STATES
        :: Leveling Up Abilities, Buying Items (in most cases), Using Courier
    --]]
    -- LEVEL UP ABILITIES
    local checkLevel, newTime = utils.TimePassed(self:getHeroVar("LastLevelUpThink"), 2.0)
    if checkLevel then
        self:setHeroVar("LastLevelUpThink", newTime)
        if bot:GetAbilityPoints() > 0 then
            utils.LevelUp(bot, self:getAbilityPriority());
        end
    end

    -- DEBUG NOTIFICATION
    self:setCurrentAction(self:GetAction())
    self:PrintActionTransition(utils.GetHeroName(bot))

    -- UPDATE GLOBAL INFO --
    enemyData.UpdateEnemyInfo()

    -- DEBUG ENEMY DUMP
    -- Dump enemy info every 15 seconds
    checkLevel, newTime = utils.TimePassed(gHeroVar.GetGlobalVar("PrevEnemyDataDump"), 15.0)
    if checkLevel then
        gHeroVar.SetGlobalVar("PrevEnemyDataDump", newTime)
        --enemyData.PrintEnemyInfo()
    end

    --USE COURIER AS NECESSARY
    utils.CourierThink(bot)
    
    --SHOULD WE USE GLYPH
    if ( self:Determine_ShouldUseGlyph(bot) ) then
        bot:Action_Glyph()
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
    
    --ACTIONS QUEUED?
    if bot:HasQueuedAction() then
        local target = self:getHeroVar("Target")
        if target.Id > 0 and not IsHeroAlive( target.Id ) then
            utils.myPrint("Queueing Disabled")
            bot:SetActionQueueing(false)
        else
            return
        end
    end
    
    -- FIXME - right place?
    local bRet = self:ConsiderItemUse()
    if bRet then return end
    
    -- Check if we are stuck
    if GetGameState() == GAME_STATE_GAME_IN_PROGRESS then
        local curLoc = bot:GetLocation()
        local checkLevel, newTime = utils.TimePassed(self:getHeroVar("LastStuckCheck"), 3.0)
        if checkLevel then
            self:setHeroVar("LastStuckCheck", newTime)
            if utils.GetDistance(self:getHeroVar("LastLocation"),curLoc) == 0 then
                local stuckCounter = self:getHeroVar("StuckCounter") + 1
                self:setHeroVar("StuckCounter", stuckCounter)

                if stuckCounter >= 12 then
                    gStuck = true
                    utils.AllChat("I AM STUCK!!!")
                end
            else
                self:setHeroVar("StuckCounter", 0)
                self:SaveLocation(bot)
            end
        end

        if gStuck then
            local fixLoc = self:getHeroVar("StuckLoc")
            if fixLoc == nil then
                self:setHeroVar("StuckLoc", utils.Fountain())
            else
                if GetUnitToLocationDistance(bot, fixLoc) < 10 then
                    utils.MoveSafelyToLocation(fixLoc)
                    return
                else
                    gStuck = false
                    self:setHeroVar("StuckLoc", nil)
                end
            end
        end
    end

    ------------------------------------------------
    -- NOW DECISIONS THAT MODIFY MY ACTION STATES --
    ------------------------------------------------

    if ( self:GetAction() == ACTION_RETREAT ) then
        local bRet = self:DoRetreat(bot, self:getHeroVar("RetreatReason"))
        if bRet then return end
    end
    local safe = self:Determine_ShouldIRetreat(bot)
    if safe ~= nil then
        utils.TreadCycle(bot, constants.STRENGTH)
        self:setHeroVar("RetreatReason", safe)
        local bRet = self:DoRetreat(bot, safe)
        if bRet then return end
    end

    if bot:IsUsingAbility() then 
        return
    else
        local bRet = self:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
        if bRet then return end
    end

    -- NOTE: Unlike many others, we should re-evalute need to fight every time and
    --       not check if GetAction == ACTION_FIGHT
    if ( self:Determine_ShouldIFighting(bot) ) then
        local bRet = self:DoFight(bot)
        if bRet then return end
    end
    
    if ( self:GetAction() == ACTION_RUNEPICKUP or self:Determine_ShouldGetRune(bot) ) then
        local bRet = self:DoGetRune(bot)
        if bRet then return end
    end

    if ( self:GetAction() == ACTION_SPECIALSHOP ) then
        return
    end

    if ( self:Determine_DoAlliesNeedHelp(bot) ) then
        local bRet = self:DoDefendAlly(bot)
        if bRet then return end
    end

    if ( self:GetAction() == ACTION_ROSHAN or self:Determine_ShouldTeamRoshan(bot) ) then
        local bRet = self:DoRoshan(bot)
        if bRet then return end
    end

    local lane, building, numEnemies = self:Determine_ShouldIDefendLane(bot)
    if ( lane ) then
        local bRet = self:DoDefendLane(bot, lane, building, numEnemies)
        if bRet then return end
    end

    if ( self:GetAction() == ACTION_GANKING or self:Determine_ShouldGank(bot) ) then
        local bRet = self:DoGank(bot)
        if bRet then return end
    end

    if ( self:Determine_ShouldRoam(bot) ) then
        local bRet = self:DoRoam(bot)
        if bRet then return end
    end

    if ( self:GetAction() == ACTION_JUNGLING or self:Determine_ShouldJungle(bot) ) then
        local bRet = self:DoJungle(bot)
        if bRet then return end
    end

    if ( self:GetAction() == ACTION_WARD or self:Determine_ShouldWard(bot) ) then
        local bRet = self:DoWard(bot)
        if bRet then return end
    end
    
    if ( self:Determine_ShouldIChangeLane(bot) ) then
        local bRet = self:DoChangeLane(bot)
        if bRet then return end
    end
    
    if ( self:Determine_ShouldIPushLane(bot) ) then
        local bRet = self:DoPushLane(bot)
        if bRet then return end
    end

    if ( self:GetAction() == ACTION_LANING or self:Determine_ShouldLane(bot) ) then
        local bRet = self:DoLane(bot)
        if bRet then return end
    end

    local loc = self:Determine_WhereToMove(bot)
    self:DoMove(bot, loc)
end

-------------------------------------------------------------------------------
-- FUNCTION DEFINITIONS - OVER-LOAD THESE IN HERO LUA IF YOU DESIRE
-------------------------------------------------------------------------------

function X:DoWhileDead(bot)
    -- clear our actionStack except for ACTION_IDLE
    local as = self:getActionStack()
    if #as > 1 then
        for i = #as-1, 1, -1 do
            table.remove(as, i)
        end
    end

    self:MoveItemsFromStashToInventory(bot);
    local bb = self:ConsiderBuyback(bot);
    if (bb) then
        bot:Action_Buyback();
    end
    return true
end

function X:DoWhileChanneling(bot)
    item_usage.UseGlimmerCape(bot)
    return true
end

function X:ConsiderBuyback(bot)
    -- FIXME: Write Buyback logic here
    if ( bot:HasBuyback() ) then
        return false -- FIXME: for now always return false
    end
    return false
end

-- Pure Abstract Function - Designed for Overload
function X:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    return false
end
-------------------------------------------------

function X:ConsiderItemUse()
    local bRet = item_usage.UseItems()
    return bRet
end

function X:Determine_ShouldUseGlyph(bot)
    local vulnerableTowers = buildings_status.GetDestroyableTowers(GetTeam())
    for i, building_id in pairs(vulnerableTowers) do
	    local tower = buildings_status.GetHandle(GetTeam(), building_id)
	    local listEnemyCreep = tower:GetNearbyCreeps(tower:GetAttackRange(), true)
	    local listHeroCount = tower:GetNearbyHeroes(tower:GetAttackRange(), true, BOT_MODE_NONE)

	    if tower:GetHealth() < math.max(tower:GetMaxHealth()*0.15, 150) and tower:TimeSinceDamagedByAnyHero() < 3
            and tower:TimeSinceDamagedByCreep() < 3 and (listEnemyCreep and #listEnemyCreep >= 2) 
            and (listHeroCount and #listHeroCount >= 1) then
		    return true
	    end
    end
    return false
end

function X:Determine_ShouldIRetreat(bot)
    if bot:GetHealth()/bot:GetMaxHealth() > 0.9 and bot:GetMana()/bot:GetMaxMana() > 0.5 then
        if utils.IsTowerAttackingMe() then
            return constants.RETREAT_TOWER
        end
        return nil
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.65 and bot:GetMana()/bot:GetMaxMana() > 0.6 and GetUnitToLocationDistance(bot, GetLocationAlongLane(self:getHeroVar("CurLane"), 0)) > 6000 then
        if utils.IsTowerAttackingMe() then
            return constants.RETREAT_TOWER
        end
        if utils.IsCreepAttackingMe() then
            local pushing = self:getHeroVar("ShouldPush")
            if self:getHeroVar("Target").Obj == nil or pushing == nil or pushing == false then
                return constants.RETREAT_CREEP
            end
        end
        return nil
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.8 and bot:GetMana()/bot:GetMaxMana() > 0.36 and GetUnitToLocationDistance(bot, GetLocationAlongLane(self:getHeroVar("CurLane"), 0)) > 6000 then
        if utils.IsTowerAttackingMe() then
            return constants.RETREAT_TOWER
        end
        if utils.IsCreepAttackingMe() then
            local pushing = self:getHeroVar("ShouldPush")
            if self:getHeroVar("Target").Obj == nil or pushing == nil or pushing == false then
                return constants.RETREAT_CREEP
            end
        end
        return nil
    end

    if ((bot:GetHealth()/bot:GetMaxHealth()) < 0.33 and self:GetAction() ~= ACTION_JUNGLING) or
        (bot:GetMana()/bot:GetMaxMana() < 0.07 and self:getPrevAction() == ACTION_LANING) then
        self:setHeroVar("IsRetreating", true)
        return constants.RETREAT_FOUNTAIN
    end

    if #nearbyAlliedHeroes < 2 then
        local MaxStun = 0

        --enemyData.GetEnemyTeamSlowDuration()/2.0

        for _,enemy in pairs(nearbyEnemyHeroes) do
            if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.4 then
                local bEscape = self:getHeroVar("HasEscape")
                local enemyManaRatio = enemy:GetMana()/enemy:GetMaxMana()

                if enemyManaRatio > (0.35 + enemy:GetLevel()/100.0) then
                    if bEscape ~= nil and bEscape ~= false then
                        MaxStun = MaxStun + enemy:GetStunDuration(true)
                    else
                        MaxStun = MaxStun + Max(enemy:GetStunDuration(true), enemy:GetSlowDuration(true)/1.5)
                    end
                end
            end
        end

        local enemyDamage = 0
        for _, enemy in pairs(nearbyEnemyHeroes) do
            if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.4 then
                local enemyManaRatio = enemy:GetMana()/enemy:GetMaxMana()
                local pDamage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_PHYSICAL)
                local mDamage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_MAGICAL)
                if enemyManaRatio < ( 0.5 - enemy:GetLevel()/100.0) then
                    enemyDamage = enemyDamage + pDamage + 0.5*mDamage + 0.5*enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_PURE)
                else
                    enemyDamage = enemyDamage + pDamage + mDamage + enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_PURE)
                end
            end
        end

        if enemyDamage > bot:GetHealth() then
            utils.myPrint(" - Retreating - could die in perfect stun/slow overlap")
            self:setHeroVar("IsRetreating", true)
            return constants.RETREAT_DANGER
        end
    end

    if utils.IsTowerAttackingMe() then
        return constants.RETREAT_TOWER
    end
    if utils.IsCreepAttackingMe() then
        local pushing = self:getHeroVar("ShouldPush")
        if self:getHeroVar("Target").Obj == nil or pushing ~= true then
            return constants.RETREAT_CREEP
        end
    end

    return nil
end

function X:Determine_ShouldIFighting2(bot)
    global_game_state.GlobalFightDetermination()
    if self:getHeroVar("Target").Id > 0 then
        return true
    end
    return false
end

function X:Determine_ShouldIFighting(bot)
    -- try to find a taret
    local weakestHero, score = fighting.FindTarget(nearbyEnemyHeroes, nearbyEnemyTowers, nearbyAlliedTowers, nearbyEnemyCreep, nearbyAlliedCreep)
    
    -- get my possible existing target
    local myTarget = self:getHeroVar("Target")
    
    -- if I found a new best target, but I have a target already, and they are not the same
    if weakestHero ~= nil and utils.ValidTarget(myTarget) and myTarget.Obj ~= weakestHero then
        if score > 50.0 or (score > 2.0 and (GetUnitToUnitDistance(bot, weakestHero) < GetUnitToUnitDistance(bot, myTarget)*1.5 or weakestHero:GetStunDuration(true) >= 1.0)) then
            myTarget.Obj = weakestHero
            myTarget.Id = weakestHero:GetPlayerID()
        end
    end
    
    if myTarget.Id > 0 and not IsHeroAlive( myTarget.Id ) then
        utils.AllChat("You dead buddy!")
        self:RemoveAction(ACTION_FIGHT)
        self:setHeroVar("Target", {Obj=nil, Id=0})
        self:setHeroVar("GankTarget", {Obj=nil, Id=0})
        myTarget.Obj = nil
        myTarget.Id = 0
    end
    
    if U.ValidTarget(myTarget) then
        local Allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
        local nFriend = 0
        for _, friend in pairs(Allies) do
            local friendID = friend:GetPlayerID()
            if gHeroVar.HasID(friendID) and myTarget.Id == gHeroVar.GetVar(friendID, "Target").Id then 
                if (GameTime() - friend:GetLastAttackTime()) < 5.0 and myTarget.Obj:GetCurrentMovementSpeed() < friend:GetCurrentMovementSpeed() then
                    nFriend = nFriend + 1
                end
            end
        end
        
        -- none of us can catch them
        if nFriends == 0 then
            for _, friend in pairs(Allies) do
                local friendID = friend:GetPlayerID()
                if gHeroVar.HasID(friendID) and myTarget.Id == gHeroVar.GetVar(friendID, "Target").Id then
                    utils.myPrint("abandoning chase of ", utils.GetHeroName(myTarget.Obj))
                    gHeroVar.SetVar(friendID, "Target", {Obj=nil, Id=0})
                end
            end
            myTarget.Obj = nil
            myTarget.Id = 0
        end
    end
    
    -- if I have a target, set by me or by team fighting function
    if myTarget.Id > 0 and IsHeroAlive(myTarget.Id) then
        if utils.ValidTarget(myTarget) then
            bot:Action_AttackUnit(myTarget.Obj, true)
            return true
        elseif GetHeroLastSeenInfo(myTarget.Id).time > 3.0 then
            utils.myPrint(" - Stopping my fight... lost sight of hero")
            self:RemoveAction(ACTION_FIGHT)
            self:setHeroVar("Target", {Obj=nil, Id=0})
            return false
        else
            self:setHeroVar("Target", myTarget)
            local Allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
            for _, friend in pairs(Allies) do
                local friendID = friend:GetPlayerID()
                if self.pID ~= friendID and gHeroVar.HasID(friendID) and GetUnitToUnitDistance(myTarget.Obj, friend)/friend:GetCurrentMovementSpeed() <= 5.0 then
                    utils.myPrint("getting help from ", utils.GetHeroName(friend), " in fighting enemyID: ", myTarget.Id)
                    gHeroVar.SetVar(friendID, "Target", myTarget)
                end
            end
            
            local pLoc = enemyData.PredictedLocation(myTarget.Id, GetHeroLastSeenInfo(myTarget.Id).time)
            if pLoc then
                item_usage.UseMovementItems()
                bot:Action_MoveToLocation(pLoc)
                return true
            end
        end
    end

    -- otherwise use the weakest hero
    if utils.NotNilOrDead(weakestHero) then
        local bFight = (score > 1) or weakestHero:HasModifier("modifier_bloodseeker_rupture")

        if bFight then
            if self:HasAction(ACTION_FIGHT) == false then
                utils.myPrint(" - Fighting ", utils.GetHeroName(weakestHero))
                self:AddAction(ACTION_FIGHT)
                self:setHeroVar("Target", {Obj=weakestHero, Id=weakestHero:GetPlayerID()})
            end

            if utils.GetHeroName(weakestHero) ~= utils.GetHeroName(getHeroVar("Target").Obj) then
                utils.myPrint(" - Fight Change - Fighting ", utils.GetHeroName(weakestHero))
                self:setHeroVar("Target", {Obj=weakestHero, Id=weakestHero:GetPlayerID()})
            end
            
            local Allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
            for _, friend in pairs(Allies) do
                local friendID = friend:GetPlayerID()
                if self.pID ~= friendID and gHeroVar.HasID(friendID) and GetUnitToUnitDistance(bot, friend)/friend:GetCurrentMovementSpeed() <= 5.0 then
                    utils.myPrint("getting help from ", utils.GetHeroName(friend), " in fighting: ", utils.GetHeroName(weakestHero))
                    gHeroVar.SetVar(friendID, "Target", {Obj=weakestHero, Id=weakestHero:GetPlayerID()})
                end
            end
            
            return true
        end
    end

    -- if we have a gank target
    local gankTarget = self:getHeroVar("GankTarget")
    if utils.ValidTarget(gankTarget) then
        bot:Action_AttackUnit(gankTarget.Obj, true)
        return true
    end

    self:RemoveAction(ACTION_FIGHT)
    self:setHeroVar("Target", {Obj=nil, Id=0})
    return false
end

function X:Determine_DoAlliesNeedHelp(bot)
    return false;
end

function X:Determine_ShouldIPushLane(bot)
    if #nearbyEnemyTowers == 0 then
        return false
    end
    
    if ( nearbyEnemyTowers[1]:GetHealth() / nearbyEnemyTowers[1]:GetMaxHealth() ) < 0.1 then
        self:setHeroVar("ShouldPush", true)
        return true
    end

    if #nearbyAlliedCreep > 0 and #nearbyEnemyHeroes == 0 then
        self:setHeroVar("ShouldPush", true)
        return true
    end

    return false
end

function X:Determine_ShouldIDefendLane(bot)
    return global_game_state.DetectEnemyPush()
end

function X:Determine_ShouldGank(bot)
    if getHeroVar("Role") == ROLE_ROAMER or (getHeroVar("Role") == ROLE_JUNGLER and self:IsReadyToGank(bot)) then
        return ganking_generic.FindTarget(bot)
    end
    return false
end

function X:IsReadyToGank(bot)
    return false
end

function X:Determine_ShouldRoam(bot)
    return false
end

function X:Determine_ShouldIChangeLane(bot)
    -- don't change lanes for first 6 minutes
    if DotaTime() < 60*6 then return false end
    
    local LaneChangeTimer = self:getHeroVar("LaneChangeTimer")
    local bCheck, newTime = utils.TimePassed(LaneChangeTimer, 3.0)
    if bCheck then
        self:setHeroVar("LaneChangeTimer", newTime)
        return true
    end
    return false
end

function X:Determine_ShouldJungle(bot)
    local bRoleJungler = self:getHeroVar("Role") == ROLE_JUNGLER
    --FIXME: Implement other reasons when/why we would want to jungle
    return bRoleJungler
end

function X:Determine_ShouldTeamRoshan(bot)
    local enemyIDs = GetTeamPlayers(utils.GetOtherTeam())
    
    local numAlive = 0
    for _, id in ipairs(enemyIDs) do
        if IsHeroAlive(id) then
            numAlive = numAlive + 1
        end
    end

	local isRoshanAlive = DotaTime() - GetRoshanKillTime() > 660 -- max 11 minutes respawn time of roshan

    if (numAlive < 3 and (GetRoshanKillTime == 0 or isRoshanAlive)) then -- FIXME: Implement
        if self:HasAction(ACTION_ROSHAN) == false then
            utils.myPrint(" - Going to Fight Roshan")
            self:AddAction(ACTION_ROSHAN)
        end
    end
    return false
end

function X:Determine_ShouldGetRune(bot)
    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then return false end

    for _,r in pairs(constants.RuneSpots) do
        local loc = GetRuneSpawnLocation(r)
        if utils.GetDistance(bot:GetLocation(), loc) < 1200 and GetRuneStatus(r) == RUNE_STATUS_AVAILABLE then
            if self:HasAction(ACTION_RUNEPICKUP) == false then
                utils.myPrint(" STARTING TO GET RUNE ")
                self:AddAction(ACTION_RUNEPICKUP)
                setHeroVar("RuneTarget", r)
                setHeroVar("RuneLoc", loc)
            end
        end
    end

    local bRet = self:DoGetRune(bot) -- grab a rune if we near one as we jungle
    if bRet then return bRet end
end

function X:Determine_ShouldWard(bot)
    local WardCheckTimer = self:getHeroVar("WardCheckTimer")
    local bCheck = true
    local newTime = GameTime()
    if WardCheckTimer ~= nil then
        bCheck, newTime = utils.TimePassed(WardCheckTimer, 0.5)
    end
    if bCheck then
        self:setHeroVar("WardCheckTimer", newTime)
        local ward = item_usage.HaveWard("item_ward_observer")
        if ward then
            local alliedMapWards = GetUnitList(UNIT_LIST_ALLIED_WARDS)
            if #alliedMapWards < 2 then --FIXME: don't hardcode.. you get more wards then you can use this way
                local wardLoc = utils.GetWardingSpot(self:getHeroVar("CurLane"))
                
                for _, value in ipairs(alliedMapWards) do
                    -- FIXME: Consider ward expiration time
                    if wardLoc ~= nil and value:GetLocation() == wardLoc then
                        return false
                    end
                end
                
                if wardLoc ~= nil and utils.EnemiesNearLocation(bot, wardLoc, 2000) < 2 then
                    self:setHeroVar("WardLocation", wardLoc)
                    utils.InitPath()
                    if self:HasAction(ACTION_WARD) == false then
                        utils.myPrint("Going to place an Observer Ward")
                        self:AddAction(ACTION_WARD)
                    end
                    return true
                end
            end
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
    if ( dist <= 1.0 ) then
        self:RemoveAction(ACTION_MOVING);
        return nil;
    end
    return loc;
end

function X:DoRetreat(bot, reason)

    if reason == constants.RETREAT_FOUNTAIN then
        if ( self:HasAction(ACTION_RETREAT) == false ) then
            utils.myPrint("DoRetreat - STARTING TO RETREAT TO FOUNTAIN")
            self:AddAction(ACTION_RETREAT)
            retreat_generic.OnStart(bot)
        end

        -- if we healed up enough, change our reason for retreating
        if bot:DistanceFromFountain() >= 5000 and (bot:GetHealth()/bot:GetMaxHealth()) > 0.6 and (bot:GetMana()/bot:GetMaxMana()) > 0.6 then
            utils.myPrint("DoRetreat - Upgrading from RETREAT_FOUNTAIN to RETREAT_DANGER")
            self:setHeroVar("IsRetreating", true)
            self:setHeroVar("RetreatReason", constants.RETREAT_DANGER)
            return true
        end

        if bot:DistanceFromFountain() > 0 or (bot:GetHealth()/bot:GetMaxHealth()) < 1.0 or (bot:GetMana()/bot:GetMaxMana()) < 1.0 then
            retreat_generic.Think(bot, utils.Fountain(GetTeam()))
            return true
        end
        --utils.myPrint("DoRetreat - RETREAT FOUNTAIN End".." - DfF: ".. bot:DistanceFromFountain()..", H: "..bot:GetHealth())
    elseif reason == constants.RETREAT_DANGER then
        if ( self:HasAction(ACTION_RETREAT) == false ) then
            utils.myPrint("STARTING TO RETREAT b/c OF DANGER")
            self:AddAction(ACTION_RETREAT)
            retreat_generic.OnStart(bot)
        end

        if self:getHeroVar("IsRetreating") then
            if bot:TimeSinceDamagedByAnyHero() < 3.0 or
                (bot:DistanceFromFountain() < 5000 and (bot:GetHealth()/bot:GetMaxHealth()) < 1.0) or
                (bot:DistanceFromFountain() >= 5000 and (bot:GetHealth()/bot:GetMaxHealth()) < 0.6) then
                retreat_generic.Think(bot)
                return true
            end
        end
        --utils.myPrint("DoRetreat - RETREAT DANGER End".." - DfF: "..bot:DistanceFromFountain()..", H: "..bot:GetHealth())
    elseif reason == constants.RETREAT_TOWER then
        if ( self:HasAction(ACTION_RETREAT) == false ) then
            utils.myPrint("STARTING TO RETREAT b/c of tower damage")
            self:AddAction(ACTION_RETREAT)
        end

        local mypos = bot:GetLocation()
        if self:getHeroVar("TargetOfRunAwayFromCreepOrTower") == nil then
            --set the target to go back
            local bInLane, cLane = utils.IsInLane()
            if bInLane then
                self:setHeroVar("TargetOfRunAwayFromCreepOrTower", GetLocationAlongLane(cLane,Max(utils.PositionAlongLane(bot, cLane)-0.05, 0.0)))
            elseif ( GetTeam() == TEAM_RADIANT ) then
                cLane = self:getHeroVar("CurLane")
                if cLane == LANE_BOT then
                    self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1], mypos[2] - 300))
                elseif cLane == LANE_TOP then
                    self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] - 400, mypos[2]))
                else
                    self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] - 300, mypos[2] - 300))
                end
            else
                cLane = self:getHeroVar("CurLane")
                if cLane == LANE_BOT then
                    self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] + 300, mypos[2]))
                elseif cLane == LANE_TOP then
                    self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1], mypos[2] + 400))
                else
                    self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] + 300, mypos[2] + 300))
                end
            end
        end

        local rLoc = self:getHeroVar("TargetOfRunAwayFromCreepOrTower")
        local d = GetUnitToLocationDistance(bot, rLoc)
        if d > 50 and utils.IsTowerAttackingMe(2.0) then
            if utils.IsInLane(bot) then
                bot:Action_MoveToLocation(rLoc)
            else
                utils.MoveSafelyToLocation(bot, rLoc)
            end
            return true
        end
        --utils.myPrint("DoRetreat - RETREAT TOWER End")
    elseif reason == constants.RETREAT_CREEP then
        if ( self:HasAction(ACTION_RETREAT) == false ) then
            utils.myPrint("STARTING TO RETREAT b/c of creep damage")
            self:AddAction(ACTION_RETREAT)
        end

        local mypos = bot:GetLocation()
        if self:getHeroVar("TargetOfRunAwayFromCreepOrTower") == nil then
            --set the target to go back
            local bInLane, cLane = utils.IsInLane()
            if bInLane then
                utils.myPrint("Creep Retreat - InLane: ", cLane)
                self:setHeroVar("TargetOfRunAwayFromCreepOrTower", GetLocationAlongLane(cLane, Max(utils.PositionAlongLane(bot, cLane)-0.04, 0.0)))
            elseif ( GetTeam() == TEAM_RADIANT ) then
                utils.myPrint("Creep Retreat - Not InLane - Radiant")
                self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] - 300, mypos[2] - 300))
            else
                utils.myPrint("Creep Retreat - Not InLane - Dire")
                self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] + 300, mypos[2] + 300))
            end
        end

        local rLoc = self:getHeroVar("TargetOfRunAwayFromCreepOrTower")
        --utils.myPrint("Creep Retreat - Destination - <",rLoc[1],", ",rLoc[2],">")
        local d = GetUnitToLocationDistance(bot, rLoc)
        if d > 50 and utils.IsCreepAttackingMe(2.0) then
            if utils.IsInLane(bot) then
                bot:Action_MoveToLocation(rLoc)
            else
                utils.MoveSafelyToLocation(bot, rLoc)
            end
            return true
        end
        --utils.myPrint("DoRetreat - RETREAT CREEP End")
    end

    -- If we got here, we are done retreating
    --utils.myPrint("done retreating from reason: "..reason)
    self:RemoveAction(ACTION_RETREAT)
    self:setHeroVar("TargetOfRunAwayFromCreepOrTower", nil)
    self:setHeroVar("IsRetreating", false)
    self:setHeroVar("RetreatReason", nil)
    return true
end

function X:DoFight(bot)
    local target = self:getHeroVar("Target")
    
    if target.Id > 0 and IsHeroAlive(target.Id) then
        if utils.ValidTarget(target) then
            local Towers = bot:GetNearbyTowers(750, true)
            if Towers ~= nil and #Towers == 0 then
                if target.Obj:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                    item_usage.UseMovementItems()
                    bot:Action_MoveToUnit(target.Obj)
                else
                    bot:Action_AttackUnit(target.Obj, true)
                end
                return true
            else
                local towerDmgToMe = 0
                local myDmgToTarget = bot:GetEstimatedDamageToTarget( true, target.Obj, 5.0, DAMAGE_TYPE_ALL )
                for _, tow in pairs(Towers) do
                    if GetUnitToLocationDistance( bot, tow:GetLocation() ) < 750 then
                        towerDmgToMe = towerDmgToMe + tow:GetEstimatedDamageToTarget( false, bot, 5.0, DAMAGE_TYPE_PHYSICAL )
                    end
                end
                if myDmgToTarget > target.Obj:GetHealth() and towerDmgToMe < (bot:GetHealth() + 100) then
                    --print(utils.GetHeroName(bot), " - we are tower diving for the kill")
                    if target.Obj:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                        bot:Action_MoveToUnit(target.Obj)
                    else
                        bot:Action_AttackUnit(target.Obj, true)
                    end
                    return true
                else
                    self:RemoveAction(ACTION_FIGHT)
                    self:setHeroVar("Target", {Obj=nil, Id=0})
                    return false
                end
            end
        else -- target alive but we don't see it
            local timeSinceSeen = GetHeroLastSeenInfo(target.Id).time
            if timeSinceSeen > 3.0 then
                self:RemoveAction(constants.ACTION_FIGHT)
                setHeroVar("Target", {Obj=nil, Id=0})
                return false
            else
                local pLoc = enemyData.PredictedLocation(target.Id, timeSinceSeen)
                if pLoc then
                    item_usage.UseMovementItems()
                    bot:Action_MoveToLocation(pLoc)
                    return true
                end
            end
        end
    else
        utils.AllChat("Suck it!")
        self:RemoveAction(ACTION_FIGHT)
        self:setHeroVar("Target", {Obj=nil, Id=0})
    end

    return false
end

function X:DoDefendAlly(bot)
    return true
end

function X:DoPushLane(bot)

    local Shrines = bot:GetNearbyShrines(750, true)
    local Barracks = bot:GetNearbyBarracks(750, true)
    local Ancient = GetAncient(utils.GetOtherTeam())
    
    if #nearbyEnemyTowers == 0 and #Shrines == 0 and #Barracks == 0 then
        if utils.NotNilOrDead(Ancient) and GetUnitToLocationDistance(bot, Ancient:GetLocation()) < bot:GetAttackRange() and
            (not Ancient:HasModifier("modifier_fountain_glyph")) then
            bot:Action_AttackUnit(Ancient, true)
            return true
        end
        return false
    end

    if #nearbyEnemyCreep > 0 then
        return false
    end
    
    if #nearbyEnemyTowers > 0 then
        for _, tower in ipairs(nearbyEnemyTowers) do
            if utils.NotNilOrDead(tower) and (not tower:HasModifier("modifier_fountain_glyph")) then
                if GetUnitToUnitDistance(tower, bot) < bot:GetAttackRange() then
                    bot:Action_AttackUnit(tower, true)
                else
                    bot:Action_MoveToUnit(tower)
                end
                return true
            end
        end
    end
    
    if #Barracks > 0 then
        for _, barrack in ipairs(Barracks) do
            if utils.NotNilOrDead(barrack) and (not barrack:HasModifier("modifier_fountain_glyph")) then
                if GetUnitToUnitDistance(barrack, bot) < bot:GetAttackRange() then
                    bot:Action_AttackUnit(barrack, true)
                else
                    bot:Action_MoveToUnit(barrack)
                end
                return true
            end
        end
    end
    
    if #Shrines > 0 then
        for _, shrine in ipairs(Shrines) do
            if utils.NotNilOrDead(shrine) and (not shrine:HasModifier("modifier_fountain_glyph")) then
                if GetUnitToUnitDistance(shrine, bot) < bot:GetAttackRange() then
                    bot:Action_AttackUnit(shrine, true)
                else
                    bot:Action_MoveToUnit(shrine)
                end
                return true
            end
        end
    end
    
    return false
end

function X:DoDefendLane(bot, lane, building, numEnemies)
    utils.myPrint("Need to defend lane: ", lane, ", building: ", building, " against numEnemies: ", numEnemies)
    -- calculate num of bots that can defend
    local numAlliesCanReachBuilding = 0
    local listAllies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    local hBuilding = buildings_status.GetHandle(GetTeam(), building)
    for _, ally in ipairs(listAllies) do
        --FIXME - Implement
        local distFromBuilding = GetUnitToUnitDistance(ally, hBuilding)
    end
    return numAlliesCanReachBuilding >= (numEnemies - 1)
end

function X:DoGank(bot)
    local gankTarget = self:getHeroVar("GankTarget")
    if gankTarget.Id > 0 and IsHeroAlive(gankTarget.Id) then
        if ( self:HasAction(ACTION_GANKING) == false ) then
            utils.myPrint(" STARTING TO GANK ")
            self:AddAction(ACTION_GANKING)
        end
        
        local bStillGanking = true
        local bTimeToKill = ganking_generic.ApproachTarget(bot, gankTarget)
        if bTimeToKill then
            bStillGanking = ganking_generic.KillTarget(bot, gankTarget)
        end
        
        if not bStillGanking then
            utils.myPrint("clearing gank")
            self:RemoveAction(ACTION_GANKING)
            self:setHeroVar("GankTarget", {Obj=nil, Id=0})
            self:setHeroVar("Target", {Obj=nil, Id=0})
        end
    else
        if utils.ValidTarget(gankTarget) then
            utils.myPrint("clearing gank - target [Id:"..gankTarget.Id.."] Health: ", gankTarget.Obj:GetHealth(), ", Alive: ", IsHeroAlive(gankTarget.Id))
        else
            utils.myPrint("clearing gank - target [Id:"..gankTarget.Id.."] Alive: ", IsHeroAlive(gankTarget.Id))
        end
        self:RemoveAction(ACTION_GANKING)
        self:setHeroVar("GankTarget", {Obj=nil, Id=0})
        self:setHeroVar("Target", {Obj=nil, Id=0})
    end

    return bStillGanking
end

function X:DoRoam(bot)
    return true
end

function X:DoJungle(bot)
    if ( self:HasAction(ACTION_JUNGLING) == false ) then
        utils.myPrint(" STARTING TO JUNGLE ")
        self:AddAction(ACTION_JUNGLING)
        jungling_generic.OnStart(bot)
    end

    jungling_generic.Think(bot)

    return true
end

function X:DoRoshan(bot)
    --FIXME: Implement Roshan fight and clear action stack when he dead
    self:RemoveAction(ACTION_ROSHAN)
    return true
end

function X:AnalyzeLanes(nLane)
    if utils.InTable(nLane, self:getHeroVar("CurLane")) then
        --[[
        if GetTeam() == TEAM_RADIANT then
            if #nLane >= 3 then
                if self:getHeroVar("Role") == constants.ROLE_MID then self:setHeroVar("CurLane", LANE_MID)
                elseif self:getHeroVar("Role") == constants.ROLE_OFFLANE then self:setHeroVar("CurLane", LANE_TOP)
                else
                    self:setHeroVar("CurLane", LANE_BOT)
                end
            end
        else
            if #nLane >= 3 then
                if self:getHeroVar("Role") == constants.ROLE_MID then self:setHeroVar("CurLane", LANE_MID)
                elseif self:getHeroVar("Role") == constants.ROLE_OFFLANE then self:setHeroVar("CurLane", LANE_BOT)
                else
                    self:setHeroVar("CurLane", LANE_TOP)
                end
            end
        end
        utils.myPrint("Lanes are evenly pushed, going back to my lane: ", self:getHeroVar("CurLane"))
        --]]
        return false
    end
    
    if #nLane > 1 then
        local newLane = nLane[RandomInt(1, #nLane)]
        utils.myPrint("Randomly switching to lane: ", newLane)
        self:setHeroVar("CurLane", newLane)
    elseif #nLane == 1 then
        utils.myPrint("Switching to lane: ", nLane[1])
        self:setHeroVar("CurLane", nLane[1])
    else
        utils.myPrint("Switching to lane: ", LANE_MID)
        self:setHeroVar("CurLane", LANE_MID)
    end
    return false
end

function X:DoChangeLane(bot)
    local listBuildings = global_game_state.GetLatestVulnerableEnemyBuildings()
    local nLane = {}
    
    -- check Tier 1 towers
    if utils.InTable(listBuildings, 1) then table.insert(nLane, LANE_TOP) end
    if utils.InTable(listBuildings, 4) then table.insert(nLane, LANE_MID) end
    if utils.InTable(listBuildings, 7) then table.insert(nLane, LANE_BOT) end
    -- if we have found a standing Tier 1 tower, end
    if #nLane > 0 then
        return self:AnalyzeLanes(nLane)
    end
        
    -- check Tier 2 towers
    if utils.InTable(listBuildings, 2) then table.insert(nLane, LANE_TOP) end
    if utils.InTable(listBuildings, 5) then table.insert(nLane, LANE_MID) end
    if utils.InTable(listBuildings, 8) then table.insert(nLane, LANE_BOT) end
    -- if we have found a standing Tier 2 tower, end
    if #nLane > 0 then
        return self:AnalyzeLanes(nLane)
    end
    
    -- check Tier 3 towers & buildings
    if utils.InTable(listBuildings, 3) or utils.InTable(listBuildings, 12) or utils.InTable(listBuildings, 13) then table.insert(nLane, LANE_TOP) end
    if utils.InTable(listBuildings, 6) or utils.InTable(listBuildings, 14) or utils.InTable(listBuildings, 15) then table.insert(nLane, LANE_MID) end
    if utils.InTable(listBuildings, 9) or utils.InTable(listBuildings, 16) or utils.InTable(listBuildings, 17) then table.insert(nLane, LANE_BOT) end
    -- if we have found a standing Tier 3 tower, end
    if #nLane > 0 then
        return self:AnalyzeLanes(nLane)
    end
    
    return false
end

function X:DoGetRune(bot)
    local runeLoc = self:getHeroVar("RuneLoc")
    if runeLoc == nil then
        self:setHeroVar("RuneTarget", nil)
        self:setHeroVar("RuneLoc", nil)
        self:RemoveAction(ACTION_RUNEPICKUP)
        return false
    end
    local dist = utils.GetDistance(bot:GetLocation(), runeLoc)
    local timeInMinutes = math.floor(DotaTime() / 60)
    local seconds = DotaTime() % 60
	
    if dist > 500 and timeInMinutes % 2 == 1 and seconds > 54 and self:getHeroVar("Role") ~= ROLE_HARDCARRY then 
        bot:Action_MoveToLocation(runeLoc)
        return true
    else
        local rt = self:getHeroVar("RuneTarget")
        if rt ~= nil and GetRuneStatus(rt) ~= RUNE_STATUS_MISSING then
            bot:Action_PickUpRune(self:getHeroVar("RuneTarget"))
            return true
        end
        self:setHeroVar("RuneTarget", nil)
        self:setHeroVar("RuneLoc", nil)
        self:RemoveAction(ACTION_RUNEPICKUP)
    end
    return false
end

function X:DoWard(bot, wardType)
    local wardType = wardType or "item_ward_observer"
    local dest = self:getHeroVar("WardLocation")
    if dest ~= nil then
        local dist = GetUnitToLocationDistance(bot, dest)
        if dist <= constants.WARD_CAST_DISTANCE then
            local ward = item_usage.HaveWard(wardType)
            if ward then
                bot:Action_UseAbilityOnLocation(ward, dest)
                U.InitPath()
                self:RemoveAction(ACTION_WARD)
                self:setHeroVar("WardLocation", nil)
                self:setHeroVar("WardPlacedTimer", GameTime())
                return true
            end
        else
            U.MoveSafelyToLocation(bot, dest)
            return true
        end
    else
        utils.myPrint("ERROR - BAD WARD LOC")
    end

    return false
end

function X:DoLane(bot)
    if ( self:HasAction(ACTION_LANING) == false ) then
        utils.myPrint(" STARTING TO LANE ")
        self:AddAction(ACTION_LANING)
        laning_generic.OnStart(bot)
    end

    laning_generic.Think(bot, nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)

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

function X:SaveLocation(bot)
    if self.Init then
        self:setHeroVar("LastLocation", bot:GetLocation())
    end
end

return X;
