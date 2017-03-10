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

function nukeDamage( bot, enemy )
    if enemy == nil or enemy:IsNull() then return 0, {}, 0, 0, 0 end

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

function queueNuke(bot, enemy, castQueue, engageDist)
    local dist = GetUnitToUnitDistance(bot, enemy)

    -- if out of range, attack move for one hit to get in range
    if dist < engageDist then
        bot:Action_ClearActions(false)
        utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
        utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
        for i = #castQueue, 1, -1 do
            local skill = castQueue[i]

            if skill:GetName() == Abilities[1] then
                bot:ActionPush_UseAbilityOnEntity(skill, enemy)
            elseif skill:GetName() == Abilities[4] then
                bot:ActionPush_UseAbilityOnEntity(skill, enemy)
            end
        end
        return true
    end
    return false
end

function viperAbility:AbilityUsageThink(bot)
    if utils.IsBusy(bot) then return true end
    
    if getHeroVar("IsRetreating") then return true end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    local me = getHeroVar("Self")
    if me:getCurrentMode() == constants.MODE_RETREAT then return false end

    local nearbyEnemyHeroes = gHeroVar.GetNearbyEnemies(bot, 1200)

    if ( #nearbyEnemyHeroes == 0 ) then return false end

    local target = getHeroVar("Target")

    if not utils.ValidTarget(target) then
        target, _ = utils.GetWeakestHero(bot, bot:GetAttackRange()+200, nearbyEnemyHeroes)
        if target ~= nil then
            local dmg, castQueue, castTime, stunTime, slowTime, engageDist = nukeDamage( bot, target )
            local rightClickTime = stunTime + slowTime -- in Viper's case we don't discount the slow as he can cast it indefinitely (mana providing)
            local totalDmgPerSec = (CalcRightClickDmg(bot, target) + DoTdpsUlt + DoTdpsQ)/bot:GetSecondsPerAttack()
            if totalDmgPerSec*rightClickTime > target:GetHealth() then
                local bKill = queueNuke(bot, target, castQueue, engageDist)
                if bKill then
                    setHeroVar("Target", target)
                    return true
                end
            end
        end
    end

    if UseUlt(bot) or UseQ(bot, nearbyEnemyHeroes) then return true end

    return false
end

function UseQ(bot, nearbyEnemyHeroes)

    if not abilityQ:IsFullyCastable() then
        return false
    end

    -- harassment code when in lane
    --[[
    local manaRatio = bot:GetMana()/bot:GetMaxMana()
    local target, _ = utils.GetWeakestHero(bot, bot:GetAttackRange()+bot:GetBoundingRadius(), nearbyEnemyHeroes)
    if target ~= nil and manaRatio > 0.4 and GetUnitToUnitDistance(bot, target) then
        utils.TreadCycle(bot, constants.INTELLIGENCE)
        bot:Action_UseAbilityOnEntity(abilityQ, target)
        return true
    end
    --]]

    local target = getHeroVar("Target")

    -- if we don't have a valid target, return
    if not utils.ValidTarget(target) then return false end

    -- if target is magic immune or invulnerable, return
    if utils.IsTargetMagicImmune(target) then return false end

    -- set our local var
    DoTdpsQ = abilityQ:GetSpecialValueInt("damage")
    DoTdpsQ = target:GetActualIncomingDamage(DoTdpsQ, DAMAGE_TYPE_MAGICAL)

    if GetUnitToUnitDistance(bot, target) < (abilityQ:GetCastRange() + bot:GetBoundingRadius()) then
        utils.TreadCycle(bot, constants.INTELLIGENCE)
        bot:Action_UseAbilityOnEntity(abilityQ, target)
        return true
    end

    return false
end

function HasUlt(bot)
    if not abilityR:IsFullyCastable() then
        return false
    end

    return true
end

function UseUlt(bot)
    if not HasUlt(bot) then return false end

    local target = getHeroVar("Target")

    -- if we don't have a valid target, return
    if not utils.ValidTarget(target) then return false end

    -- if target is magic immune or invulnerable, return
    if target:IsMagicImmune() or target:IsInvulnerable() then return false end

    -- set our local var
    DoTdpsUlt = abilityR:GetSpecialValueInt("damage")

    if bot:GetLevel() >= 25 then
        local unique2 = bot:GetAbilityByName("special_bonus_unique_viper_2")
        if unique2 and unique2:GetLevel() >= 1 then
            DoTdpsUlt = DoTdpsUlt + 80
        end
    end

    DoTdpsUlt = target:GetActualIncomingDamage(DoTdpsUlt, DAMAGE_TYPE_MAGICAL)

    if GetUnitToUnitDistance(target, bot) < (abilityR:GetCastRange() + 100) then
        utils.TreadCycle(bot, constants.INTELLIGENCE)
        bot:Action_UseAbilityOnEntity(abilityR, target)
        return true
    end

    return false
end

function CalcRightClickDmg(bot, target)
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

return viperAbility
