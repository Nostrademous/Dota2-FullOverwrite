-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_drow_ranger" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.drow_ranger.SKILL_0
local SKILL_W = heroData.drow_ranger.SKILL_1
local SKILL_E = heroData.drow_ranger.SKILL_2
local SKILL_R = heroData.drow_ranger.SKILL_3

local TALENT1 = heroData.drow_ranger.TALENT_0
local TALENT2 = heroData.drow_ranger.TALENT_1
local TALENT3 = heroData.drow_ranger.TALENT_2
local TALENT4 = heroData.drow_ranger.TALENT_3
local TALENT5 = heroData.drow_ranger.TALENT_4
local TALENT6 = heroData.drow_ranger.TALENT_5
local TALENT7 = heroData.drow_ranger.TALENT_6
local TALENT8 = heroData.drow_ranger.TALENT_7

local DrowRangerAbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_W,    SKILL_Q,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_E,    SKILL_E,    TALENT1,
    SKILL_W,    SKILL_R,    SKILL_E,    SKILL_W,    TALENT3,
    SKILL_W,    SKILL_R,    TALENT5,    TALENT8
}

local botDrow = dt:new()

function botDrow:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local drowRangerBot = botDrow:new{abilityPriority = DrowRangerAbilityPriority}

function drowRangerBot:DoHeroSpecificInit(bot)
end

function drowRangerBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function drowRangerBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function drowRangerBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    drowRangerBot:Think(bot)
end

function drowRangerBot:GetMaxClearableCampLevel(bot)
    if DotaTime() < 30 then
        return constants.CAMP_EASY
    end

    local marksmanship = bot:GetAbilityByName(SKILL_R)

    if utils.HaveItem(bot, "item_dragon_lance") and marksmanship:GetLevel() >= 1 then
        return constants.CAMP_ANCIENT
    elseif utils.HaveItem(bot, "item_power_treads") and marksmanship:GetLevel() >= 1 then
        return constants.CAMP_HARD
    end

    return constants.CAMP_MEDIUM
end

-- function drowRangerBot:IsReadyToGank(bot)
    -- local frostArrow = bot:GetAbilityByName("drow_ranger_frost_arrows")

    -- if utils.HaveItem(bot, "item_dragon_lance") and frostArrow:GetLevel >= 4 then
        -- return true
    -- end
    -- return false -- that's all we need
-- end

function drowRangerBot:DoCleanCamp(bot, neutrals, difficulty)
    local frostArrow = bot:GetAbilityByName(SKILL_Q)

    for i, neutral in ipairs(neutrals) do
        if utils.ValidTarget(neutral) then
            local slowed =  neutral:HasModifier("modifier_drow_ranger_frost_arrows_slow")

            if not slowed and not utils.IsTargetMagicImmune(neutral) then
                gHeroVar.HeroUseAbilityOnEntity(bot, frostArrow, neutral)
                return
            end

            gHeroVar.HeroAttackUnit(bot, neutral, true)
            return
        end
    end
end
