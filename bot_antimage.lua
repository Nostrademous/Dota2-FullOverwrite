-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require ( GetScriptDirectory().."/ability_usage_antimage" )
local dt = require( GetScriptDirectory().."/decision_tree" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

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
};

local antimageModeStack = { [1] = constants.MODE_NONE }

AMBot = dt:new()

function AMBot:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

amBot = AMBot:new{modeStack = antimageModeStack, abilityPriority = AntimageAbilityPriority}
--AMBot:printInfo();

amBot.Init = false

function amBot:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    ability_usage_antimage.AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
end

function amBot:DoHeroSpecificInit(bot)
    self:setHeroVar("HasMovementAbility", bot:GetAbilityByName(SKILL_W))
    self:setHeroVar("HasEscape", bot:GetAbilityByName(SKILL_W))
end

function Think()
    local bot = GetBot()

    amBot:Think(bot)
    
    -- if we are initialized, do the rest
    if amBot.Init then
        gHeroVar.ExecuteHeroActionQueue(bot)
    end
end
