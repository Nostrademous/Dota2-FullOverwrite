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

local BLOODSEEKER_SKILL_Q = "bloodseeker_bloodrage";
local BLOODSEEKER_SKILL_W = "bloodseeker_blood_bath";
local BLOODSEEKER_SKILL_E = "bloodseeker_thirst";
local BLOODSEEKER_SKILL_R = "bloodseeker_rupture";

local BLOODSEEKER_ABILITY1 = "special_bonus_attack_damage_25"
local BLOODSEEKER_ABILITY2 = "special_bonus_hp_200"
local BLOODSEEKER_ABILITY3 = "special_bonus_attack_speed_30"
local BLOODSEEKER_ABILITY4 = "special_bonus_unique_bloodseeker_2"
local BLOODSEEKER_ABILITY5 = "special_bonus_unique_bloodseeker_3"
local BLOODSEEKER_ABILITY6 = "special_bonus_all_stats_10"
local BLOODSEEKER_ABILITY7 = "special_bonus_unique_bloodseeker"
local BLOODSEEKER_ABILITY8 = "special_bonus_lifesteal_30"

local AbilityPriority = {
    BLOODSEEKER_SKILL_Q,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_Q,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_Q,
    BLOODSEEKER_SKILL_R,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_Q,    BLOODSEEKER_ABILITY2,
    BLOODSEEKER_SKILL_W,    BLOODSEEKER_SKILL_R,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_ABILITY4,
    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_R,    BLOODSEEKER_ABILITY5,   BLOODSEEKER_ABILITY8
}

local botBS = dt:new()

function botBS:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

bloodseekerBot = botBS:new{abilityPriority = AbilityPriority}

function bloodseekerBot:ConsiderAbilityUse()
    ability.AbilityUsageThink(GetBot())
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

    ItemPurchaseThinkBS()

    -- if we are initialized, do the rest
    if bloodseekerBot.Init then
        if bot:GetLevel() >= 16 and getHeroVar("Role") ~= constants.ROLE_HARDCARRY then
            setHeroVar("Role", constants.ROLE_HARDCARRY)
            setHeroVar("CurLane", LANE_BOT) --FIXME: don't hardcode this
        end
    end
end

function bloodseekerBot:GetMaxClearableCampLevel(bot)
    if DotaTime() < 30 then
        return constants.CAMP_EASY
    end

    local bloodrage = bot:GetAbilityByName(BLOODSEEKER_SKILL_Q)
    if bloodrage:GetLevel() >= 4 then
        return constants.CAMP_ANCIENT
    elseif utils.HaveItem(bot, "item_iron_talon") and bloodrage:GetLevel() >= 2 then
        return constants.CAMP_HARD
    end

    return constants.CAMP_MEDIUM
end

function bloodseekerBot:IsReadyToGank(bot)
    local rupture = bot:GetAbilityByName(BLOODSEEKER_SKILL_R)
    return rupture:IsFullyCastable() or bot:GetCurrentMovementSpeed() >= 420
end

function bloodseekerBot:DoCleanCamp(bot, neutrals, difficulty)
    local bloodraged =  bot:HasModifier("modifier_bloodseeker_bloodrage")
    local bloodrage = bot:GetAbilityByName(BLOODSEEKER_SKILL_Q)
    if not bloodraged and bloodrage:IsCooldownReady() then -- bloodrage all the time
        bot:Action_UseAbilityOnEntity(bloodrage, bot)
    end
    table.sort(neutrals, function(n1, n2) return n1:GetHealth() < n2:GetHealth() end) -- sort by health
    local it = utils.IsItemAvailable("item_iron_talon")
    if bloodraged and it ~= nil and difficulty ~= constants.CAMP_ANCIENT then -- we are bloodraged and have an iron talon and not fighting ancients
        local it_target = neutrals[#neutrals] -- neutral with most health
        if it_target:GetHealth() > 0.5 * it_target:GetMaxHealth() then -- is it worth it? TODO: add a absolute minimum / use it on big guys only
            bot:Action_UseAbilityOnEntity(it, it_target)
        end
    end
    for i, neutral in ipairs(neutrals) do
        -- kill the Ghost first as they slow down our DPS tremendously by being around
        if string.find(neutral:GetUnitName(), "ghost") ~= nil and bloodraged then
            gHeroVar.HeroAttackUnit(bot, neutral, true)
            return
        end
    end
    for i, neutral in ipairs(neutrals) do
        local eDamage = bot:GetEstimatedDamageToTarget(true, neutral, bot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL)
        if (eDamage < neutral:GetHealth() or bloodraged) then -- make sure we lasthit with bloodrage on
            gHeroVar.HeroAttackUnit(bot, neutral, true)
            break
        end
    end
    -- TODO: don't attack if we should wait on all neutrals!
end
