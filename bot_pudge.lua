-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_pudge" )

local SKILL_Q = heroData.pudge.SKILL_0
local SKILL_W = heroData.pudge.SKILL_1
local SKILL_E = heroData.pudge.SKILL_2
local SKILL_R = heroData.pudge.SKILL_3

local TALENT1 = heroData.pudge.TALENT_0
local TALENT2 = heroData.pudge.TALENT_1
local TALENT3 = heroData.pudge.TALENT_2
local TALENT4 = heroData.pudge.TALENT_3
local TALENT5 = heroData.pudge.TALENT_4
local TALENT6 = heroData.pudge.TALENT_5
local TALENT7 = heroData.pudge.TALENT_6
local TALENT8 = heroData.pudge.TALENT_7

local AbilityPriority = {
    SKILL_W,    SKILL_Q,    SKILL_Q,    SKILL_W,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    TALENT1,
    SKILL_E,    SKILL_R,    SKILL_E,    SKILL_E,    TALENT3,
    SKILL_E,    SKILL_R,    TALENT5,    TALENT7
}

local botPudge = dt:new()

function botPudge:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local pudgeBot = botPudge:new{abilityPriority = AbilityPriority}

function pudgeBot:DoHeroSpecificInit(bot)
end

function pudgeBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function pudgeBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function pudgeBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    pudgeBot:Think(bot)
end
