-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_phantom_assassin" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = "phantom_assassin_stifling_dagger"
local SKILL_W = "phantom_assassin_phantom_strike"
local SKILL_E = "phantom_assassin_blur"
local SKILL_R = "phantom_assassin_coup_de_grace"

local ABILITY1 = "special_bonus_hp_150"
local ABILITY2 = "special_bonus_attack_damage_15"
local ABILITY3 = "special_bonus_lifesteal_10"
local ABILITY4 = "special_bonus_movement_speed_20"
local ABILITY5 = "special_bonus_attack_speed_35"
local ABILITY6 = "special_bonus_all_stats_10"
local ABILITY7 = "special_bonus_agility_25"
local ABILITY8 = "special_bonus_unique_phantom_assassin"

local AbilityPriority = {
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    ABILITY2,
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    ABILITY3,
    SKILL_W,    SKILL_R,    ABILITY6,   ABILITY7
}

local botPA = dt:new()

function botPA:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local paBot = botPA:new{abilityPriority = AbilityPriority}

function paBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function paBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function paBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function paBot:DoHeroSpecificInit(bot)
    local mvAbility = bot:GetAbilityByName(SKILL_W)
    self:setHeroVar("HasMovementAbility", {mvAbility, mvAbility:GetCastRange()})
    self:setHeroVar("HasEscape", {mvAbility, mvAbility:GetCastRange()})
end

function Think()
    local bot = GetBot()

    paBot:Think(bot)
end
