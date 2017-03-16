-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_viper" )

local SKILL_Q = "viper_poison_attack";
local SKILL_W = "viper_nethertoxin";
local SKILL_E = "viper_corrosive_skin";
local SKILL_R = "viper_viper_strike";

local ABILITY1 = "special_bonus_attack_damage_15"
local ABILITY2 = "special_bonus_hp_150"
local ABILITY3 = "special_bonus_strength_8"
local ABILITY4 = "special_bonus_agility_14"
local ABILITY5 = "special_bonus_armor_7"
local ABILITY6 = "special_bonus_attack_range_75"
local ABILITY7 = "special_bonus_unique_viper_1"
local ABILITY8 = "special_bonus_unique_viper_2"

local ViperAbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_R,    SKILL_W,    SKILL_W,    SKILL_Q,    ABILITY2,
    SKILL_Q,    SKILL_R,    SKILL_Q,    SKILL_E,    ABILITY4,
    SKILL_E,    SKILL_R,    ABILITY6,   ABILITY8
}

local botViper = dt:new()

function botViper:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local viperBot = botViper:new{abilityPriority = ViperAbilityPriority}

function viperBot:DoHeroSpecificInit(bot)
    self:setHeroVar("HasOrbAbility", SKILL_Q)
end

function viperBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function viperBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function viperBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    viperBot:Think(bot)
end
