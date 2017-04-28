-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_gyrocopter" )

local SKILL_Q = heroData.gyrocopter.SKILL_0
local SKILL_W = heroData.gyrocopter.SKILL_1
local SKILL_E = heroData.gyrocopter.SKILL_2
local SKILL_R = heroData.gyrocopter.SKILL_3

local TALENT1 = heroData.gyrocopter.TALENT_0
local TALENT2 = heroData.gyrocopter.TALENT_1
local TALENT3 = heroData.gyrocopter.TALENT_2
local TALENT4 = heroData.gyrocopter.TALENT_3
local TALENT5 = heroData.gyrocopter.TALENT_4
local TALENT6 = heroData.gyrocopter.TALENT_5
local TALENT7 = heroData.gyrocopter.TALENT_6
local TALENT8 = heroData.gyrocopter.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_W,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    TALENT1,
    SKILL_E,    SKILL_R,    SKILL_E,    SKILL_E,    TALENT4,
    SKILL_E,    SKILL_R,    TALENT6,    TALENT7
}

local botGyro = dt:new()

function botGyro:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local gyroBot = botGyro:new{abilityPriority = AbilityPriority}

function gyroBot:DoHeroSpecificInit(bot)
end

function gyroBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function gyroBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function gyroBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    gyroBot:Think(bot)
end
