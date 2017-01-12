-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- Some Functions have been copy/pasted from bot-scripting community members 
--- Including: 
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision_tree" )

local SKILL_Q = "antimage_mana_break";
local SKILL_W = "antimage_blink";
local SKILL_E = "antimage_spell_shield";
local SKILL_R = "antimage_mana_void"; 

local ABILITY1 = "special_bonus_strength_6"
local ABILITY2 = "special_bonus_attack_damage_20"
local ABILITY3 = "special_bonus_attack_speed_20"
local ABILITY4 = "special_bonus_hp_250"
local ABILITY5 = "special_bonus_evasion_15"
local ABILITY6 = "special_bonus_all_stats_10"
local ABILITY7 = "special_bonus_agility_25"
local ABILITY8 = "special_bonus_unique_antimage"

local AntimageAbilityPriority = {
	SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    ABILITY2,
    SKILL_W,    SKILL_R,    SKILL_E,    SKILL_E,    ABILITY4,
    SKILL_E,    SKILL_R,    ABILITY6, 	ABILITY8
};

ACTION_NONE			= "ACTION_NONE";
local antimageActionQueue = { [1] = ACTION_NONE }

AMBot = dt:new()

function AMBot:new(o)
	o = o or dt:new(o)
	setmetatable(o, self)
	self.__index = self
	return o
end

AMBot = AMBot:new{prevTime = -997.0, actionQueue = antimageActionQueue, abilityPriority = AntimageAbilityPriority}
--AMBot:printInfo();

AMBot.Init = false;

function AMBot:RetreatAbility()
	local npcBot = GetBot()
	
	local blink = npcBot:GetAbilityByName("antimage_blink")
	if blink:IsFullyCastable() then
		return blink
	end
	return nil
end

function Think()
    local npcBot = GetBot();
	
	AMBot:Think(npcBot);
end
