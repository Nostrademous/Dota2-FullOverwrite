-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_phantom_assassin" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.phantom_assassin.SKILL_0
local SKILL_W = heroData.phantom_assassin.SKILL_1
local SKILL_E = heroData.phantom_assassin.SKILL_2
local SKILL_R = heroData.phantom_assassin.SKILL_3

local TALENT1 = heroData.phantom_assassin.TALENT_0
local TALENT2 = heroData.phantom_assassin.TALENT_1
local TALENT3 = heroData.phantom_assassin.TALENT_2
local TALENT4 = heroData.phantom_assassin.TALENT_3
local TALENT5 = heroData.phantom_assassin.TALENT_4
local TALENT6 = heroData.phantom_assassin.TALENT_5
local TALENT7 = heroData.phantom_assassin.TALENT_6
local TALENT8 = heroData.phantom_assassin.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT2,
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT3,
    SKILL_W,    SKILL_R,    TALENT6,    TALENT7
}

local botPA = dt:new()

function botPA:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local paBot = botPA:new{abilityPriority = AbilityPriority}

function paBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function paBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function paBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function paBot:DoHeroSpecificInit(bot)
    local mvAbility = bot:GetAbilityByName(SKILL_W)
    self:setHeroVar("HasMovementAbility", {mvAbility, mvAbility:GetCastRange()})
    self:setHeroVar("HasEscape", {mvAbility, mvAbility:GetCastRange()})
end

function Think()
    local bot = GetBot()

    paBot:Think(bot)
end
