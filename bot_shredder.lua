-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_shredder" )
require( GetScriptDirectory().."/ability_usage_shredder" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision_tree" )

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
};

local timberActionStack = { [1] = constants.ACTION_NONE }

TimberBot = dt:new()

function TimberBot:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

timberBot = TimberBot:new{actionStack = timberActionStack, abilityPriority = TimberAbilityPriority}

timberBot.Init = false

function timberBot:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    return ability_usage_shredder.AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
end

function Think()
    local npcBot = GetBot()

    timberBot:Think(npcBot)
end
