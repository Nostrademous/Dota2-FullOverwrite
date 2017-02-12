-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_enigma" )
require ( GetScriptDirectory().."/ability_usage_enigma" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision_tree" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local ENIGMA_SKILL_Q = "enigma_malefice";
local ENIGMA_SKILL_W = "enigma_demonic_conversion";
local ENIGMA_SKILL_E = "enigma_midnight_pulse";
local ENIGMA_SKILL_R = "enigma_black_hole";

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
};

local enigmaActionQueue = { [1] = constants.MODE_NONE }

enigmaBot = dt:new()

function enigmaBot:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

enigmaBot = enigmaBot:new{actionQueue = enigmaActionQueue, abilityPriority = EnigmaAbilityPriority}
--enigmaBot:printInfo();

enigmaBot.Init = false;

function enigmaBot:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    ability_usage_enigma.AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
end

function Think()
    local bot = GetBot()

    enigmaBot:Think(bot)
    
    -- if we are initialized, do the rest
    if enigmaBot.Init then
        gHeroVar.ExecuteHeroActionQueue(bot)
    end
end
