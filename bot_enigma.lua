-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_enigma" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.enigma.SKILL_0
local SKILL_W = heroData.enigma.SKILL_1
local SKILL_E = heroData.enigma.SKILL_2
local SKILL_R = heroData.enigma.SKILL_3

local TALENT1 = heroData.enigma.TALENT_0
local TALENT2 = heroData.enigma.TALENT_1
local TALENT3 = heroData.enigma.TALENT_2
local TALENT4 = heroData.enigma.TALENT_3
local TALENT5 = heroData.enigma.TALENT_4
local TALENT6 = heroData.enigma.TALENT_5
local TALENT7 = heroData.enigma.TALENT_6
local TALENT8 = heroData.enigma.TALENT_7

local EnigmaAbilityPriority = {
    SKILL_W,    SKILL_Q,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_R,    SKILL_W,    SKILL_Q,    SKILL_E,    TALENT1,
    SKILL_Q,    SKILL_R,    SKILL_E,    SKILL_Q,    TALENT3,
    SKILL_E,    SKILL_R,    TALENT6,    TALENT7
}

local botEnigma = dt:new()

function botEnigma:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local enigmaBot = botEnigma:new{abilityPriority = EnigmaAbilityPriority}

function enigmaBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function enigmaBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function enigmaBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    enigmaBot:Think(bot)
end
