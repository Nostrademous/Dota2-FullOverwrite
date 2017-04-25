-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_spirit_breaker" )

require( GetScriptDirectory().."/item_usage" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.spirit_breaker.SKILL_0
local SKILL_W = heroData.spirit_breaker.SKILL_1
local SKILL_E = heroData.spirit_breaker.SKILL_2
local SKILL_R = heroData.spirit_breaker.SKILL_3

local TALENT1 = heroData.spirit_breaker.TALENT_0
local TALENT2 = heroData.spirit_breaker.TALENT_1
local TALENT3 = heroData.spirit_breaker.TALENT_2
local TALENT4 = heroData.spirit_breaker.TALENT_3
local TALENT5 = heroData.spirit_breaker.TALENT_4
local TALENT6 = heroData.spirit_breaker.TALENT_5
local TALENT7 = heroData.spirit_breaker.TALENT_6
local TALENT8 = heroData.spirit_breaker.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT1,
    SKILL_W,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT3,
    SKILL_W,    SKILL_R,    TALENT6,    TALENT7
}

local botSB = dt:new()

function botSB:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local sbBot = botSB:new{abilityPriority = AbilityPriority}

function sbBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function sbBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function sbBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function sbBot:DoHeroSpecificInit(bot)
end

function Think()
    local bot = GetBot()

    -- We are charging
    if bot:HasModifier("modifier_spirit_breaker_charge_of_darkness") then
        ConsiderActionsWhileCharging(bot) 
        return
    end
    
    sbBot:Think(bot)
end

function sbBot:IsReadyToGank(bot)
    local charge = bot:GetAbilityByName(SKILL_Q)
    return charge:GetLevel() >= 2 and charge:IsFullyCastable()
end

function ConsiderActionsWhileCharging(bot) 
    -- we are retreating
    if bot.SelfRef:getCurrentMode():GetName() == "retreat" then
        local enemies = gHeroVar.GetNearbyEnemies(bot, 1600)
        if #enemies == 0 then
            bot:Action_ClearActions(true)
            return
        end
    end
    
    local target = getHeroVar("RoamTarget")
    if not target then target = getHeroVar("Target") end
    
    -- target TP'ed somewhere bad
    if not utils.ValidTarget(target) then
        bot:Action_ClearActions(true)
        return
    else
        if GetUnitToLocationDistance(target, utils.Fountain(utils.GetOtherTeam())) < 1250 then
            bot:Action_ClearActions(true)
            return
        end
    end
    
    local sb = utils.IsItemAvailable("item_invis_sword")
    if sb then
        local chargeSpeed = bot:GetAbilityByName(SKILL_Q):GetSpecialValueInt("movement_speed")
        if not utils.ValidTarget(target) then target = getHeroVar("Target") end
        if utils.ValidTarget(target) then
            local timeToArrival = GetUnitToUnitDistance(bot, target)/chargeSpeed
            if timeToArrival < 10.0 and timeToArrival > 2.0 then
                item_usage.UseShadowBlade()
                return
            end
        end
    end
    
    local se = utils.IsItemAvailable("item_silver_edge")
    if se then
        local chargeSpeed = bot:GetAbilityByName(SKILL_Q):GetSpecialValueInt("movement_speed")
        if not utils.ValidTarget(target) then target = getHeroVar("Target") end
        if utils.ValidTarget(target) then
            if GetUnitToUnitDistance(bot, target)/chargeSpeed < 10.0 then
                item_usage.UseSilverEdge()
                return
            end
        end
    end
end
