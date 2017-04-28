-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_bane" )

local SKILL_Q = heroData.bane.SKILL_0
local SKILL_W = heroData.bane.SKILL_1
local SKILL_E = heroData.bane.SKILL_2
local SKILL_R = heroData.bane.SKILL_3

local TALENT1 = heroData.bane.TALENT_0
local TALENT2 = heroData.bane.TALENT_1
local TALENT3 = heroData.bane.TALENT_2
local TALENT4 = heroData.bane.TALENT_3
local TALENT5 = heroData.bane.TALENT_4
local TALENT6 = heroData.bane.TALENT_5
local TALENT7 = heroData.bane.TALENT_6
local TALENT8 = heroData.bane.TALENT_7

local AbilityPriority = {
    SKILL_E,    SKILL_W,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_R,    SKILL_W,    SKILL_E,    SKILL_E,    TALENT2,
    SKILL_Q,    SKILL_R,    SKILL_Q,    SKILL_Q,    TALENT4,
    SKILL_Q,    SKILL_R,    TALENT6,    TALENT8
}

local botBane = dt:new()

function botBane:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local baneBot = botBane:new{abilityPriority = AbilityPriority}

function baneBot:DoHeroSpecificInit(bot)
end

function baneBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function baneBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function baneBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    baneBot:Think(bot)
end
