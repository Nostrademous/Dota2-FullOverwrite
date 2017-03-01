-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/role" )
require( GetScriptDirectory().."/buildings_status" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local think = require( GetScriptDirectory().."/think" )

-------------------------------------------------------------------------------
-- BASE CLASS - DO NOT MODIFY THIS SECTION
-------------------------------------------------------------------------------

local X = { init = false, currentMode = constants.MODE_NONE, currentModeValue = BOT_MODE_DESIRE_NONE, prevMode = constants.MODE_NONE, abilityPriority = {} }

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
        utils.myPrint("Mode Transition: "..self.prevMode.." --> "..self.currentMode)
        if self.prevMode ~= constants.MODE_NONE then
            self.prevMode:OnEnd()
        end
        if self.currentMode ~= constants.MODE_NONE then
            self.currentMode:OnStart(self)
        end
        self.prevMode = self.currentMode
    end

    if self.currentMode ~= constants.MODE_NONE then
        self.currentMode:Think()
    end
end

function X:BeginMode(mode, value)
    if mode == self.currentMode then return end
    self.currentMode = mode
    self.currentModeValue = value
end

function X:ClearMode()
    self.currentMode = constants.MODE_NONE
    self.currentModeValue = BOT_MODE_DESIRE_NONE
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

    self.Name = utils.GetHeroName(bot)
    self.pID = bot:GetPlayerID() -- do this to reduce calls to bot:GetPlayerID() in the future
    gHeroVar.InitHeroVar(self.pID)

    self:setHeroVar("Self", self)
    self:setHeroVar("LastCourierThink", -1000.0)
    self:setHeroVar("LastLevelUpThink", -1000.0)
    self:setHeroVar("TeamBuy", {})
    self:setHeroVar("DoDefendLane", {})
    self:setHeroVar("IsRetreating", false)
    self:setHeroVar("ShouldPush", false)
    
    local botDifficulty = bot:GetDifficulty()
    if botDifficulty == DIFFICULTY_EASY then
        self:setHeroVar("AbilityDelay", 0.75)
    elseif botDifficulty == DIFFICULTY_MEDIUM then
        self:setHeroVar("AbilityDelay", 0.45)
    elseif botDifficulty == DIFFICULTY_HARD then
        self:setHeroVar("AbilityDelay", 0.15)
    elseif botDifficulty == DIFFICULTY_UNFAIR then
        self:setHeroVar("AbilityDelay", 0.1)
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

    local itemPurchase = require( GetScriptDirectory().."/itemPurchase/"..self.Name )
    setHeroVar("ItemPurchaseClass", itemPurchase)
    itemPurchase:Init()
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

    -- level up abilities if time
    local checkLevel, newTime = utils.TimePassed(self:getHeroVar("LastLevelUpThink"), 2.0)
    if checkLevel then
        self:setHeroVar("LastLevelUpThink", newTime)
        while bot:GetAbilityPoints() > 0 do
            utils.LevelUp(bot, self.abilityPriority)
        end
    end

    -- use courier if needed (TO BE REPLACED BY TEAM LEVEL COURIER CONTROLS)
    utils.CourierThink(bot)
    
    -- check if I am alive, if not, short-circuit most stuff
    if not bot:IsAlive() then
        self:DoWhileDead(bot)
        return
    end

    -- consider purchasing items
    self:getHeroVar("ItemPurchaseClass"):ItemPurchaseThink(bot)
    
    -- update our building information
    buildings_status.Update()

    -- do out Thinking and set our Mode
    local highestDesiredMode, highestDesiredValue = think.MainThink()
    if highestDesiredValue >= self:getCurrentModeValue() then
        self:BeginMode(highestDesiredMode, highestDesiredValue)
    end
    self:ExecuteMode()
end

-------------------------------------------------------------------------------
-- BASE DO-WHILE-DEAD - DO NOT OVER-LOAD
-------------------------------------------------------------------------------

function X:DoWhileDead(bot)
    self:ClearMode()

    self:MoveItemsFromStashToInventory(bot)
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
-- VIRTUAL FUNCTIONS - OVER-LOAD THESE IN HERO-SPECIFIC FILES (IF APPROPRIATE)
-------------------------------------------------------------------------------
function X:DoHeroSpecificInit(bot)
    return
end

return X
