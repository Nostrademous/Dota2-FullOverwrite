-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_mirana" )

local SKILL_Q = heroData.mirana.SKILL_0
local SKILL_W = heroData.mirana.SKILL_1
local SKILL_E = heroData.mirana.SKILL_2
local SKILL_R = heroData.mirana.SKILL_3

local TALENT1 = heroData.mirana.TALENT_0
local TALENT2 = heroData.mirana.TALENT_1
local TALENT3 = heroData.mirana.TALENT_2
local TALENT4 = heroData.mirana.TALENT_3
local TALENT5 = heroData.mirana.TALENT_4
local TALENT6 = heroData.mirana.TALENT_5
local TALENT7 = heroData.mirana.TALENT_6
local TALENT8 = heroData.mirana.TALENT_7

local AbilityPriority = {
    SKILL_W,    SKILL_E,    SKILL_Q,    SKILL_Q,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT1,
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT4,
    SKILL_W,    SKILL_R,    TALENT5,    TALENT8
}

local botMirana = dt:new()

function botMirana:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local miranaBot = botMirana:new{abilityPriority = AbilityPriority}

function miranaBot:DoHeroSpecificInit(bot)
end

function miranaBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function miranaBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function miranaBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    miranaBot:Think(bot)
end
