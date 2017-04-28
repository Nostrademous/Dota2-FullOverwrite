-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_treant" )

local SKILL_Q = heroData.treant.SKILL_0
local SKILL_W = heroData.treant.SKILL_1
local SKILL_E = heroData.treant.SKILL_2
local SKILL_R = heroData.treant.SKILL_4 -- SKILL_3 is eyes in the forest

local TALENT1 = heroData.treant.TALENT_0
local TALENT2 = heroData.treant.TALENT_1
local TALENT3 = heroData.treant.TALENT_2
local TALENT4 = heroData.treant.TALENT_3
local TALENT5 = heroData.treant.TALENT_4
local TALENT6 = heroData.treant.TALENT_5
local TALENT7 = heroData.treant.TALENT_6
local TALENT8 = heroData.treant.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_E,    SKILL_E,
    SKILL_R,    SKILL_E,    SKILL_E,    SKILL_Q,    TALENT2,
    SKILL_Q,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT3,
    SKILL_W,    SKILL_R,    TALENT5,    TALENT8
}

local botTreant = dt:new()

function botTreant:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local treantBot = botTreant:new{abilityPriority = AbilityPriority}

function treantBot:DoHeroSpecificInit(bot)
end

function treantBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function treantBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function treantBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    treantBot:Think(bot)
end
