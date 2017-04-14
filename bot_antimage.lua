-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_antimage" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.antimage.SKILL_0
local SKILL_W = heroData.antimage.SKILL_1
local SKILL_E = heroData.antimage.SKILL_2
local SKILL_R = heroData.antimage.SKILL_3

local TALENT1 = heroData.antimage.TALENT_0
local TALENT2 = heroData.antimage.TALENT_1
local TALENT3 = heroData.antimage.TALENT_2
local TALENT4 = heroData.antimage.TALENT_3
local TALENT5 = heroData.antimage.TALENT_4
local TALENT6 = heroData.antimage.TALENT_5
local TALENT7 = heroData.antimage.TALENT_6
local TALENT8 = heroData.antimage.TALENT_7

local AntimageAbilityPriority = {
    SKILL_W,    SKILL_Q,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    TALENT1,
    SKILL_W,    SKILL_R,    SKILL_E,    SKILL_E,    TALENT4,
    SKILL_E,    SKILL_R,    TALENT6,    TALENT8
}

local botAM = dt:new()

function botAM:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local amBot = botAM:new{abilityPriority = AntimageAbilityPriority}

function amBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function amBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function amBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function amBot:DoHeroSpecificInit(bot)
    local mvAbility = bot:GetAbilityByName(SKILL_W)
    self:setHeroVar("HasMovementAbility", {mvAbility, mvAbility:GetSpecialValueInt("blink_range")})
    self:setHeroVar("HasEscape", {mvAbility, mvAbility:GetSpecialValueInt("blink_range")})
end

function Think()
    local bot = GetBot()

    amBot:Think(bot)
end
