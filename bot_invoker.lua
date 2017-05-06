-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_invoker" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.invoker.SKILL_0
local SKILL_W = heroData.invoker.SKILL_1
local SKILL_E = heroData.invoker.SKILL_2
local SKILL_R = heroData.invoker.SKILL_5

local TALENT1 = heroData.invoker.TALENT_0
local TALENT2 = heroData.invoker.TALENT_1
local TALENT3 = heroData.invoker.TALENT_2
local TALENT4 = heroData.invoker.TALENT_3
local TALENT5 = heroData.invoker.TALENT_4
local TALENT6 = heroData.invoker.TALENT_5
local TALENT7 = heroData.invoker.TALENT_6
local TALENT8 = heroData.invoker.TALENT_7

local AbilityPriority = {
    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_Q,    SKILL_E,
    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_E,    SKILL_Q,    SKILL_E,    TALENT2,    TALENT4,
    SKILL_W,    SKILL_W,    SKILL_Q,    SKILL_W,    TALENT5,
    SKILL_Q,    SKILL_W,    SKILL_Q,    SKILL_Q,    TALENT8
}

local botInv = dt:new()

function botInv:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local invBot = botInv:new{abilityPriority = AbilityPriority}

function invBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function invBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function invBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

-- RETURN: ability, damage, dmg_type, cast delay
function invBot:GetGlobalDamage()
    local bot = GetBot()
    
    local globalAbility = bot:GetAbilityByName("invoker_sun_strike")
    if globalAbility and globalAbility:IsFullyCastable() then
        if not globalAbility:IsHidden() then
            return globalAbility, globalAbility:GetSpecialValueFloat("damage"), DAMAGE_TYPE_PURE, 1.75
        else
            if bot:GetMana() >= (globalAbility:GetManaCost() + bot:GetAbilityByName(SKILL_R):GetManaCost()) then
                return globalAbility, globalAbility:GetSpecialValueFloat("damage"), DAMAGE_TYPE_PURE, (1.75 + 0.25)
            end
        end
    end
    
    return nil, 0, nil, 0
end

function invBot:UseGlobal( hTarget, hAbility, Loc )
    if utils.ValidTarget(hTarget) then
        local bot = GetBot()
        gHeroVar.HeroPushUseAbilityOnLocation(bot, hAbility, Loc)
        if hAbility:IsHidden() then
            bot:ActionPush_Delay(0.01)
            gHeroVar.HeroPushUseAbility(bot,  bot:GetAbilityByName(SKILL_R) )
            gHeroVar.HeroPushUseAbility(bot,  bot:GetAbilityByName(SKILL_E) )
            gHeroVar.HeroPushUseAbility(bot,  bot:GetAbilityByName(SKILL_E) )
            gHeroVar.HeroPushUseAbility(bot,  bot:GetAbilityByName(SKILL_E) )
        end
    end
end

function invBot:DoHeroSpecificInit(bot)
    setHeroVar("HasGlobal", {[1]=bot:GetAbilityByName("invoker_sun_strike"), [2]=1.75+getHeroVar("AbilityDelay")})
    setHeroVar("HasStun",  {{[1]=bot:GetAbilityByName("invoker_cold_snap"), [2]=0.05+getHeroVar("AbilityDelay")}})
end

function Think()
    local bot = GetBot()
    
    invBot:Think(bot)
end
