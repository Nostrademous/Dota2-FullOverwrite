-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_lina" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local LINA_SKILL_Q = "lina_dragon_slave"
local LINA_SKILL_W = "lina_light_strike_array"
local LINA_SKILL_E = "lina_fiery_soul"
local LINA_SKILL_R = "lina_laguna_blade"

local LINA_ABILITY1 = "special_bonus_unique_lina_3"
local LINA_ABILITY2 = "special_bonus_cast_range_125"
local LINA_ABILITY3 = "special_bonus_attack_damage_50"
local LINA_ABILITY4 = "special_bonus_respawn_reduction_30"
local LINA_ABILITY5 = "special_bonus_spell_amplify_6"
local LINA_ABILITY6 = "special_bonus_attack_range_150"
local LINA_ABILITY7 = "special_bonus_unique_lina_1"
local LINA_ABILITY8 = "special_bonus_unique_lina_2"

local LinaAbilityPriority = {
    LINA_SKILL_Q,    LINA_SKILL_E,    LINA_SKILL_Q,    LINA_SKILL_W,    LINA_SKILL_Q,
    LINA_SKILL_R,    LINA_SKILL_Q,    LINA_SKILL_E,    LINA_SKILL_E,    LINA_ABILITY1,
    LINA_SKILL_E,    LINA_SKILL_R,    LINA_SKILL_W,    LINA_SKILL_W,    LINA_ABILITY3,
    LINA_SKILL_W,    LINA_SKILL_R,    LINA_ABILITY5,   LINA_ABILITY7
}

local botLina = dt:new()

function botLina:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local linaBot = botLina:new{abilityPriority = LinaAbilityPriority}

function linaBot:DoHeroSpecificInit(bot)
    setHeroVar("HasStun",  {{[1]=bot:GetAbilityByName(LINA_SKILL_W), [2]=0.95+getHeroVar("AbilityDelay")}})
end

function linaBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function linaBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function linaBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function linaBot:IsReadyToGank(bot)
    local ult = bot:GetAbilityByName(LINA_SKILL_R)
    if ult:IsFullyCastable() and utils.HaveItem(bot, "item_blink") then
        return true
    end
    return false
end

function Think()
    local bot = GetBot()
    
    linaBot:Think(bot)
end
