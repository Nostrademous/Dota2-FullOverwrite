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

local linaActionQueue = { [1] = constants.ACTION_NONE }

LinaBot = dt:new()

function LinaBot:new(o)
	o = o or dt:new(o)
	setmetatable(o, self)
	self.__index = self
	return o
end

linaBot = LinaBot:new{prevTime = -999.0, actionQueue = linaActionQueue, abilityPriority = LinaAbilityPriority}
--linaBot:printInfo();

linaBot.Init = false;

function linaBot:ConsiderAbilityUse()
	ability_usage_lina.AbilityUsageThink()
end

local LaningState = 0
local CurLane = nil
local MoveThreshold = 1.0
local DamageThreshold = 1.0
local ShouldPush = false
local IsCore = nil
local Role = nil
local IsRetreating = false
local IsInLane = false
local BackTimerGen = -1000
local LastCourierThink = -1000.0

function LoadUpdates(npcBot)
	npcBot.LaningState = LaningState
	npcBot.CurLane = CurLane
	npcBot.MoveThreshold = MoveThreshold
	npcBot.DamageThreshold = DamageThreshold
	npcBot.ShouldPush = ShouldPush
	npcBot.IsCore = IsCore
	npcBot.Role = Role
	npcBot.IsRetreating = IsRetreating
	npcBot.IsInLane = IsInLane
	npcBot.BackTimerGen = BackTimerGen
	npcBot.LastCourierThink = LastCourierThink
end

function SaveUpdates(npcBot)
	LaningState = npcBot.LaningState
	CurLane = npcBot.CurLane
	MoveThreshold = npcBot.MoveThreshold
	DamageThreshold = npcBot.DamageThreshold
	ShouldPush = npcBot.ShouldPush
	IsCore = npcBot.IsCore
	Role = npcBot.Role
	IsRetreating = npcBot.IsRetreating
	IsInLane = npcBot.IsInLane
	BackTimerGen = npcBot.BackTimerGen
	LastCourierThink = npcBot.LastCourierThink
end

function PrintUpdate()
	print(LaningState)
	print(CurLane)
	print(Role)
	print(IsRetreating)
	print(BackTimerGen)
end

function Think()
    local npcBot = GetBot()
	LoadUpdates(npcBot)
	
	linaBot:Think(npcBot)
	
	SaveUpdates(npcBot)
	--PrintUpdate()
end
