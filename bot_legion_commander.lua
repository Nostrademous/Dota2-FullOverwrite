-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

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

local SKILL_Q = "legion_commander_overwhelming_odds"
local SKILL_W = "legion_commander_press_the_attack"
local SKILL_E = "legion_commander_moment_of_courage"
local SKILL_R = "legion_commander_duel"

local ABILITY1 = "special_bonus_strength_7"
local ABILITY2 = "special_bonus_exp_boost_20"
local ABILITY3 = "special_bonus_attack_damage_30"
local ABILITY4 = "special_bonus_movement_speed_20"
local ABILITY5 = "special_bonus_armor_7"
local ABILITY6 = "special_bonus_respawn_reduction_20"
local ABILITY7 = "special_bonus_unique_legion_commander"   -- +40 dmg duel bonus
local ABILITY8 = "special_bonus_unique_legion_commander_2" -- -8s Press the Attack

local AbilityPriority = {
    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,    SKILL_Q,
    SKILL_R,    SKILL_E,    SKILL_W,    SKILL_W,    ABILITY2,
    SKILL_Q,    SKILL_R,    SKILL_E,    SKILL_Q,    ABILITY4,
    SKILL_Q,    SKILL_R,    ABILITY6,   ABILITY8
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
        if bot:GetLevel() >= 16 and getHeroVar("Role") ~= constants.ROLE_HARDCARRY then
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

function lcBot:DoCleanCamp(bot, neutrals, difficulty)
    table.sort(neutrals, function(n1, n2) return n1:GetHealth() < n2:GetHealth() end) -- sort by health
    local it = utils.IsItemAvailable("item_iron_talon")
    if it ~= nil and difficulty ~= constants.CAMP_ANCIENT then -- we have an iron talon and not fighting ancients
        local it_target = neutrals[#neutrals] -- neutral with most health
        if it_target:GetHealth() > 0.5 * it_target:GetMaxHealth() then -- is it worth it? TODO: add a absolute minimum / use it on big guys only
            bot:Action_UseAbilityOnEntity(it, it_target)
            return
        end
    end
    for i, neutral in ipairs(neutrals) do
        -- kill the Ghost first as they slow down our DPS tremendously by being around
        if string.find(neutral:GetUnitName(), "ghost") ~= nil then
            gHeroVar.HeroAttackUnit(bot, neutral, true)
            return
        end
    end
    
    if #neutrals > 0 then
        gHeroVar.HeroAttackUnit(bot, neutrals[1], true)
        return
    end
end
