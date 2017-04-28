-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_obsidian_destroyer" )

local SKILL_Q = heroData.obsidian_destroyer.SKILL_0
local SKILL_W = heroData.obsidian_destroyer.SKILL_1
local SKILL_E = heroData.obsidian_destroyer.SKILL_2
local SKILL_R = heroData.obsidian_destroyer.SKILL_3

local TALENT1 = heroData.obsidian_destroyer.TALENT_0
local TALENT2 = heroData.obsidian_destroyer.TALENT_1
local TALENT3 = heroData.obsidian_destroyer.TALENT_2
local TALENT4 = heroData.obsidian_destroyer.TALENT_3
local TALENT5 = heroData.obsidian_destroyer.TALENT_4
local TALENT6 = heroData.obsidian_destroyer.TALENT_5
local TALENT7 = heroData.obsidian_destroyer.TALENT_6
local TALENT8 = heroData.obsidian_destroyer.TALENT_7

local AbilityPriority = {
    SKILL_W,    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_E,    TALENT1,
    SKILL_R,    SKILL_E,    SKILL_R,    SKILL_Q,    TALENT4,
    SKILL_Q,    SKILL_R,    TALENT5,    TALENT7
}

local botOD = dt:new()

function botOD:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local odBot = botOD:new{abilityPriority = AbilityPriority}

function odBot:DoHeroSpecificInit(bot)
    self:setHeroVar("HasOrbAbility", SKILL_Q)
end

function odBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function odBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function odBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    odBot:Think(bot)
end
