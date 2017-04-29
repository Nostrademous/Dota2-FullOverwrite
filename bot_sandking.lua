-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_sandking" )

local SKILL_Q = heroData.sandking.SKILL_0
local SKILL_W = heroData.sandking.SKILL_1
local SKILL_E = heroData.sandking.SKILL_2
local SKILL_R = heroData.sandking.SKILL_3

local TALENT1 = heroData.sandking.TALENT_0
local TALENT2 = heroData.sandking.TALENT_1
local TALENT3 = heroData.sandking.TALENT_2
local TALENT4 = heroData.sandking.TALENT_3
local TALENT5 = heroData.sandking.TALENT_4
local TALENT6 = heroData.sandking.TALENT_5
local TALENT7 = heroData.sandking.TALENT_6
local TALENT8 = heroData.sandking.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT2,
    SKILL_W,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT4,
    SKILL_W,    SKILL_R,    TALENT6,    TALENT7
}

local botSK = dt:new()

function botSK:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local sandkingBot = botSK:new{abilityPriority = AbilityPriority}

function sandkingBot:DoHeroSpecificInit(bot)
end

function sandkingBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function sandkingBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function sandkingBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    sandkingBot:Think(bot)
end
