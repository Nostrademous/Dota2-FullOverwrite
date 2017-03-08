-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_venomancer" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = "venomancer_venomous_gale"
local SKILL_W = "venomancer_poison_sting"
local SKILL_E = "venomancer_plague_ward"
local SKILL_R = "venomancer_poison_nova"

local ABILITY1 = "special_bonus_exp_boost_20"
local ABILITY2 = "special_bonus_movement_speed_20"
local ABILITY3 = "special_bonus_hp_200"
local ABILITY4 = "special_bonus_cast_range_150"
local ABILITY5 = "special_bonus_attack_damage_75"
local ABILITY6 = "special_bonus_magic_resistance_15"
local ABILITY7 = "special_bonus_respawn_reduction_60"
local ABILITY8 = "special_bonus_unique_venomancer"

local AbilityPriority = {
    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,    SKILL_E,
    SKILL_R,    SKILL_E,    SKILL_W,    SKILL_Q,    ABILITY1,
    SKILL_W,    SKILL_R,    SKILL_Q,    SKILL_Q,    ABILITY3,
    SKILL_Q,    SKILL_R,    ABILITY5,   ABILITY8
}

local botVM = dt:new()

function botVM:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local vmBot = botVM:new{abilityPriority = AbilityPriority}

function vmBot:ConsiderAbilityUse()
    ability.AbilityUsageThink(GetBot())
end

function vmBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function vmBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    vmBot:Think(bot)
end
