-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_antimage" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = "antimage_mana_break";
local SKILL_W = "antimage_blink";
local SKILL_E = "antimage_spell_shield";
local SKILL_R = "antimage_mana_void";

local ABILITY1 = "special_bonus_hp_150"
local ABILITY2 = "special_bonus_attack_damage_20"
local ABILITY3 = "special_bonus_attack_speed_20"
local ABILITY4 = "special_bonus_unique_antimage"
local ABILITY5 = "special_bonus_evasion_15"
local ABILITY6 = "special_bonus_all_stats_10"
local ABILITY7 = "special_bonus_agility_25"
local ABILITY8 = "special_bonus_unique_antimage_2"

local AntimageAbilityPriority = {
    SKILL_W,    SKILL_Q,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    ABILITY1,
    SKILL_W,    SKILL_R,    SKILL_E,    SKILL_E,    ABILITY4,
    SKILL_E,    SKILL_R,    ABILITY6,   ABILITY8
}

local botAM = dt:new()

function botAM:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local amBot = botAM:new{abilityPriority = AntimageAbilityPriority}

function amBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function amBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function amBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function amBot:DoHeroSpecificInit(bot)
    local mvAbility = bot:GetAbilityByName(SKILL_W)
    self:setHeroVar("HasMovementAbility", {mvAbility, mvAbility:GetSpecialValueInt("blink_range")})
    self:setHeroVar("HasEscape", {mvAbility, mvAbility:GetSpecialValueInt("blink_range")})
end

function Think()
    local bot = GetBot()

    amBot:Think(bot)
end
