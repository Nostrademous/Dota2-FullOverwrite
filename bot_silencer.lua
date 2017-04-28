-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_silencer" )

local SKILL_Q = heroData.silencer.SKILL_0
local SKILL_W = heroData.silencer.SKILL_1
local SKILL_E = heroData.silencer.SKILL_2
local SKILL_R = heroData.silencer.SKILL_3

local TALENT1 = heroData.silencer.TALENT_0
local TALENT2 = heroData.silencer.TALENT_1
local TALENT3 = heroData.silencer.TALENT_2
local TALENT4 = heroData.silencer.TALENT_3
local TALENT5 = heroData.silencer.TALENT_4
local TALENT6 = heroData.silencer.TALENT_5
local TALENT7 = heroData.silencer.TALENT_6
local TALENT8 = heroData.silencer.TALENT_7

local AbilityPriority = {
    SKILL_W,    SKILL_Q,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT2,
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT4,
    SKILL_W,    SKILL_R,    TALENT5,    TALENT7
}

local botSilencer = dt:new()

function botSilencer:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local silencerBot = botSilencer:new{abilityPriority = AbilityPriority}

function silencerBot:DoHeroSpecificInit(bot)
end

function silencerBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function silencerBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function silencerBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    silencerBot:Think(bot)
end
