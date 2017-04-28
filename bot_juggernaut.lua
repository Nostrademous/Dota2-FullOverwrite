-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_juggernaut" )

local SKILL_Q = heroData.juggernaut.SKILL_0
local SKILL_W = heroData.juggernaut.SKILL_1
local SKILL_E = heroData.juggernaut.SKILL_2
local SKILL_R = heroData.juggernaut.SKILL_3

local TALENT1 = heroData.juggernaut.TALENT_0
local TALENT2 = heroData.juggernaut.TALENT_1
local TALENT3 = heroData.juggernaut.TALENT_2
local TALENT4 = heroData.juggernaut.TALENT_3
local TALENT5 = heroData.juggernaut.TALENT_4
local TALENT6 = heroData.juggernaut.TALENT_5
local TALENT7 = heroData.juggernaut.TALENT_6
local TALENT8 = heroData.juggernaut.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_Q,    SKILL_W,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    TALENT2,
    SKILL_W,    SKILL_R,    SKILL_E,    SKILL_E,    TALENT3,
    SKILL_E,    SKILL_R,    TALENT6,    TALENT7
}

local botJugg = dt:new()

function botJugg:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local juggernautBot = botJugg:new{abilityPriority = AbilityPriority}

function juggernautBot:DoHeroSpecificInit(bot)
end

function juggernautBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function juggernautBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function juggernautBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    juggernautBot:Think(bot)
end
