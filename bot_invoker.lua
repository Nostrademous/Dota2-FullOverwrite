-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------
---[[

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_invoker" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = "invoker_quas"
local SKILL_W = "invoker_wex"
local SKILL_E = "invoker_exort"
--local SKILL_R = "invoker_invoke"

local ABILITY1 = "special_bonus_attack_damage_15"
local ABILITY2 = "special_bonus_hp_125"
local ABILITY3 = "special_bonus_unique_invoker_1" -- +1 Forged Spirit Summoned
local ABILITY4 = "special_bonus_exp_boost_30"
local ABILITY5 = "special_bonus_all_stats_7"
local ABILITY6 = "special_bonus_attack_speed_35"
local ABILITY7 = "special_bonus_unique_invoker_2" -- AOE Deafening Blast
local ABILITY8 = "special_bonus_unique_invoker_3" -- -18s Tornado Cooldown

local AbilityPriority = {
    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_Q,    SKILL_E,
    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_E,    SKILL_Q,    SKILL_E,    ABILITY1,   ABILITY4,
    SKILL_W,    SKILL_W,    SKILL_Q,    SKILL_W,    ABILITY5,
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_Q,    ABILITY7
}

local botInv = dt:new()

function botInv:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local invBot = botInv:new{abilityPriority = AbilityPriority}

function invBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function invBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function invBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function invBot:DoHeroSpecificInit(bot)
    setHeroVar("HasGlobal", {[1]=bot:GetAbilityByName("invoker_sun_strike"), [2]=1.75+getHeroVar("AbilityDelay")})
    setHeroVar("HasStun",  {{[1]=bot:GetAbilityByName("invoker_cold_snap"), [2]=0.05+getHeroVar("AbilityDelay")}})
end

function Think()
    local bot = GetBot()

    invBot:Think(bot)
end

---]]

--[[

function PredictPosition(hHero, fTime)
    local loc = hHero:GetLocation()
	local v = hHero:GetVelocity()
	return Vector( loc.x + fTime * v.x, loc.y + fTime * v.y, loc.z )
end

local abilitySS = nil

function UseSS()
    -- Get some of its values
    local nRadius = 175
    local nDelay = 1.75 -- 0.05 cast point, 1.7 delay
    local nDamage = abilitySS:GetSpecialValueFloat("damage")

    --------------------------------------
    -- Global Usage
    --------------------------------------
    local globalEnemies = GetUnitList(UNIT_LIST_ENEMY_HEROES)
    for _, enemy in pairs(globalEnemies) do
        if enemy ~= nil and not enemy:IsNull() then
            if enemy:GetHealth() < nDamage and enemy:GetMovementDirectionStability() > 0.9 then
                --return BOT_ACTION_DESIRE_MODERATE, enemy:GetExtrapolatedLocation( nDelay )
                return BOT_ACTION_DESIRE_MODERATE, PredictPosition( enemy, nDelay )
            end
        end
    end
    
    return BOT_ACTION_DESIRE_NONE, nil
end

function Think()
    local bot = GetBot()

    -- Check if we're already using an ability
    if bot:NumQueuedActions() > 0 then return end

    if bot:GetAbilityPoints() > 0 then
        bot:ActionImmediate_LevelAbility("invoker_exort")
        return
    end

    local abilityE  = bot:GetAbilityByName( "invoker_exort" )
    local abilityR  = bot:GetAbilityByName( "invoker_invoke" )
    abilitySS = bot:GetAbilityByName( "invoker_sun_strike" )

    local ssDes, ssLoc = UseSS()
    
    if ssDes > 0 then
        bot:ActionPush_Delay(0.01)
        bot:ActionPush_UseAbilityOnLocation(abilitySS, ssLoc)
        bot:ActionPush_UseAbility(abilityR)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_Delay(0.01)
        bot:ActionPush_UseAbilityOnLocation(abilitySS, ssLoc)
        bot:ActionPush_UseAbility(abilityR)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_Delay(0.01)
        bot:ActionPush_UseAbilityOnLocation(abilitySS, ssLoc)
        bot:ActionPush_UseAbility(abilityR)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_Delay(0.01)
        bot:ActionPush_UseAbilityOnLocation(abilitySS, ssLoc)
        bot:ActionPush_UseAbility(abilityR)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_Delay(0.01)
        bot:ActionPush_UseAbilityOnLocation(abilitySS, ssLoc)
        bot:ActionPush_UseAbility(abilityR)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
        bot:ActionPush_UseAbility(abilityE)
    end
end
---]]
