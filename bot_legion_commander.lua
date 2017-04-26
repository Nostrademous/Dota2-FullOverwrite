-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local heroData = require( GetScriptDirectory().."/hero_data" )
local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_legion_commander" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = heroData.legion_commander.SKILL_0
local SKILL_W = heroData.legion_commander.SKILL_1
local SKILL_E = heroData.legion_commander.SKILL_2
local SKILL_R = heroData.legion_commander.SKILL_3

local TALENT1 = heroData.legion_commander.TALENT_0
local TALENT2 = heroData.legion_commander.TALENT_1
local TALENT3 = heroData.legion_commander.TALENT_2
local TALENT4 = heroData.legion_commander.TALENT_3
local TALENT5 = heroData.legion_commander.TALENT_4
local TALENT6 = heroData.legion_commander.TALENT_5
local TALENT7 = heroData.legion_commander.TALENT_6
local TALENT8 = heroData.legion_commander.TALENT_7

local AbilityPriority = {
    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,    SKILL_Q,
    SKILL_R,    SKILL_E,    SKILL_W,    SKILL_W,    TALENT2,
    SKILL_Q,    SKILL_R,    SKILL_E,    SKILL_Q,    TALENT3,
    SKILL_Q,    SKILL_R,    TALENT5,    TALENT7
}

local botLC = dt:new()

function botLC:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local lcBot = botLC:new{abilityPriority = AbilityPriority}

function lcBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function lcBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function lcBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    lcBot:Think(bot)

    -- if we are initialized, do the rest
    if lcBot.Init then
        if (bot:GetLevel() >= 12 or utils.HaveItem(bot, "item_blink")) and
            getHeroVar("Role") ~= constants.ROLE_HARDCARRY then
            setHeroVar("Role", constants.ROLE_HARDCARRY)
            setHeroVar("CurLane", LANE_BOT) --FIXME: don't hardcode this
        end
    end
end

function lcBot:GetMaxClearableCampLevel(bot)
    if DotaTime() < 30 then
        return constants.CAMP_EASY
    end

    local abilityE = bot:GetAbilityByName(SKILL_E)
    if abilityE:GetLevel() >= 4 then
        return constants.CAMP_ANCIENT
    elseif utils.HaveItem(bot, "item_iron_talon") and abilityE:GetLevel() >= 2 then
        return constants.CAMP_HARD
    end

    return constants.CAMP_MEDIUM
end

function lcBot:IsReadyToGank(bot)
    local ult = bot:GetAbilityByName(SKILL_R)
    return ult:IsFullyCastable()
end

function lcBot:DoCleanCamp(bot, neutrals)
    if #neutrals == 0 then return end
    
    if #neutrals > 1 then
        table.sort(neutrals, function(n1, n2) return n1:GetHealth() < n2:GetHealth() end) -- sort by health
    end
    
    for i, neutral in ipairs(neutrals) do
        -- kill the Ghost first as they slow down our DPS tremendously by being around
        if utils.ValidTarget(neutral) and string.find(neutral:GetUnitName(), "ghost") ~= nil then
            gHeroVar.HeroAttackUnit(bot, neutral, true)
            return
        end
    end
    
    if utils.ValidTarget(neutrals[1]) then
        gHeroVar.HeroAttackUnit(bot, neutrals[1], true)
        return
    end
end
