-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_lina" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.lina.SKILL_0
local SKILL_W = heroData.lina.SKILL_1
local SKILL_E = heroData.lina.SKILL_2
local SKILL_R = heroData.lina.SKILL_3

local TALENT1 = heroData.lina.TALENT_0
local TALENT2 = heroData.lina.TALENT_1
local TALENT3 = heroData.lina.TALENT_2
local TALENT4 = heroData.lina.TALENT_3
local TALENT5 = heroData.lina.TALENT_4
local TALENT6 = heroData.lina.TALENT_5
local TALENT7 = heroData.lina.TALENT_6
local TALENT8 = heroData.lina.TALENT_7

local LinaAbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_Q,     SKILL_W,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,     SKILL_E,    TALENT1,
    SKILL_E,    SKILL_R,    SKILL_W,     SKILL_W,    TALENT3,
    SKILL_W,    SKILL_R,    TALENT5,     TALENT7
}

local botLina = dt:new()

function botLina:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local linaBot = botLina:new{abilityPriority = LinaAbilityPriority}

function linaBot:DoHeroSpecificInit(bot)
    setHeroVar("HasStun",  {{[1]=bot:GetAbilityByName(SKILL_W), [2]=0.95+getHeroVar("AbilityDelay")}})
end

function linaBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function linaBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function linaBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function linaBot:IsReadyToGank(bot)
    local ult = bot:GetAbilityByName(SKILL_R)
    if ult:IsFullyCastable() and utils.HaveItem(bot, "item_blink") then
        return true
    end
    return false
end

function Think()
    local bot = GetBot()
    
    linaBot:Think(bot)
end
