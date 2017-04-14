-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_viper" )

local SKILL_Q = heroData.viper.SKILL_0
local SKILL_W = heroData.viper.SKILL_1
local SKILL_E = heroData.viper.SKILL_2
local SKILL_R = heroData.viper.SKILL_3

local TALENT1 = heroData.viper.TALENT_0
local TALENT2 = heroData.viper.TALENT_1
local TALENT3 = heroData.viper.TALENT_2
local TALENT4 = heroData.viper.TALENT_3
local TALENT5 = heroData.viper.TALENT_4
local TALENT6 = heroData.viper.TALENT_5
local TALENT7 = heroData.viper.TALENT_6
local TALENT8 = heroData.viper.TALENT_7

local ViperAbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_R,    SKILL_W,    SKILL_W,    SKILL_Q,    TALENT1,
    SKILL_Q,    SKILL_R,    SKILL_Q,    SKILL_E,    TALENT4,
    SKILL_E,    SKILL_R,    TALENT6,    TALENT7
}

local botViper = dt:new()

function botViper:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local viperBot = botViper:new{abilityPriority = ViperAbilityPriority}

function viperBot:DoHeroSpecificInit(bot)
    self:setHeroVar("HasOrbAbility", SKILL_Q)
end

function viperBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function viperBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function viperBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    viperBot:Think(bot)
end
