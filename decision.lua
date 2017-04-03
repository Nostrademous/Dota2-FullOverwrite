-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/role" )
require( GetScriptDirectory().."/buildings_status" )
require( GetScriptDirectory().."/global_game_state" )
require( GetScriptDirectory().."/item_usage" )
require( GetScriptDirectory().."/debugging" )
require( GetScriptDirectory().."/modifiers" )

none = dofile( GetScriptDirectory().."/modes/none" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local think = require( GetScriptDirectory().."/think" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )
local enemyInfo = require( GetScriptDirectory().."/enemy_info" )

-------------------------------------------------------------------------------
-- BASE CLASS - DO NOT MODIFY THIS SECTION
-------------------------------------------------------------------------------

local X = { init = false, currentMode = none, currentModeValue = BOT_MODE_DESIRE_NONE, prevMode = none, abilityPriority = {} }

function X:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function X:getCurrentMode()
    return self.currentMode
end

function X:getCurrentModeValue()
    return self.currentModeValue
end

function X:getPrevMode()
    return self.prevMode
end

function X:ExecuteMode()
    if self.currentMode ~= self.prevMode then
        if self.currentMode:GetName() == nil then
            utils.pause("Unimplemented Mode: ", self.currentMode)
        end
        utils.myPrint("Mode Transition: "..self.prevMode:GetName():upper().." --> "..self.currentMode:GetName():upper())
        self.prevMode:OnEnd()
        self.currentMode:OnStart(self)
        self.prevMode = self.currentMode
    end

    self.currentMode:Think(GetBot())
end

function X:BeginMode(mode, value)
    if mode == self.currentMode then return end
    self.currentMode = mode
    self.currentModeValue = value
end

function X:ClearMode()
    self.currentMode = none
    self.currentModeValue = BOT_MODE_DESIRE_NONE
    self:ExecuteMode()
end

-------------------------------------------------------------------------------
-- CONVENIENCE FUNCTIONS 
-------------------------------------------------------------------------------

function X:setHeroVar(var, value)
    gHeroVar.SetVar(self.pID, var, value)
end

function X:getHeroVar(var)
    return gHeroVar.GetVar(self.pID, var)
end

-------------------------------------------------------------------------------
-- BASE INITIALIZATION - DO NOT OVER-LOAD
-------------------------------------------------------------------------------

function X:DoInit(bot)
    local allyList = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    if #allyList ~= 5 then return end

    gHeroVar.SetGlobalVar("LastCourierBurst", -1000.0)
    gHeroVar.SetGlobalVar("AOEZones", {})
    gHeroVar.SetGlobalVar("BadProjectiles", {})

    self.Name = utils.GetHeroName(bot)
    self.pID = bot:GetPlayerID() -- do this to reduce calls to bot:GetPlayerID() in the future
    gHeroVar.InitHeroVar(self.pID)

    bot.Name = utils.GetHeroName(bot)
    bot.SelfRef = self
    bot.lastModeThink = -1000.0
    
    self:setHeroVar("Self", self)
    self:setHeroVar("LastCourierThink", -1000.0)
    self:setHeroVar("LastLevelUpThink", -1000.0)
    self:setHeroVar("TeamBuy", {})
    self:setHeroVar("DoDefendLane", {})
    bot.IsRetreating = false
    self:setHeroVar("Target", nil)
    self:setHeroVar("RoamTarget", nil)
    
    local botDifficulty = bot:GetDifficulty()
    if botDifficulty == DIFFICULTY_EASY then
        self:setHeroVar("AbilityDelay", 0.75)
    elseif botDifficulty == DIFFICULTY_MEDIUM then
        self:setHeroVar("AbilityDelay", 0.45)
    elseif botDifficulty == DIFFICULTY_HARD then
        self:setHeroVar("AbilityDelay", 0.0)
    elseif botDifficulty == DIFFICULTY_UNFAIR then
        self:setHeroVar("AbilityDelay", 0.0)
    end

    role.GetRoles()
    if role.RolesFilled() then
        self.Init = true
        for i = 1,5,1 do
            local hero = GetTeamMember( i )
            if hero:GetPlayerID() == self.pID then
                cLane, cRole = role.GetLaneAndRole(GetTeam(), i)
                self:setHeroVar("CurLane", cLane)
                self:setHeroVar("Role", cRole)
                break
            end
        end
    end
    utils.myPrint(" initialized - Lane: ", self:getHeroVar("CurLane"), ", Role: ", self:getHeroVar("Role"))

    self:DoHeroSpecificInit(bot)
    if not bot.RetreatHealthPerc then bot.RetreatHealthPerc = 0.25 end
    
    local itemPurchase = dofile( GetScriptDirectory().."/itemPurchase/"..self.Name )
    setHeroVar("ItemPurchaseClass", itemPurchase)
    --utils.myPrint("Initializing Purchase Table: ", itemPurchase)
    itemPurchase:Init()
    
    local abilityUse = dofile( GetScriptDirectory().."/abilityUse/abilityUse_"..self.Name )
    setHeroVar("AbilityUsageClass", abilityUse)
end

-------------------------------------------------------------------------------
-- BASE THINK - DO NOT OVER-LOAD
-------------------------------------------------------------------------------

function X:Think(bot)
    -- if we are a human player, don't bother
    if not bot:IsBot() then return end

    if GetGameState() == GAME_STATE_PRE_GAME and not self.Init then
        self:DoInit(bot)
        return
    end

    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME then return end
    
    local tt = getHeroVar("Target")
    local rt = getHeroVar("RoamTarget")
    if tt ~= nil and (tt:IsNull() or not tt:IsAlive()) then
        utils.myPrint("Null Target")
        setHeroVar("Target", nil)
        bot.teamKill = false
        if self.currentMode:GetName() == "fighting" then
            self:ClearMode()
        end
        bot:Action_ClearActions(true)
        return
    end
    if rt ~= nil and (rt:IsNull() or not rt:IsAlive()) then
        utils.myPrint("Null RoamTarget")
        setHeroVar("RoamTarget", nil)
        bot:Action_ClearActions(true)
        return
    end
    
    -- level up abilities if time
    local checkLevel, newTime = utils.TimePassed(self:getHeroVar("LastLevelUpThink"), 2.0)
    if checkLevel then
        self:setHeroVar("LastLevelUpThink", newTime)
        while bot:GetAbilityPoints() > 0 do
            utils.LevelUp(bot, self.abilityPriority)
        end
    end

    -- check if jungle respawn timer was hit to repopulate our table
    jungle_status.checkSpawnTimer()
    
    -- use courier if needed (TO BE REPLACED BY TEAM LEVEL COURIER CONTROLS)
    utils.CourierThink(bot)

    -- update our global enemy info cache
    enemyInfo.BuildEnemyList()
    enemyData.UpdateEnemyInfo()
    
    --enemyInfo.PrintEnemyInfo()

    -- draw debug stuff (actual drawing is done on the first call in a frame)
    debugging.draw()
    
    -- check if I am alive, if not, short-circuit most stuff
    if not bot:IsAlive() then
        self:DoWhileDead(bot)
        return
    end
    
    -- update our building information
    buildings_status.Update()
    
    if utils.IsBusy(bot) then return end
    
    -- check if we should change lanes
    self:DoChangeLane(bot)
    
    -- consider purchasing items
    self:getHeroVar("ItemPurchaseClass"):ItemPurchaseThink(bot)
    
    -- consider using items
    if item_usage.UseItems() then return end
    
    -- if we are in fountain, heal fully
    if bot:HasModifier("modifier_fountain_aura_buff") then
        if bot:GetHealth()/bot:GetMaxHealth() < 0.95 then return end
        if bot:GetMana()/bot:GetMaxMana() < 0.95 then return end
    end
    
    -- if we are at active shrine
    if bot:HasModifier("modifier_filler_heal") then
        if bot:GetHealth()/bot:GetMaxHealth() < 1.0 then
            bot.DontMove = true
            return
        end
        if bot:GetMana()/bot:GetMaxMana() < 1.0 then
            bot.DontMove = true
            return
        end
    elseif not modifiers.IsRuptured(bot) then
        bot.DontMove = false
    end
    
    -- do out Thinking and set our Mode
    if GameTime() - bot.lastModeThink >= 0.1 then
        local highestDesiredMode, highestDesiredValue = think.MainThink()
        self:BeginMode(highestDesiredMode, highestDesiredValue)
        self:ExecuteMode()
        
        bot.lastModeThink = GameTime()
    end
    
    -- consider using abilities
    if not utils.IsBusy(bot) then
        local bAbilityQueued = self:getHeroVar("AbilityUsageClass"):AbilityUsageThink(bot)
        if bAbilityQueued then return end
    end
end

-------------------------------------------------------------------------------
-- BASE DO-WHILE-DEAD - DO NOT OVER-LOAD
-------------------------------------------------------------------------------

function X:DoWhileDead(bot)    
    self:ClearMode()
    bot:Action_ClearActions(true)
    self:setHeroVar("Target", nil)
    self:setHeroVar("RoamTarget", nil)

    utils.MoveItemsFromStashToInventory(bot)
    local bb = self:ConsiderBuyback(bot)
    if (bb) then
        bot:ActionImmediate_Buyback()
    end
end

function X:ConsiderBuyback(bot)
    -- FIXME: Write Buyback logic here
    -- GetBuybackCooldown(), GetBuybackCost()
    if bot:HasBuyback() then
        return false -- FIXME: for now always return false
    end
    return false
end

-------------------------------------------------------------------------------
-- BASE LANE CHANGE LOGIC - DO NOT OVER-LOAD
-------------------------------------------------------------------------------

function X:AnalyzeLanes(nLane)
    if utils.InTable(nLane, self:getHeroVar("CurLane")) then
        return
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

    self:setHeroVar("LaningState", 1) -- 1 is LaningState.Moving
    return
end

function X:DoChangeLane(bot)
    local listBuildings = buildings_status.GetStandingBuildingIDs(utils.GetOtherTeam())
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

    return
end

-------------------------------------------------------------------------------
-- VIRTUAL FUNCTIONS - OVER-LOAD THESE IN HERO-SPECIFIC FILES (IF APPROPRIATE)
-------------------------------------------------------------------------------

function X:IsReadyToGank(bot)
    return false
end

function X:DoHeroSpecificInit(bot)
    utils.myPrint("non-overloaded function 'DoHeroSpecificInit' called")
    return
end

return X
