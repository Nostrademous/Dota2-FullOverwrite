-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_phantom_lancer" )

local SKILL_Q = heroData.phantom_lancer.SKILL_0
local SKILL_W = heroData.phantom_lancer.SKILL_1
local SKILL_E = heroData.phantom_lancer.SKILL_2
local SKILL_R = heroData.phantom_lancer.SKILL_3

local TALENT1 = heroData.phantom_lancer.TALENT_0
local TALENT2 = heroData.phantom_lancer.TALENT_1
local TALENT3 = heroData.phantom_lancer.TALENT_2
local TALENT4 = heroData.phantom_lancer.TALENT_3
local TALENT5 = heroData.phantom_lancer.TALENT_4
local TALENT6 = heroData.phantom_lancer.TALENT_5
local TALENT7 = heroData.phantom_lancer.TALENT_6
local TALENT8 = heroData.phantom_lancer.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    TALENT1,
    SKILL_W,    SKILL_R,    SKILL_E,    SKILL_E,    TALENT4,
    SKILL_E,    SKILL_R,    TALENT5,    TALENT7
}

local botPL = dt:new()

function botPL:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local phantom_lancerBot = botPL:new{abilityPriority = AbilityPriority}

function phantom_lancerBot:DoHeroSpecificInit(bot)
end

function phantom_lancerBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function phantom_lancerBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function phantom_lancerBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    phantom_lancerBot:Think(bot)
end
