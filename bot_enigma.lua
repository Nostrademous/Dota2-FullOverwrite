-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_enigma" )
require ( GetScriptDirectory().."/ability_usage_enigma" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision_tree" )

local ENIGMA_SKILL_Q = "enigma_malefice";
local ENIGMA_SKILL_W = "enigma_demonic_conversion";
local ENIGMA_SKILL_E = "enigma_midnight_pulse";
local ENIGMA_SKILL_R = "enigma_black_hole";

local ENIGMA_ABILITY1 = "special_bonus_movement_speed_20"
local ENIGMA_ABILITY2 = "special_bonus_magic_resistance_12"
local ENIGMA_ABILITY3 = "special_bonus_cooldown_reduction_15"
local ENIGMA_ABILITY4 = "special_bonus_gold_income_20"
local ENIGMA_ABILITY5 = "special_bonus_hp_300"
local ENIGMA_ABILITY6 = "special_bonus_respawn_reduction_30"
local ENIGMA_ABILITY7 = "special_bonus_armor_12"
local ENIGMA_ABILITY8 = "special_bonus_unique_enigma"

local EnigmaAbilityPriority = {
	ENIGMA_SKILL_W,    ENIGMA_SKILL_Q,    ENIGMA_SKILL_W,    ENIGMA_SKILL_E,    ENIGMA_SKILL_W,
    ENIGMA_SKILL_R,    ENIGMA_SKILL_W,    ENIGMA_SKILL_Q,    ENIGMA_SKILL_E,    ENIGMA_ABILITY1,
    ENIGMA_SKILL_Q,    ENIGMA_SKILL_R,    ENIGMA_SKILL_E,    ENIGMA_SKILL_Q,    ENIGMA_ABILITY3,
    ENIGMA_SKILL_E,    ENIGMA_SKILL_R,    ENIGMA_ABILITY6,   ENIGMA_ABILITY7
};

local enigmaActionQueue = { [1] = constants.ACTION_NONE }

enigmaBot = dt:new()

function enigmaBot:new(o)
	o = o or dt:new(o)
	setmetatable(o, self)
	self.__index = self
	return o
end

enigmaBot = enigmaBot:new{prevTime = -999.0, actionQueue = enigmaActionQueue, abilityPriority = EnigmaAbilityPriority}
--enigmaBot:printInfo();

enigmaBot.Init = false;

function enigmaBot:ConsiderAbilityUse()
	ability_usage_enigma.AbilityUsageThink()
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
local TargetOfRunAwayFromCreepOrTower = nil

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
	npcBot.TargetOfRunAwayFromCreepOrTower = TargetOfRunAwayFromCreepOrTower
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
	TargetOfRunAwayFromCreepOrTower = npcBot.TargetOfRunAwayFromCreepOrTower
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

	enigmaBot:Think(npcBot)

	SaveUpdates(npcBot)
	--PrintUpdate()
end
