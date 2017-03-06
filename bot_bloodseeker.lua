-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_bloodseeker" )
require( GetScriptDirectory().."/ability_usage_bloodseeker" )
require( GetScriptDirectory().."/jungling_generic" )
require( GetScriptDirectory().."/debugging" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision_tree" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

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

local BloodseekerAbilityPriority = {
    BLOODSEEKER_SKILL_Q,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_Q,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_Q,
    BLOODSEEKER_SKILL_R,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_Q,    BLOODSEEKER_ABILITY2,
    BLOODSEEKER_SKILL_W,    BLOODSEEKER_SKILL_R,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_ABILITY4,
    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_R,    BLOODSEEKER_ABILITY5,   BLOODSEEKER_ABILITY8
};

local bloodseekerModeStack = { [1] = {constants.MODE_NONE, BOT_ACTION_DESIRE_NONE} }

botBS = dt:new()

function botBS:new(o)
    o = o or dt:new(o)
    setmetatable(o, self)
    self.__index = self
    return o
end

bloodseekerBot = botBS:new{modeStack = bloodseekerModeStack, abilityPriority = BloodseekerAbilityPriority}
--bloodseekerBot:printInfo()

bloodseekerBot.Init = false

function bloodseekerBot:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    ability_usage_bloodseeker.AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
end

function Think()
    local bot = GetBot()

    bloodseekerBot:Think(bot)

    ItemPurchaseThinkBS()

    -- if we are initialized, do the rest
    if bloodseekerBot.Init then
        if bot:GetLevel() >= 20 and getHeroVar("Role") ~= constants.ROLE_HARDCARRY then
            bloodseekerBot:RemoveMode(constants.MODE_JUNGLING)
            setHeroVar("Role", constants.ROLE_HARDCARRY)
            setHeroVar("CurLane", LANE_BOT) --FIXME: don't hardcode this
        end

        gHeroVar.ExecuteHeroActionQueue(bot)
    end
end

-- We over-write DoRetreat behavior for JUNGLER Bloodseeker
function bloodseekerBot:DoRetreat(bot, reason)
    -- if we got creep damage and are a JUNGLER do special stuff
    local pushing = self:getCurrentMode() == constants.MODE_PUSHLANE

    local bloodrage = bot:GetAbilityByName(BLOODSEEKER_SKILL_Q)
    local bloodragePct =  bloodrage:GetSpecialValueInt("health_bonus_creep_pct")/100

    local neutrals = bot:GetNearbyCreeps(500, true)
    if #neutrals == 0 then
        -- if we are retreating - piggyback on retreat logic movement code
        if self:getCurrentMode() == constants.MODE_RETREAT then
            -- we use '.' instead of ':' and pass 'self' so it is the correct self
            return dt.DoRetreat(self, bot, getHeroVar("RetreatReason"))
        end
        return false
    end
    table.sort(neutrals, function(n1, n2) return n1:GetHealth() < n2:GetHealth() end)

    local estimatedDamage = bot:GetEstimatedDamageToTarget(true, neutrals[1], bot:GetSecondsPerAttack(), DAMAGE_TYPE_PHYSICAL)
    --local actualDamage = neutrals[1]:GetActualIncomingDamage(estimatedDamage, DAMAGE_TYPE_PHYSICAL)
    local bloodrageHeal = bloodragePct * neutrals[1]:GetMaxHealth()

    if reason == constants.RETREAT_CREEP and self:getCurrentMode() == constants.MODE_JUNGLING then
        -- if our health is lower than maximum( 15% health, 100 health )
        local healthThreshold = math.max(bot:GetMaxHealth()*0.15, 100)

        if bot:GetHealth() < healthThreshold then
            local totalCreepDamage = 0

            for i, neutral in ipairs(neutrals) do
                local estimatedNCDamage = neutral:GetEstimatedDamageToTarget(true, bot, neutral:GetSecondsPerAttack(), DAMAGE_TYPE_ALL)
                local estimatedNCDamageTest = neutral:GetEstimatedDamageToTarget(true, bot, neutral:GetSecondsPerAttack(), DAMAGE_TYPE_PHYSICAL)
                -- TODO: Bs backs up although he could get a netural kill and heal himself. big satyr might have been involved.. keep an eye on that
                if (estimatedNCDamage > estimatedNCDamageTest + 20) then debugging.SetBotState(bot, 1, "IT'S MAGIC! "..estimatedNCDamage.." "..estimatedNCDamageTest) end
                totalCreepDamage = (totalCreepDamage + estimatedNCDamage)
            end

            if (estimatedDamage < neutrals[1]:GetHealth()) and (bot:GetHealth() + bloodrageHeal) < healthThreshold
            and (bot:GetHealth() < totalCreepDamage) then
                debugging.SetBotState(bot, 2, "Can't do it :(")
                setHeroVar("RetreatReason", constants.RETREAT_FOUNTAIN)
                if ( self:HasMode(constants.MODE_RETREAT) == false ) then
                    self:AddMode(constants.MODE_RETREAT)
                    setHeroVar("IsInLane", false)
                    return true
                end
            else
                return false
            end
        end
        -- if we are retreating - piggyback on retreat logic movement code
        if self:getCurrentMode() == constants.MODE_RETREAT then
            -- we use '.' instead of ':' and pass 'self' so it is the correct self
            return dt.DoRetreat(self, bot, getHeroVar("RetreatReason"))
        end

        -- we are not retreating, allow decision tree logic to fall through
        -- to the next level
        return false
    -- if we are not a jungler, invoke default DoRetreat behavior
    else
        -- we use '.' instead of ':' and pass 'self' so it is the correct self
        return dt.DoRetreat(self, bot, getHeroVar("RetreatReason"))
    end
    return true
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
    local thirst = bot:GetAbilityByName(BLOODSEEKER_SKILL_E)
    return rupture:IsFullyCastable() or thirst:GetLevel() >= 3
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

function bloodseekerBot:GetNukeDamage(bot, target)
    return ability_usage_bloodseeker.nukeDamage( bot, target )
end

function bloodseekerBot:QueueNuke(bot, target, actionQueue, engageDist)
    return ability_usage_bloodseeker.queueNuke( bot, target, actionQueue, engageDist )
end
