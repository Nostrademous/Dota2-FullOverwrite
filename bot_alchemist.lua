-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_alchemist" )

local SKILL_Q = heroData.alchemist.SKILL_0
local SKILL_W = heroData.alchemist.SKILL_1
local SKILL_E = heroData.alchemist.SKILL_2
local SKILL_R = heroData.alchemist.SKILL_3

local TALENT1 = heroData.alchemist.TALENT_0
local TALENT2 = heroData.alchemist.TALENT_1
local TALENT3 = heroData.alchemist.TALENT_2
local TALENT4 = heroData.alchemist.TALENT_3
local TALENT5 = heroData.alchemist.TALENT_4
local TALENT6 = heroData.alchemist.TALENT_5
local TALENT7 = heroData.alchemist.TALENT_6
local TALENT8 = heroData.alchemist.TALENT_7

local AbilityPriority = {
    SKILL_E,    SKILL_Q,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT2,
    SKILL_W,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT4,
    SKILL_W,    SKILL_R,    TALENT6,    TALENT7
}

local botAlch = dt:new()

function botAlch:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local alchBot = botAlch:new{abilityPriority = AbilityPriority}

function alchBot:DoHeroSpecificInit(bot)
end

function alchBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function alchBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function alchBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    alchBot:Think(bot)
end
