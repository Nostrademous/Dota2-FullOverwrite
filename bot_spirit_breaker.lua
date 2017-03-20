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

local SKILL_Q = "spirit_breaker_charge_of_darkness"
local SKILL_W = "spirit_breaker_empowering_haste"
local SKILL_E = "spirit_breaker_greater_bash"
local SKILL_R = "spirit_breaker_nether_strike"

local ABILITY1 = "special_bonus_all_stats_5"
local ABILITY2 = "special_bonus_movement_speed_20"
local ABILITY3 = "special_bonus_attack_damage_20"
local ABILITY4 = "special_bonus_armor_5"
local ABILITY5 = "special_bonus_gold_income_20"
local ABILITY6 = "special_bonus_respawn_reduction_40"
local ABILITY7 = "special_bonus_unique_spirit_breaker_1" -- +17% greater bash chance
local ABILITY8 = "special_bonus_unique_spirit_breaker_2" -- +500 charge speed

local AbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    ABILITY1,
    SKILL_W,    SKILL_R,    SKILL_W,    SKILL_W,    ABILITY4,
    SKILL_W,    SKILL_R,    ABILITY5,   ABILITY7
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
    
    -- target TP'ed somewhere bad
    local target = getHeroVar("RoamTarget")
    if not target then target = getHeroVar("Target") end
    if not utils.ValidTarget(target) or GetUnitToLocationDistance(target, utils.Fountain(utils.GetOtherTeam())) < 1250 then
        bot:Action_ClearActions(true)
        return
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
