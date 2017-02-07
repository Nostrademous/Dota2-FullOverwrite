-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_lina" )
require ( GetScriptDirectory().."/ability_usage_lina" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision_tree" )

local LINA_SKILL_Q = "lina_dragon_slave";
local LINA_SKILL_W = "lina_light_strike_array";
local LINA_SKILL_E = "lina_fiery_soul";
local LINA_SKILL_R = "lina_laguna_blade";

local LINA_ABILITY1 = "special_bonus_mp_250"
local LINA_ABILITY2 = "special_bonus_attack_damage_20"
local LINA_ABILITY3 = "special_bonus_respawn_reduction_30"
local LINA_ABILITY4 = "special_bonus_cast_range_125"
local LINA_ABILITY5 = "special_bonus_spell_amplify_6"
local LINA_ABILITY6 = "special_bonus_attack_range_150"
local LINA_ABILITY7 = "special_bonus_unique_lina_1"
local LINA_ABILITY8 = "special_bonus_unique_lina_2"

local LinaAbilityPriority = {
    LINA_SKILL_Q,    LINA_SKILL_E,    LINA_SKILL_Q,    LINA_SKILL_W,    LINA_SKILL_Q,
    LINA_SKILL_R,    LINA_SKILL_Q,    LINA_SKILL_E,    LINA_SKILL_E,    LINA_ABILITY1,
    LINA_SKILL_E,    LINA_SKILL_R,    LINA_SKILL_W,    LINA_SKILL_W,    LINA_ABILITY3,
    LINA_SKILL_W,    LINA_SKILL_R,    LINA_ABILITY5,   LINA_ABILITY7
};

local linaActionStack = { [1] = constants.ACTION_NONE }

LinaBot = dt:new()

function LinaBot:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

linaBot = LinaBot:new{actionStack = linaActionStack, abilityPriority = LinaAbilityPriority}
--linaBot:printInfo();

linaBot.Init = false

function linaBot:DoHeroSpecificInit(bot)
end

function linaBot:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    return ability_usage_lina.AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
end

function Think()
    local npcBot = GetBot()

    linaBot:Think(npcBot)
end
