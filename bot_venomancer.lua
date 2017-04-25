-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_venomancer" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.venomancer.SKILL_0
local SKILL_W = heroData.venomancer.SKILL_1
local SKILL_E = heroData.venomancer.SKILL_2
local SKILL_R = heroData.venomancer.SKILL_3

local TALENT1 = heroData.venomancer.TALENT_0
local TALENT2 = heroData.venomancer.TALENT_1
local TALENT3 = heroData.venomancer.TALENT_2
local TALENT4 = heroData.venomancer.TALENT_3
local TALENT5 = heroData.venomancer.TALENT_4
local TALENT6 = heroData.venomancer.TALENT_5
local TALENT7 = heroData.venomancer.TALENT_6
local TALENT8 = heroData.venomancer.TALENT_7

local AbilityPriority = {
    SKILL_Q,    SKILL_W,    SKILL_E,    SKILL_E,    SKILL_E,
    SKILL_R,    SKILL_E,    SKILL_W,    SKILL_W,    SKILL_W,
    TALENT1,    SKILL_R,    SKILL_Q,    SKILL_Q,    TALENT4,
    SKILL_Q,    SKILL_R,    TALENT5,    TALENT8
}

local botVM = dt:new()

function botVM:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local vmBot = botVM:new{abilityPriority = AbilityPriority}

function vmBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function vmBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function vmBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    vmBot:Think(bot)
end
