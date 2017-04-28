-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_morphling" )

local SKILL_Q = heroData.morphling.SKILL_0
local SKILL_W = heroData.morphling.SKILL_1
local SKILL_E = heroData.morphling.SKILL_2 -- 3 is Morph_Str, 4 is Hybrid (Aghs)
local SKILL_R = heroData.morphling.SKILL_5 -- 6 is Morph, 7 is Morph Replicate

local TALENT1 = heroData.morphling.TALENT_0
local TALENT2 = heroData.morphling.TALENT_1
local TALENT3 = heroData.morphling.TALENT_2
local TALENT4 = heroData.morphling.TALENT_3
local TALENT5 = heroData.morphling.TALENT_4
local TALENT6 = heroData.morphling.TALENT_5
local TALENT7 = heroData.morphling.TALENT_6
local TALENT8 = heroData.morphling.TALENT_7

local AbilityPriority = {
    SKILL_E,    SKILL_Q,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_R,    TALENT2,
    SKILL_W,    SKILL_R,    SKILL_W,    SKILL_W,    TALENT4,
    SKILL_W,    SKILL_R,    TALENT6,    TALENT8
}

local botMorph = dt:new()

function botMorph:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local morphlingBot = botMorph:new{abilityPriority = AbilityPriority}

function morphlingBot:DoHeroSpecificInit(bot)
end

function morphlingBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function morphlingBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function morphlingBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    morphlingBot:Think(bot)
end
