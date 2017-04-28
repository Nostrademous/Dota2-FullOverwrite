-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_nevermore" )

local SKILL_Q = heroData.nevermore.SKILL_0 -- 1 & 2 are the other razes
local SKILL_W = heroData.nevermore.SKILL_3
local SKILL_E = heroData.nevermore.SKILL_4
local SKILL_R = heroData.nevermore.SKILL_5

local TALENT1 = heroData.nevermore.TALENT_0
local TALENT2 = heroData.nevermore.TALENT_1
local TALENT3 = heroData.nevermore.TALENT_2
local TALENT4 = heroData.nevermore.TALENT_3
local TALENT5 = heroData.nevermore.TALENT_4
local TALENT6 = heroData.nevermore.TALENT_5
local TALENT7 = heroData.nevermore.TALENT_6
local TALENT8 = heroData.nevermore.TALENT_7

local AbilityPriority = {
    SKILL_W,    SKILL_Q,    SKILL_Q,    SKILL_W,    SKILL_Q,
    SKILL_W,    SKILL_Q,    SKILL_W,    SKILL_R,    TALENT2,
    SKILL_E,    SKILL_R,    SKILL_E,    SKILL_E,    TALENT4,
    SKILL_E,    SKILL_R,    TALENT6,    TALENT7
}

local botSF = dt:new()

function botSF:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local nevermoreBot = botSF:new{abilityPriority = AbilityPriority}

function nevermoreBot:DoHeroSpecificInit(bot)
end

function nevermoreBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function nevermoreBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function nevermoreBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    nevermoreBot:Think(bot)
end
