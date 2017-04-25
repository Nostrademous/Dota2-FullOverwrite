-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_shredder" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.shredder.SKILL_0
local SKILL_W = heroData.shredder.SKILL_1
local SKILL_E = heroData.shredder.SKILL_2
local SKILL_R = heroData.shredder.SKILL_5
local SKILL_R2= heroData.shredder.SKILL_3 -- chakram 2 (from Aghs)

local TALENT1 = heroData.shredder.TALENT_0
local TALENT2 = heroData.shredder.TALENT_1
local TALENT3 = heroData.shredder.TALENT_2
local TALENT4 = heroData.shredder.TALENT_3
local TALENT5 = heroData.shredder.TALENT_4
local TALENT6 = heroData.shredder.TALENT_5
local TALENT7 = heroData.shredder.TALENT_6
local TALENT8 = heroData.shredder.TALENT_7

local TimberAbilityPriority = {
    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_W,
    SKILL_R,    SKILL_E,    SKILL_E,    SKILL_W,    TALENT1,
    SKILL_W,    SKILL_R,    SKILL_Q,    SKILL_Q,    TALENT4,
    SKILL_Q,    SKILL_R,    TALENT6,    TALENT8
}

local botTimber = dt:new()

function botTimber:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local timberBot = botTimber:new{abilityPriority = TimberAbilityPriority}

function timberBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function timberBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function timberBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    timberBot:Think(bot)
end
