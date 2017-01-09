-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- Some Functions have been copy/pasted from bot-scripting community members 
--- Including: 
-------------------------------------------------------------------------------

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

ACTION_NONE			= "ACTION_NONE";
local linaActionQueue = { [1] = ACTION_NONE }

local linaBot = dt:new(nil, ACTION_NONE, ACTION_NONE, -998.0, linaActionQueue);
linaBot:printInfo();

local prevTime = -1000.0
local currentAction = ACTION_NONE
local prevAction = ACTION_NONE

function Think()
    local npcBot = GetBot();
	if ( not npcBot ) then return end
	
	linaBot:Think(npcBot, LinaAbilityPriority);
end
