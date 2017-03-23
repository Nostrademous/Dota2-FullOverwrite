-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local viperAbility = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/fight_simul" )
require( GetScriptDirectory().."/modifiers" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

local Abilities ={
    "viper_poison_attack",
    "viper_nethertoxin",
    "viper_corrosive_skin",
    "viper_viper_strike"
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

local DoTdpsQ = 0
local DoTdpsUlt = 0

local AttackRange   = 0
local ManaPerc      = 0
local modeName      = nil

function viperAbility:nukeDamage( bot, enemy )
    if not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = bot:GetAttackRange()+bot:GetBoundingRadius()

    local magicImmune = utils.IsTargetMagicImmune(enemy)

    local baseRightClickDmg = CalcRightClickDmg(bot, enemy)

    -- Check Viper Strike
    if abilityR:IsFullyCastable() then
        local manaCostR = abilityR:GetManaCost()
        if manaCostR <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostR
                dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(abilityR:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
                castTime = castTime + abilityR:GetCastPoint()
                slowTime = slowTime + 5.1
                engageDist = Min(engageDist, abilityR:GetCastRange())
                table.insert(comboQueue, abilityR)
            end
        end
    end

    -- Check Poison Attack
    if abilityQ:IsFullyCastable() then
        if not magicImmune then
            local manaCostQ = abilityQ:GetManaCost()
            local numCasts = Min(bot:GetLevel(), 4)
            if abilityR:IsFullyCastable() then
                numCasts = math.ceil(5.1/bot:GetSecondsPerAttack())
            end

            for i = 1, numCasts, 1 do
                if manaCostQ <= manaAvailable then
                    manaAvailable = manaAvailable - manaCostQ
                    dmgTotal = dmgTotal + baseRightClickDmg + enemy:GetActualIncomingDamage(DoTdpsQ, DAMAGE_TYPE_MAGICAL)
                    castTime = castTime + bot:GetAttackPoint()
                    slowTime = slowTime + 2.0
                    table.insert(comboQueue, abilityQ)
                end
            end
        end
    end

    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function viperAbility:queueNuke(bot, enemy, castQueue, engageDist)
    if not utils.ValidTarget(enemy) then return false end
    
    local dist = GetUnitToUnitDistance(bot, enemy)

    -- if out of range, attack move for one hit to get in range
    if dist < engageDist then
        bot:Action_ClearActions(false)
        utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
        utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
        for i = #castQueue, 1, -1 do
            local skill = castQueue[i]

            if skill:GetName() == Abilities[1] then
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            elseif skill:GetName() == Abilities[4] then
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            end
        end
        return true
    end
    return false
end

function CalcRightClickDmg(bot, target)
    if not utils.ValidTarget(target) then return 0 end
    
    local bonusDmg = 0
    if abilityW ~= nil and abilityW:GetLevel() > 0 then
        bonusDmg = abilityW:GetSpecialValueFloat("bonus_damage")
        local tgtHealthPrct = target:GetHealth()/target:GetMaxHealth()
        local healthRank = math.ceil(tgtHealthPrct/20)
        bonusDmg = bonusDmg * math.pow(2, 5-healthRank)
    end

    local rightClickDmg = bot:GetAttackDamage() + bonusDmg
    local actualDmg = target:GetActualIncomingDamage(rightClickDmg, DAMAGE_TYPE_PHYSICAL)
    return actualDmg
end

function ComboDmg(bot, target)
    if not utils.ValidTarget(target) then return 0 end
    
    local dmg, castQueue, castTime, stunTime, slowTime, engageDist = viperAbility:nukeDamage( bot, target )
    local rightClickTime = stunTime + slowTime -- in Viper's case we don't discount the slow as he can cast it indefinitely (mana providing)

    DoTdpsQ   = target:GetActualIncomingDamage(abilityQ:GetSpecialValueInt("damage"), DAMAGE_TYPE_MAGICAL)

    DoTdpsR   = abilityR:GetSpecialValueInt("damage")
    if bot:GetLevel() >= 25 then
        local unique2 = bot:GetAbilityByName("special_bonus_unique_viper_2")
        if unique2 and unique2:GetLevel() >= 1 then
            DoTdpsR = DoTdpsR + 80
        end
    end
    DoTdpsR = target:GetActualIncomingDamage(DoTdpsR, DAMAGE_TYPE_MAGICAL)

    local totalDmgPerSec = (CalcRightClickDmg(bot, target) + DoTdpsR + DoTdpsQ)/bot:GetSecondsPerAttack()
    return totalDmgPerSec*rightClickTime
end

function viperAbility:AbilityUsageThink(bot)
    if utils.IsBusy(bot) then return true end

    if utils.IsUnableToCast(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    AttackRange   = bot:GetAttackRange() + bot:GetBoundingRadius()
    ManaPerc      = bot:GetMana()/bot:GetMaxMana()
    modeName      = bot.SelfRef:getCurrentMode():GetName()

    -- Consider using each ability
    local castQDesire, castQTarget  = ConsiderQ()
    local castRDesire, castRTarget  = ConsiderR()

    if castRDesire > 0 then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityR, castRTarget)
        return true
    end

    if castQDesire > 0 then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityQ, castQTarget)
        return true
    end

    return false
end

function ConsiderQ()
    local bot = GetBot()

    if not abilityQ:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
        local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, AttackRange + 100)
        if utils.ValidTarget(WeakestEnemy) then
            if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
                if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(ComboDmg(bot, WeakestEnemy), DAMAGE_TYPE_PHYSICAL) then
                    return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
                end
            end
        end
    end

    -- If we're going after someone
    if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
        local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

        if utils.ValidTarget(npcEnemy) then
            if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) and
                GetUnitToUnitDistance(bot, npcEnemy) < (AttackRange + 75*#gHeroVar.GetNearbyAllies(bot,1200)) then
                return BOT_ACTION_DESIRE_MODERATE, npcEnemy
            end
        end
    end

    -- If we are pushing a lane and have our level 25 building unique talent
    if modeName == "pushlane" and ManaPerc > 0.25 then
        local unique1 = bot:GetAbilityByName("special_bonus_unique_viper_1")
        if unique1 and unique1:GetLevel() >= 1 then
            local at = bot:GetAttackTarget()
            if utils.NotNilOrDead(at) and at:IsBuilding() then
                return BOT_ACTION_DESIRE_MODERATE, at
            end
        end
    end

    -- laning harassment
    if modeName == "laning" and ManaPerc > 0.4 then
        local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, AttackRange)
        if utils.ValidTarget(WeakestEnemy) then
            if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
                return BOT_ACTION_DESIRE_LOW, WeakestEnemy
            end
        end
    end

    -- jungling
    if modeName == "jungling" and ManaPerc > 0.25 then
        local neutralCreeps = gHeroVar.GetNearbyEnemyCreep(bot, AttackRange)
        for _, creep in pairs(neutralCreeps) do
            if not creep:HasModifier("modifier_viper_poison_attack_slow") and not creep:IsAncientCreep() then
                return BOT_ACTION_DESIRE_LOW, creep
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderR()
    local bot = GetBot()

    if not abilityR:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
        local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, AttackRange + 100)
        if utils.ValidTarget(WeakestEnemy) then
            if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
                if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(ComboDmg(bot, WeakestEnemy), DAMAGE_TYPE_PHYSICAL) then
                    return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
                end
            end
        end
    end

    -- If we're going after someone
    if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
        local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

        if utils.ValidTarget(npcEnemy) then
            if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) and
                GetUnitToUnitDistance(bot, npcEnemy) < (AttackRange + 75*#gHeroVar.GetNearbyAllies(bot,1200)) then
                return BOT_ACTION_DESIRE_MODERATE, npcEnemy
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

return viperAbility
