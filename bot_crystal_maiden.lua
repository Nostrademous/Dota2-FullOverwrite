-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_crystal_maiden" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.crystal_maiden.SKILL_0
local SKILL_W = heroData.crystal_maiden.SKILL_1
local SKILL_E = heroData.crystal_maiden.SKILL_2
local SKILL_R = heroData.crystal_maiden.SKILL_3

local TALENT1 = heroData.crystal_maiden.TALENT_0
local TALENT2 = heroData.crystal_maiden.TALENT_1
local TALENT3 = heroData.crystal_maiden.TALENT_2
local TALENT4 = heroData.crystal_maiden.TALENT_3
local TALENT5 = heroData.crystal_maiden.TALENT_4
local TALENT6 = heroData.crystal_maiden.TALENT_5
local TALENT7 = heroData.crystal_maiden.TALENT_6
local TALENT8 = heroData.crystal_maiden.TALENT_7

local AbilityPriority = {
    SKILL_W,    SKILL_E,    SKILL_E,    SKILL_Q,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_Q,    SKILL_E,    TALENT2,
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT4,
    SKILL_W,    SKILL_R,    TALENT6,    TALENT7
}

local botCM = dt:new()

function botCM:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local cmBot = botCM:new{abilityPriority = AbilityPriority}

function cmBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function cmBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function cmBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function cmBot:DoHeroSpecificInit(bot)
    setHeroVar("HasStun",  {{[1]=bot:GetAbilityByName(SKILL_W), [2]=0.3}})
end

function Think()
    local bot = GetBot()
    
    cmBot:Think(bot)
end
