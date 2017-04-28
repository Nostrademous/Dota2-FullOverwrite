-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_earthshaker" )

local SKILL_Q = heroData.earthshaker.SKILL_0
local SKILL_W = heroData.earthshaker.SKILL_1
local SKILL_E = heroData.earthshaker.SKILL_2
local SKILL_R = heroData.earthshaker.SKILL_3

local TALENT1 = heroData.earthshaker.TALENT_0
local TALENT2 = heroData.earthshaker.TALENT_1
local TALENT3 = heroData.earthshaker.TALENT_2
local TALENT4 = heroData.earthshaker.TALENT_3
local TALENT5 = heroData.earthshaker.TALENT_4
local TALENT6 = heroData.earthshaker.TALENT_5
local TALENT7 = heroData.earthshaker.TALENT_6
local TALENT8 = heroData.earthshaker.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT2,
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT3,
    SKILL_W,    SKILL_R,    TALENT5,    TALENT8
}

local botES = dt:new()

function botES:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local earthshakerBot = botES:new{abilityPriority = AbilityPriority}

function earthshakerBot:DoHeroSpecificInit(bot)
end

function earthshakerBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function earthshakerBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function earthshakerBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    earthshakerBot:Think(bot)
end
