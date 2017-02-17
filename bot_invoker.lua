-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_invoker" )
require( GetScriptDirectory().."/ability_usage_invoker" )

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

local SKILL_Q = "invoker_quas"
local SKILL_W = "invoker_wex"
local SKILL_E = "invoker_exort"
--local SKILL_R = "invoker_invoke"

local ABILITY1 = "special_bonus_attack_damage_15"
local ABILITY2 = "special_bonus_hp_125"
local ABILITY3 = "special_bonus_unique_invoker_1" -- +1 Forged Spirit Summoned
local ABILITY4 = "special_bonus_exp_boost_30"
local ABILITY5 = "special_bonus_all_stats_7"
local ABILITY6 = "special_bonus_attack_speed_35"
local ABILITY7 = "special_bonus_unique_invoker_2" -- AOE Deafening Blast
local ABILITY8 = "special_bonus_unique_invoker_3" -- -18s Tornado Cooldown

local AbilityPriority = {
    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_Q,    SKILL_E,
    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_E,    SKILL_Q,    SKILL_E,    ABILITY1,   ABILITY4,
    SKILL_W,    SKILL_W,    SKILL_Q,    SKILL_W,    ABILITY5,
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_Q,    ABILITY7
}

local inModeStack = { [1] = {constants.MODE_NONE, BOT_ACTION_DESIRE_NONE} }

botInv = dt:new()

function botInv:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

invBot = botInv:new{modeStack = inModeStack, abilityPriority = AbilityPriority}

invBot.Init = false

function invBot:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    ability_usage_invoker.AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
end

function invBot:GetNukeDamage(bot, target)
    return ability_usage_invoker.nukeDamage( bot, target )
end

function invBot:QueueNuke(bot, target, actionQueue)
    return ability_usage_invoker.queueNuke( bot, target, actionQueue )
end

function invBot:DoHeroSpecificInit(bot)
    setHeroVar("HasGlobal", {[1]=bot:GetAbilityByName("invoker_sun_strike"), [2]=1.75})
    setHeroVar("HasStun",  {{[1]=bot:GetAbilityByName("invoker_cold_snap"), [2]=0.05}})
end

function Think()
    local bot = GetBot()

    invBot:Think(bot)
    
    -- if we are initialized, do the rest
    if invBot.Init then
        gHeroVar.ExecuteHeroActionQueue(bot)
    end
end
