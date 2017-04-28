-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_puck" )

local SKILL_Q = heroData.puck.SKILL_0
local SKILL_W = heroData.puck.SKILL_1
local SKILL_E = heroData.puck.SKILL_2 -- 3 is ethereal jaunt (aka jump into orb)
local SKILL_R = heroData.puck.SKILL_4

local TALENT1 = heroData.puck.TALENT_0
local TALENT2 = heroData.puck.TALENT_1
local TALENT3 = heroData.puck.TALENT_2
local TALENT4 = heroData.puck.TALENT_3
local TALENT5 = heroData.puck.TALENT_4
local TALENT6 = heroData.puck.TALENT_5
local TALENT7 = heroData.puck.TALENT_6
local TALENT8 = heroData.puck.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_Q,    SKILL_W,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    SKILL_W,
    SKILL_E,    SKILL_R,    SKILL_E,    SKILL_E,    TALENT1,
    TALENT3,    SKILL_R,    TALENT6,    TALENT8
}

local botPuck = dt:new()

function botPuck:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local puckBot = botPuck:new{abilityPriority = AbilityPriority}

function puckBot:DoHeroSpecificInit(bot)
end

function puckBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function puckBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function puckBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    puckBot:Think(bot)
end
