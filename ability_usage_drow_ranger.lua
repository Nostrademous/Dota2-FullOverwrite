-------------------------------------------------------------------------------
--- AUTHOR: pbenologa, Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_drow_ranger", package.seeall )

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    local bot = bot or GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = bot or GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local Abilities ={
    "drow_ranger_frost_arrows",
    "drow_ranger_wave_of_silence",
    "drow_ranger_trueshot",
    "drow_ranger_marksmanship"
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

function nukeDamage( bot, enemy )
    if enemy == nil or not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    
    local magicImmune = utils.IsTargetMagicImmune(enemy)
    
    -- Check Frost Arrows
    if abilityQ:IsFullyCastable() then
        if not magicImmune then
            local manaCostQ = abilityQ:GetManaCost()
            local speedReduction = abilityQ:GetSpecialValueInt("frost_arrows_movement_speed")
            local numCasts = 1
            
            local dist = GetUnitToUnitDistance(bot, enemy)
            if dist < (bot:GetAttackRange() + bot:GetBoundingRadius() + enemy:GetBoundingRadius()) then
                if bot:GetCurrentMovementSpeed() > (enemy:GetCurrentMovementSpeed() + speedReduction) then
                    numCasts = Min(10, math.floor(manaAvailable/12))
                else
                    local distToEscape = (bot:GetAttackRange() + bot:GetBoundingRadius() + enemy:GetBoundingRadius()) - dist
                    local timeToEscape = distToEscape/(enemy:GetCurrentMovementSpeed() + speedReduction - bot:GetCurrentMovementSpeed())
                    numCasts = Min(math.floor(timeToEscape/bot:GetSecondsPerAttack()), math.floor(manaAvailable/12))
                end
            end
            
            for i = 1, numCasts, 1 do
                if manaCostQ <= manaAvailable then
                    manaAvailable = manaAvailable - manaCostQ
                    dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
                    castTime = castTime + abilityQ:GetAttackPoint()
                    slowTime = slowTime + 1.5
                    table.insert(comboQueue, abilityQ)
                end
            end
        end
    end
    
    return dmgTotal, comboQueue, castTime, stunTime, slowTime
end

function queueNuke(bot, enemy, castQueue)
    local nCastRange = bot:GetAttackRange() + bot:GetBoundingRadius() + enemy:GetBoundingRadius()
    local dist = GetUnitToUnitDistance(bot, enemy)

    bot:Action_ClearActions()

    -- if out of range, attack move for one hit to get in range
    if dist > nCastRange then
        bot:ActionPush_AttackUnit( enemy, true )
    end

    utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
    utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
    for i = #castQueue, 1, -1 do
        local skill = castQueue[i]

        if skill:GetName() == Abilities[1] then
            bot:Action_UseAbilityOnEntity(skill, enemy)
        elseif skill:GetName() == Abilities[2] then
            gHeroVar.HeroPushUseAbilityOnLocation(skill, enemy)
        end
    end
    bot:ActionQueue_AttackUnit( enemy, false )
end

local function UseQ(bot)
    if not abilityQ:IsFullyCastable() then
        return false
    end

    -- harassment code when in lane
    --[[
    local manaRatio = bot:GetMana()/bot:GetMaxMana()
    local target, _ = utils.GetWeakestHero(bot, bot:GetAttackRange()+bot:GetBoundingRadius(), nearbyEnemyHeroes)
    if target ~= nil and manaRatio > 0.4 and GetUnitToUnitDistance(bot, target) then
        utils.TreadCycle(bot, constants.INTELLIGENCE)
        bot:Action_UseAbilityOnEntity(ability, target)
        return true
    end
    --]]

    target = getHeroVar("Target")

    -- if we don't have a valid target, return
    if not utils.ValidTarget(target) then return false end

    -- if target is magic immune or invulnerable return
    if utils.IsTargetMagicImmune(target.Obj) then return false end

    if GetUnitToUnitDistance(bot, target.Obj) < (abilityQ:GetCastRange() + bot:GetBoundingRadius()) then
        utils.TreadCycle(bot, constants.INTELLIGENCE)
        bot:Action_UseAbilityOnEntity(abilityQ, target.Obj)
        return true
    end

    return false
end

local function UseW(bot, nearbyEnemyHeroes)
    if not abilityW:IsFullyCastable() then
        return false
    end

    if #nearbyEnemyHeroes == 0 then return false end

    local wave_speed = abilityW:GetSpecialValueFloat("wave_speed")

    --Use gust to break channeling spells
    for _, enemy in pairs( nearbyEnemyHeroes ) do
        if GetUnitToUnitDistance(bot, enemy) < abilityW:GetCastRange() and enemy:IsChanneling() then
            if not enemy:IsMagicImmune() then
                local gustDelay = abilityW:GetCastPoint() + GetUnitToUnitDistance(bot, enemy)/wave_speed
                utils.TreadCycle(bot, constants.INTELLIGENCE)
                bot:Action_UseAbilityOnLocation(abilityW, enemy:GetExtrapolatedLocation(gustDelay))
                return true
            end
        end
    end

    --Use Gust as a Defensive skill to fend off chasing enemies
    if getHeroVar("IsRetreating") and (bot:GetHealth()/bot:GetMaxHealth()) < 0.5 then
        for _, enemy in pairs( nearbyEnemyHeroes ) do
            if GetUnitToUnitDistance(bot, enemy) < 150 and (not enemy:IsMagicImmune()) then
                local gustDelay = abilityW:GetCastPoint() + GetUnitToUnitDistance(bot, enemy)/wave_speed
                utils.TreadCycle(bot, constants.INTELLIGENCE)
                bot:Action_UseAbilityOnLocation(abilityW, enemy:GetExtrapolatedLocation(gustDelay))
                return true
            end
        end
    end

    return false
end

local function UseE(bot, nearbyEnemyTowers, nearbyAlliedCreep)
    if not abilityE:IsFullyCastable() then
        return false
    end
    -- TODO: use GetAttackTarget() to check if drow is attacking a tower before using trueshot not sure which is better

    if #nearbyEnemyTowers == 0 then return false end

    local rangedCnt = 0
    for i, creeps in ipairs(nearbyAlliedCreep) do
        if (utils.IsMelee(creeps)) then
            rangedCnt = rangedCnt + 1
        end
    end

    if #nearbyEnemyTowers > 0 and rangedCnt > 3 then
        gHeroVar.HeroUseAbility(bot, abilityE)
        return true
    end

    return false
end

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    if not bot:IsAlive() then return false end

    -- Check if we're already using an ability
    if bot:IsUsingAbility() or bot:IsChanneling() then return false end
    
    if ( #nearbyEnemyHeroes == 0 and #nearbyEnemyCreep == 0 ) then return false end
    
    local target = getHeroVar("Target")
    if not utils.ValidTarget(target) then
        if #nearbyEnemyHeroes == 1 then
            target = nearbyEnemyHeroes[1]
            if GetUnitToUnitDistance(bot, target) < (bot:GetAttackRange() + bot:GetBoundingRadius() + target:GetBoundingRadius()) then
                local dmg, castQueue, castTime, stunTime, slowTime = nukeDamage( bot, target )

                if dmg > target:GetHealth() then
                    setHeroVar("Target", {Obj=target, Id=target:GetPlayerID()})
                    queueNuke(bot, target, castQueue)
                    return true
                end
            end
        end
    end

    if UseE(bot, nearbyEnemyTowers, nearbyAlliedCreep) then return true end

    if UseW(bot, nearbyEnemyHeroes) then return true end

    if UseQ(bot, nearbyEnemyHeroes) then return true end

    return false
end

for k,v in pairs( ability_usage_drow_ranger ) do _G._savedEnv[k] = v end
