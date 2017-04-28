-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_axe" )

local SKILL_Q = heroData.axe.SKILL_0
local SKILL_W = heroData.axe.SKILL_1
local SKILL_E = heroData.axe.SKILL_2
local SKILL_R = heroData.axe.SKILL_3

local TALENT1 = heroData.axe.TALENT_0
local TALENT2 = heroData.axe.TALENT_1
local TALENT3 = heroData.axe.TALENT_2
local TALENT4 = heroData.axe.TALENT_3
local TALENT5 = heroData.axe.TALENT_4
local TALENT6 = heroData.axe.TALENT_5
local TALENT7 = heroData.axe.TALENT_6
local TALENT8 = heroData.axe.TALENT_7

local AbilityPriority = {
    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_E,
    SKILL_R,    SKILL_E,    SKILL_Q,    SKILL_Q,    TALENT2,
    SKILL_Q,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT4,
    SKILL_W,    SKILL_R,    TALENT5,    TALENT8
}

local botAxe = dt:new()

function botAxe:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local axeBot = botAxe:new{abilityPriority = AbilityPriority}

function axeBot:DoHeroSpecificInit(bot)
end

function axeBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function axeBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function axeBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    axeBot:Think(bot)
end
