-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_shredder" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q   = "shredder_whirling_death"
local SKILL_W   = "shredder_timber_chain"
local SKILL_E   = "shredder_reactive_armor"
local SKILL_R   = "shredder_chakram"

local ABILITY1 = "special_bonus_hp_150"
local ABILITY2 = "special_bonus_exp_boost_20"
local ABILITY3 = "special_bonus_hp_regen_14"
local ABILITY4 = "special_bonus_intelligence_20"
local ABILITY5 = "special_bonus_spell_amplify_5"
local ABILITY6 = "special_bonus_cast_range_150"
local ABILITY7 = "special_bonus_unique_timbersaw"
local ABILITY8 = "special_bonus_strength_20"

local TimberAbilityPriority = {
    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_W,
    SKILL_R,    SKILL_E,    SKILL_E,    SKILL_W,    ABILITY2,
    SKILL_W,    SKILL_R,    SKILL_Q,    SKILL_Q,    ABILITY3,
    SKILL_Q,    SKILL_R,    ABILITY5,   ABIILTY8
}

local botTimber = dt:new()

function botTimber:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local timberBot = botTimber:new{abilityPriority = TimberAbilityPriority}

function timberBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function timberBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function timberBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    timberBot:Think(bot)
end
