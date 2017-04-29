-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_razor" )

local SKILL_Q = heroData.razor.SKILL_0
local SKILL_W = heroData.razor.SKILL_1
local SKILL_E = heroData.razor.SKILL_2
local SKILL_R = heroData.razor.SKILL_3

local TALENT1 = heroData.razor.TALENT_0
local TALENT2 = heroData.razor.TALENT_1
local TALENT3 = heroData.razor.TALENT_2
local TALENT4 = heroData.razor.TALENT_3
local TALENT5 = heroData.razor.TALENT_4
local TALENT6 = heroData.razor.TALENT_5
local TALENT7 = heroData.razor.TALENT_6
local TALENT8 = heroData.razor.TALENT_7

local AbilityPriority = {
    SKILL_W,    SKILL_E,    SKILL_W,    SKILL_Q,    SKILL_Q,
    SKILL_Q,    SKILL_Q,    SKILL_R,    SKILL_E,    TALENT2,
    SKILL_E,    SKILL_R,    SKILL_E,    SKILL_W,    TALENT3,
    SKILL_W,    SKILL_R,    TALENT6,    TALENT7
}

local botRazor = dt:new()

function botRazor:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local razorBot = botRazor:new{abilityPriority = AbilityPriority}

function razorBot:DoHeroSpecificInit(bot)
end

function razorBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function razorBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function razorBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    razorBot:Think(bot)
end
