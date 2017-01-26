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
require( GetScriptDirectory().."/fighting" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

enemyData = require( GetScriptDirectory().."/enemy_data" )

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
        utils.myPrint("Action Transition: "..self:getPrevAction().." --> "..self:getCurrentAction())
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
    if GetTeamMember( GetTeam(), 1 ) == nil or GetTeamMember( GetTeam(), 5 ) == nil then return end

    self.pID = bot:GetPlayerID() -- do this to reduce calls to bot:GetPlayerID() in the future
    gHeroVar.InitHeroVar(self.pID)

    self:setHeroVar("Self", self)
    self:setHeroVar("Name", utils.GetHeroName(bot))
    self:setHeroVar("LastCourierThink", -1000.0)
    self:setHeroVar("LastLevelUpThink", -1000.0)
    self:setHeroVar("LastStuckCheck", -1000.0)
    self:setHeroVar("StuckCounter", 0)
    self:setHeroVar("LastLocation", Vector(0, 0, 0))

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

    ---[[
    -- UPDATE GLOBAL INFO --
    checkLevel, newTime = utils.TimePassed(gHeroVar.GetGlobalVar("PrevEnemyUpdateTime"), 5.0)
    if checkLevel then
        gHeroVar.SetGlobalVar("PrevEnemyUpdateTime", newTime)
        enemyData.UpdateEnemyInfo()
    end

    -- DEBUG ENEMY DUMP
    -- Dump enemy info every 15 seconds
    checkLevel, newTime = utils.TimePassed(gHeroVar.GetGlobalVar("PrevEnemyDataDump"), 15.0)
    if checkLevel then
        gHeroVar.SetGlobalVar("PrevEnemyDataDump", newTime)
        --enemyData.PrintEnemyInfo()
    end

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

    --FIXME: Is this the right place to do this???
    utils.CourierThink(bot)
    -- FIXME - right place?
    self:ConsiderItemUse()

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

    -- Check if our bot was trying to harass with an ability using Out of Range Casting variable
    -- Give them 2.0 seconds to use it or fall through to further logic
    local oorC = self:getHeroVar("OutOfRangeCasting")
    if bot:GetCurrentActionType() == BOT_ACTION_TYPE_USE_ABILITY and ( oorc ~= nil and (oorC-GameTime()) < 2.0 ) then
        utils.myPrint("CLEARING OORC ABILITY USE")
        bot:Action_ClearActions()
        return
    end

    if ( self:GetAction() == ACTION_RETREAT ) then
        local bRet = self:DoRetreat(bot, self:getHeroVar("RetreatReason"))
        if bRet then return end
    end
    local safe = self:Determine_ShouldIRetreat(bot)
    if safe ~= nil then
        self:setHeroVar("RetreatReason", safe)
        local bRet = self:DoRetreat(bot, safe)
        if bRet then return end
    end

    local bRet = self:ConsiderAbilityUse()
    if bRet then return end

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

    if ( self:Determine_ShouldIPushLane(bot) ) then
        local bRet = self:DoPushLane(bot)
        if bRet then return end
    end

    if ( self:Determine_ShouldIDefendLane(bot) ) then
        local bRet = self:DoDefendLane(bot)
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

-- Pure Abstract Function - Designed for Overload
function X:ConsiderAbilityUse()
    return false
end
-------------------------------------------------

function X:ConsiderItemUse()
    local timeInfo = item_usage.UseItems()
    if timeInfo ~= nil then
        print( "X:ConsiderItemUse() TimeInfo: ", timeInfo )
    end
end

function X:Determine_ShouldUseGlyph(bot)
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
            if self:getHeroVar("Target") == nil or pushing == nil or pushing == false then
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
            if self:getHeroVar("Target") == nil or pushing == nil or pushing == false then
                return constants.RETREAT_CREEP
            end
        end
        return nil
    end

    local Enemies = bot:GetNearbyHeroes(1500, true, BOT_MODE_NONE)
    local Allies = bot:GetNearbyHeroes(1500, false, BOT_MODE_NONE)
    local Towers = bot:GetNearbyTowers(900, true)

    local nEn = 0
    if Enemies ~= nil then
        nEn = #Enemies
    end

    local nAl = 0

    if Allies ~= nil then
        for _,ally in pairs(Allies) do
            if utils.NotNilOrDead(ally) then
                nAl = nAl + 1
            end
        end
    end

    local nTo = 0
    if Towers ~= nil then
        nTo = #Towers
    end

    if ((bot:GetHealth()/bot:GetMaxHealth()) < 0.33 and self:GetAction() ~= ACTION_JUNGLING) or
        (bot:GetMana()/bot:GetMaxMana() < 0.07 and self:getPrevAction() == ACTION_LANING) then
        return constants.RETREAT_FOUNTAIN
    end

    if nAl < 2 then
        local MaxStun = 0

        --enemyData.GetEnemyTeamSlowDuration()/2.0

        for _,enemy in pairs(Enemies) do
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
        for _, enemy in pairs(Enemies) do
            if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.4 then
                local enemyManaRatio = enemy:GetMana()/enemy:GetMaxMana()
                local pDamage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_PHYSICAL)
                local mDamage = bot:GetActualDamage(enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_MAGICAL), DAMAGE_TYPE_MAGICAL)
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
        if self:getHeroVar("Target") == nil or pushing ~= true then
            return constants.RETREAT_CREEP
        end
    end

    return nil
end

function X:Determine_ShouldIFighting(bot)
    local friendsTarget = nil

    local Allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    local bFriendFighting = false
    for _, friend in pairs(Allies) do
        local friendID = friend:GetPlayerID()
        if self.pID ~= friendID and gHeroVar.HasID(friendID) and GetUnitToUnitDistance(bot, friend) <= 3800 then
            --print("Me: ", self.pID, ", Friend: ", friendID, ", Dist: ", GetUnitToUnitDistance(bot, friend))
            local friendsTarget = gHeroVar.GetVar(friendID, "Target")
            if friendsTarget ~= nil then
                bFriendFighting = true
                --print(self:getHeroVar("Name").." helping out my Buddy "..utils.GetHeroName(friend).." get a kill on "..utils.GetHeroName(friendsTarget))
                if GetUnitToUnitDistance(bot, friendsTarget) < 1000 then
                    self:setHeroVar("HelpingFriend", friend:GetPlayerID())
                    if self:HasAction(ACTION_FIGHT) == false then
                        self:AddAction(ACTION_FIGHT)
                    end
                else
                    bot:Action_MoveToUnit(friendsTarget)
                end
            end
        end
    end

    myTarget = self:getHeroVar("Target")
    if myTarget and ( not myTarget:IsAlive() ) then
        self:RemoveAction(ACTION_FIGHT)
        self:setHeroVar("Target", nil)
        self:setHeroVar("GankTarget", nil)
    end

    local myFriend = self:getHeroVar("HelpingFriend")
    if myFriend and gHeroVar.GetVar(myFriend, "Target") == nil then
        self:RemoveAction(ACTION_FIGHT)
        self:setHeroVar("Target", nil)
        self:setHeroVar("HelpingFriend", nil)
    end

    local weakestHero, score = fighting.FindTarget(1200)

    if utils.NotNilOrDead(weakestHero) then
        local bFight = (score > 1) or weakestHero:HasModifier("modifier_bloodseeker_rupture")

        if bFight then
            if self:HasAction(ACTION_FIGHT) == false then
                utils.myPrint(" - Fighting ", utils.GetHeroName(weakestHero))
                self:AddAction(ACTION_FIGHT)
                self:setHeroVar("Target", weakestHero)
            end

            if weakestHero ~= getHeroVar("Target") then
                utils.myPrint(" - Fight Change - Fighting ", utils.GetHeroName(weakestHero))
                self:setHeroVar("Target", weakestHero)
            end
            
            return true
        end
    end

    weakestHero = getHeroVar("Target") or friendsTarget
    if weakestHero ~= nil then
        if (not utils.NotNilOrDead(weakestHero)) then
            if (not weakestHero:CanBeSeen()) and weakestHero:GetTimeSinceLastSeen() > 3.0 then
                utils.myPrint(" - Stopping my fight... lost sight of hero")
                self:RemoveAction(ACTION_FIGHT)
                self:setHeroVar("Target", nil)
                return false
            else
                self:setHeroVar("Target", weakestHero)
                local lastLoc = weakestHero:GetLastSeenLocation()
                if utils.GetOtherTeam() == TEAM_DIRE then
                    local prob1 = GetUnitPotentialValue(weakestHero, Vector(lastLoc[1] + 500, lastLoc[2]), 1000)
                    local prob2 = GetUnitPotentialValue(weakestHero, Vector(lastLoc[1], lastLoc[2] + 500), 1000)
                    if prob1 > 180 and prob1 > prob2 then
                        item_usage.UseMovementItems()
                        bot:Action_MoveToLocation(Vector(lastLoc[1] + 500, lastLoc[2]))
                        return true
                    elseif prob2 > 180 then
                        item_usage.UseMovementItems()
                        bot:Action_MoveToLocation(Vector(lastLoc[1], lastLoc[2] + 500))
                        return true
                    end
                else
                    local prob1 = GetUnitPotentialValue(weakestHero, Vector(lastLoc[1] - 500, lastLoc[2]), 1000)
                    local prob2 = GetUnitPotentialValue(weakestHero, Vector(lastLoc[1], lastLoc[2] - 500), 1000)
                    if prob1 > 180 and prob1 > prob2 then
                        item_usage.UseMovementItems()
                        bot:Action_MoveToLocation(Vector(lastLoc[1] - 500, lastLoc[2]))
                        return true
                    elseif prob2 > 180 then
                        item_usage.UseMovementItems()
                        bot:Action_MoveToLocation(Vector(lastLoc[1], lastLoc[2] - 500))
                        return true
                    end
                end
            end
        end

        if (GameTime() - bot:GetLastAttackTime()) > 5.0 and weakestHero:GetCurrentMovementSpeed() >= bot:GetCurrentMovementSpeed() then
            utils.myPrint(" - Stopping my fight... done chasing")
            self:RemoveAction(ACTION_FIGHT)
            self:setHeroVar("Target", nil)
            return false
        end
    end

    if self:getHeroVar("GankTarget") ~= nil then
        bot:Action_AttackUnit(self:getHeroVar("GankTarget"), true)
        return true
    end

    self:RemoveAction(ACTION_FIGHT)
    self:setHeroVar("Target", nil)
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
    local me = getHeroVar("Self")
    if getHeroVar("Role") == ROLE_ROAMER or (getHeroVar("Role") == ROLE_JUNGLER and me:IsReadyToGank(bot)) then
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

function X:Determine_ShouldJungle(bot)
    local bRoleJungler = self:getHeroVar("Role") == ROLE_JUNGLER
    --FIXME: Implement other reasons when/why we would want to jungle
    return bRoleJungler
end

function X:Determine_ShouldTeamRoshan(bot)
    if (false) then -- FIXME: Implement
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
            end
        end
    end

    local bRet = self:DoGetRune(bot) -- grab a rune if we near one as we jungle
    if bRet then return bRet end
end

function X:Determine_ShouldWard(bot)
    local wardPlacedTimer = self:getHeroVar("WardPlacedTimer")

    local bCheck = true
    local newTime = GameTime()
    if wardPlacedTimer ~= nil then
        bCheck, newTime = utils.TimePassed(wardPlacedTimer, 0.5)
    end

    if bCheck then
        self:setHeroVar("WardPlacedTimer", newTime)
        local ward = item_usage.HaveWard("item_ward_observer")
        if ward then
            local alliedMapWards = GetUnitList(UNIT_LIST_ALLIED_WARDS)
            if #alliedMapWards < 2 then --FIXME: don't hardcode.. you get more wards then you can use this way
                local wardLoc = utils.GetWardingSpot(self:getHeroVar("CurLane"))
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
    --if reason == nil then return false end

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
            bot:Action_MoveToLocation(rLoc)
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
                self:setHeroVar("TargetOfRunAwayFromCreepOrTower", GetLocationAlongLane(cLane, Max(utils.PositionAlongLane(bot, cLane)-0.04, 0.0)))
            elseif ( GetTeam() == TEAM_RADIANT ) then
                self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] - 300, mypos[2] - 300))
            else
                self:setHeroVar("TargetOfRunAwayFromCreepOrTower", Vector(mypos[1] + 300, mypos[2] + 300))
            end
        end

        local rLoc = self:getHeroVar("TargetOfRunAwayFromCreepOrTower")
        local d = GetUnitToLocationDistance(bot, rLoc)
        if d > 50 and utils.IsCreepAttackingMe(3.0) then
            bot:Action_MoveToLocation(rLoc)
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
    if target ~= nil then
        if target:IsAlive() then
            local Towers = bot:GetNearbyTowers(750, true)
            if Towers ~= nil and #Towers == 0 then
                if target:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                    item_usage.UseMovementItems()
                    bot:Action_MoveToUnit(target)
                else
                    bot:Action_AttackUnit(target, true)
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
                        bot:Action_AttackUnit(target, true)
                    end
                    return true
                else
                    self:RemoveAction(ACTION_FIGHT)
                    self:setHeroVar("Target", nil)
                    return false
                end
            end
        else
            utils.AllChat("Suck it!")
            self:RemoveAction(ACTION_FIGHT)
            self:setHeroVar("Target", nil)
        end
    end
    return false
end

function X:DoDefendAlly(bot)
    return true
end

function X:DoPushLane(bot)
    self:setHeroVar("ShouldPush", true)

    local Towers = bot:GetNearbyTowers(750, true)
    local Shrines = bot:GetNearbyShrines(750, true)
    local Barracks = bot:GetNearbyBarracks(750, true)
    local Ancient = GetAncient(utils.GetOtherTeam())
    
    if #Towers == 0 and #Shrines == 0 and #Barracks == 0 then
        if utils.NotNilOrDead(Ancient) and GetUnitToLocationDistance(bot, Ancient:GetLocation()) < bot:GetAttackRange() and
            (not Ancient:IsAttackImmune()) then
            bot:Action_AttackUnit(Ancient, true)
            return true
        end
        return false
    end

    if #Towers > 0 then
        for _, tower in ipairs(Towers) do
            if utils.NotNilOrDead(tower) and (not tower:IsAttackImmune()) then
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
            if utils.NotNilOrDead(barrack) and (not barrack:IsAttackImmune()) then
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
            if utils.NotNilOrDead(shrine) and (not shrine:IsAttackImmune()) then
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

function X:DoDefendLane(bot)
    return true
end

function X:DoGank(bot)
    if ( self:HasAction(ACTION_GANKING) == false ) then
        utils.myPrint(" STARTING TO GANK ")
        self:AddAction(ACTION_GANKING)
    end

    local gankTarget = self:getHeroVar("GankTarget")
    local bStillGanking = true
    if gankTarget ~= nil then
        local bTimeToKill = ganking_generic.ApproachTarget(bot)
        if bTimeToKill then
            bStillGanking = ganking_generic.KillTarget(bot, gankTarget)
        end
    else
        bStillGanking = false
    end

    if not bStillGanking then
        utils.myPrint("clearing gank")
        self:RemoveAction(ACTION_GANKING)
        self:setHeroVar("GankTarget", nil)
        self:setHeroVar("Target", nil)
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

function X:DoGetRune(bot)
    local rt = getHeroVar("RuneTarget")
    if rt ~= nil and GetRuneStatus(rt) ~= RUNE_STATUS_MISSING then
        bot:Action_PickUpRune(getHeroVar("RuneTarget"))
        return true
    end
    self:setHeroVar("RuneTarget", nil)
    self:RemoveAction(ACTION_RUNEPICKUP)
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

function X:SaveLocation(bot)
    if self.Init then
        self:setHeroVar("LastLocation", bot:GetLocation())
    end
end

return X;
