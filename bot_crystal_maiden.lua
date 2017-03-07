-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_crystal_maiden" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = "crystal_maiden_crystal_nova"
local SKILL_W = "crystal_maiden_frostbite"
local SKILL_E = "crystal_maiden_brilliance_aura"
local SKILL_R = "crystal_maiden_freezing_field"

local ABILITY1 = "special_bonus_magic_resistance_15"
local ABILITY2 = "special_bonus_attack_damage_60"
local ABILITY3 = "special_bonus_cast_range_125"
local ABILITY4 = "special_bonus_hp_250"
local ABILITY5 = "special_bonus_gold_income_20"
local ABILITY6 = "special_bonus_respawn_reduction_35"
local ABILITY7 = "special_bonus_unique_crystal_maiden_1"
local ABILITY8 = "special_bonus_unique_crystal_maiden_2"

local AbilityPriority = {
    SKILL_W,    SKILL_E,    SKILL_E,    SKILL_Q,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_Q,    SKILL_E,    ABILITY2,
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    ABILITY4,
    SKILL_W,    SKILL_R,    ABILITY6,   ABILITY7
}

local botCM = dt:new()

function botCM:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local cmBot = botCM:new{abilityPriority = AbilityPriority}

function cmBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function cmBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function cmBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function cmBot:DoHeroSpecificInit(bot)
    setHeroVar("HasStun",  {{[1]=bot:GetAbilityByName("crystal_maiden_frostbite"), [2]=0.3}})
end

function Think()
    local bot = GetBot()

    cmBot:Think(bot)
end
