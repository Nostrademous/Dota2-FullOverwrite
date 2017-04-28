-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_sniper" )

local SKILL_Q = heroData.sniper.SKILL_0
local SKILL_W = heroData.sniper.SKILL_1
local SKILL_E = heroData.sniper.SKILL_2
local SKILL_R = heroData.sniper.SKILL_3

local TALENT1 = heroData.sniper.TALENT_0
local TALENT2 = heroData.sniper.TALENT_1
local TALENT3 = heroData.sniper.TALENT_2
local TALENT4 = heroData.sniper.TALENT_3
local TALENT5 = heroData.sniper.TALENT_4
local TALENT6 = heroData.sniper.TALENT_5
local TALENT7 = heroData.sniper.TALENT_6
local TALENT8 = heroData.sniper.TALENT_7

local AbilityPriority = {
    SKILL_W,    SKILL_E,    SKILL_Q,    SKILL_Q,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT2,
    SKILL_E,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT3,
    SKILL_W,    SKILL_R,    TALENT6,    TALENT8
}

local botSniper = dt:new()

function botSniper:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local sniperBot = botSniper:new{abilityPriority = AbilityPriority}

function sniperBot:DoHeroSpecificInit(bot)
end

function sniperBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function sniperBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function sniperBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    sniperBot:Think(bot)
end
