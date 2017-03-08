-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_enigma" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local ENIGMA_SKILL_Q = "enigma_malefice"
local ENIGMA_SKILL_W = "enigma_demonic_conversion"
local ENIGMA_SKILL_E = "enigma_midnight_pulse"
local ENIGMA_SKILL_R = "enigma_black_hole"

local ENIGMA_ABILITY1 = "special_bonus_movement_speed_20"
local ENIGMA_ABILITY2 = "special_bonus_magic_resistance_12"
local ENIGMA_ABILITY3 = "special_bonus_cooldown_reduction_15"
local ENIGMA_ABILITY4 = "special_bonus_gold_income_20"
local ENIGMA_ABILITY5 = "special_bonus_hp_300"
local ENIGMA_ABILITY6 = "special_bonus_respawn_reduction_40"
local ENIGMA_ABILITY7 = "special_bonus_armor_12"
local ENIGMA_ABILITY8 = "special_bonus_unique_enigma"

local EnigmaAbilityPriority = {
    ENIGMA_SKILL_W,    ENIGMA_SKILL_Q,    ENIGMA_SKILL_W,    ENIGMA_SKILL_E,    ENIGMA_SKILL_W,
    ENIGMA_SKILL_R,    ENIGMA_SKILL_W,    ENIGMA_SKILL_Q,    ENIGMA_SKILL_E,    ENIGMA_ABILITY1,
    ENIGMA_SKILL_Q,    ENIGMA_SKILL_R,    ENIGMA_SKILL_E,    ENIGMA_SKILL_Q,    ENIGMA_ABILITY3,
    ENIGMA_SKILL_E,    ENIGMA_SKILL_R,    ENIGMA_ABILITY6,   ENIGMA_ABILITY7
}

local botEnigma = dt:new()

function botEnigma:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local enigmaBot = botEnigma:new{abilityPriority = EnigmaAbilityPriority}

function enigmaBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function enigmaBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function enigmaBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    enigmaBot:Think(bot)
end
