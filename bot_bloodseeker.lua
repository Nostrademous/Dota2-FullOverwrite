-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local ability = require( GetScriptDirectory().."/abilityUse/abilityUse_bloodseeker" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local SKILL_Q = "bloodseeker_bloodrage";
local SKILL_W = "bloodseeker_blood_bath";
local SKILL_E = "bloodseeker_thirst";
local SKILL_R = "bloodseeker_rupture";

local ABILITY1 = "special_bonus_attack_damage_25"
local ABILITY2 = "special_bonus_hp_225"
local ABILITY3 = "special_bonus_attack_speed_30"
local ABILITY4 = "special_bonus_unique_bloodseeker_2"
local ABILITY5 = "special_bonus_unique_bloodseeker_3"
local ABILITY6 = "special_bonus_all_stats_10"
local ABILITY7 = "special_bonus_unique_bloodseeker"
local ABILITY8 = "special_bonus_lifesteal_30"

local AbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_W,    SKILL_E,    SKILL_Q,    ABILITY2,
    SKILL_W,    SKILL_R,    SKILL_W,    SKILL_W,    ABILITY4,
    SKILL_E,    SKILL_R,    ABILITY5,   ABILITY8
}

local botBS = dt:new()

function botBS:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

local bloodseekerBot = botBS:new{abilityPriority = AbilityPriority}

function bloodseekerBot:ConsiderAbilityUse()
    return ability.AbilityUsageThink(GetBot())
end

function bloodseekerBot:GetNukeDamage(bot, target)
    return ability.nukeDamage( bot, target )
end

function bloodseekerBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability.queueNuke( bot, target, actionQueue, engageDist )
end

function Think()
    local bot = GetBot()

    bloodseekerBot:Think(bot)

    -- if we are initialized, do the rest
    if bloodseekerBot.Init then
        if bot:GetLevel() >= 12 and getHeroVar("Role") ~= constants.ROLE_HARDCARRY then
            setHeroVar("Role", constants.ROLE_HARDCARRY)
            setHeroVar("CurLane", LANE_BOT) --FIXME: don't hardcode this
            bot.RetreatHealthPerc = 0.25
        end
    end
end

function bloodseekerBot:GetMaxClearableCampLevel(bot)
    if DotaTime() < 30 then
        return constants.CAMP_EASY
    end

    local bloodrage = bot:GetAbilityByName(SKILL_Q)
    if bloodrage:GetLevel() >= 4 then
        return constants.CAMP_ANCIENT
    elseif (utils.HaveItem(bot, "item_iron_talon") and bloodrage:GetLevel() >= 2) or bloodrage:GetLevel() >= 3 then
        return constants.CAMP_HARD
    end

    return constants.CAMP_MEDIUM
end

function bloodseekerBot:DoHeroSpecificInit(bot)
    bot.RetreatHealthPerc = 0.1
end

function bloodseekerBot:IsReadyToGank(bot)
    local rupture = bot:GetAbilityByName(SKILL_R)
    return rupture:IsFullyCastable() or (bot:GetCurrentMovementSpeed() >= 420 and bot:GetLevel() > 5)
end

function bloodseekerBot:DoCleanCamp(bot, neutrals)
    if #neutrals == 0 then return end
    
    local bloodraged = bot:HasModifier("modifier_bloodseeker_bloodrage")

    if #neutrals > 1 then
        table.sort(neutrals, function(n1, n2) return n1:GetHealth() < n2:GetHealth() end) -- sort by health
    end
    
    for _, neutral in pairs(neutrals) do
        -- kill the Ghost first as they slow down our DPS tremendously by being around
        if utils.ValidTarget(neutral) and string.find(neutral:GetUnitName(), "ghost") ~= nil and bloodraged then
            gHeroVar.HeroAttackUnit(bot, neutral, true)
            return
        end
    end
    for _, neutral in pairs(neutrals) do
        if utils.ValidTarget(neutral) then
            local eDamage = bot:GetEstimatedDamageToTarget(true, neutral, bot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL)
            if (eDamage < neutral:GetHealth() or bloodraged) then -- make sure we lasthit with bloodrage on
                gHeroVar.HeroAttackUnit(bot, neutral, true)
                return
            end
        end
    end
    -- TODO: don't attack if we should wait on all neutrals!
end
