-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_venomancer" )
require( GetScriptDirectory().."/ability_usage_venomancer" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision_tree" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

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

local vmModeStack = { [1] = constants.MODE_NONE }

botVM = dt:new()

function botVM:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

vmBot = botVM:new{modeStack = vmModeStack, abilityPriority = AbilityPriority}

vmBot.Init = false

function vmBot:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    ability_usage_venomancer.AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
end

function Think()
    local bot = GetBot()

    vmBot:Think(bot)
    
    -- if we are initialized, do the rest
    if vmBot.Init then
        gHeroVar.ExecuteHeroActionQueue(bot)
    end
end
