-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_bloodseeker", package.seeall )

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
    "bloodseeker_bloodrage",
    "bloodseeker_blood_bath",
    "bloodseeker_thirst",
    "bloodseeker_rupture"
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

function nukeDamage( bot, enemy )
    if enemy == nil or enemy:IsNull() then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 10000

    local magicImmune = utils.IsTargetMagicImmune(enemy)
    
    -- Check Rupture
    if abilityR:IsFullyCastable() then
        local manaCostR = abilityR:GetManaCost()
        if manaCostR <= manaAvailable then
            manaAvailable = manaAvailable - manaCostR
            dmgTotal = dmgTotal + 200  -- 200 pure damage every 1/4 second if moving
            castTime = castTime + abilityR:GetCastPoint()
            stunTime = stunTime + 12.0
            engageDist = Min(engageDist, abilityR:GetCastRange())
            table.insert(comboQueue, abilityR)
        end
    end

    -- Check Blood Bath
    if abilityW:IsFullyCastable() then
        local manaCostW = abilityW:GetManaCost()
        if manaCostW <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostW
                dmgTotal = dmgTotal + abilityW:GetSpecialValueInt("damage") -- damage is pure, silence is magic
                castTime = castTime + abilityW:GetCastPoint()
                engageDist = Min(engageDist, abilityW:GetCastRange())
                table.insert(comboQueue, 1, abilityW)
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

            if skill:GetName() == Abilities[2] then
                if utils.IsCrowdControlled(enemy) or modifiers.IsRuptured(enemy) then
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
                else
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetExtrapolatedLocation(3.0))
                end
            elseif skill:GetName() == Abilities[4] then
                bot:ActionPush_UseAbilityOnEntity(skill, enemy)
            end
        end
        bot:ActionQueue_AttackUnit( enemy, false )
        return true
    end
    return false
end

local function UseW(bot, nearbyEnemyHeroes)
    if not abilityW:IsFullyCastable() then return false end

    if #nearbyEnemyHeroes == 1 and abilityR:IsFullyCastable() then
        setHeroVar("Target", {Obj=nearbyEnemyHeroes[1], Id=nearbyEnemyHeroes[1]:GetPlayerID()})
        return false
    end

    local target = getHeroVar("Target")
    if utils.ValidTarget(target) and GetUnitToUnitDistance(bot, target.Obj) > 1500 then
        return false
    end
    
    local delay = abilityW:GetSpecialValueFloat("delay_plus_castpoint_tooltip")
    if #nearbyEnemyHeroes == 1 then
        bot:Action_UseAbilityOnLocation(abilityW, nearbyEnemyHeroes[1]:GetExtrapolatedLocation(delay))
        return true
    else
        local center = utils.GetCenter(nearbyEnemyHeroes)
        if center ~= nil then
            bot:Action_UseAbilityOnLocation(abilityW, center)
            return true
        end
    end

    return false
end

local function UseUlt(bot, nearbyEnemyHeroes, nearbyEnemyTowers)
    if not abilityR:IsFullyCastable() then return false end

    local enemy = getHeroVar("Target")
    if not utils.ValidTarget(enemy) then return false end
    
    --[[
    if #nearbyEnemyHeroes == 0 and #nearbyEnemyTowers == 0 and (enemy:GetHealth()/enemy:GetMaxHealth()) < 0.2 then
        return false
    end
    --]]
    local timeToKillRightClicking = fight_simul.estimateTimeToKill(bot, enemy.Obj)
    --utils.myPrint("Estimating Time To Kill with Right Clicks: ", timeToKillRightClicking)
    if timeToKillRightClicking < 4.0 then
        utils.myPrint("Not Using Ult")
        return false
    end

    if GetUnitToUnitDistance(enemy.Obj, bot) < (abilityR:GetCastRange() - 100) then
        bot:Action_UseAbilityOnEntity(abilityR, enemy.Obj)
        return true
    end

    return false
end

local function UseQ(bot)
    if not abilityQ:IsFullyCastable() then return false end

    local enemy = getHeroVar("Target")
    if utils.ValidTarget(enemy) and GetUnitToUnitDistance(enemy.Obj, bot) < (abilityQ:GetCastRange() - 100) then
        bot:Action_UseAbilityOnEntity(abilityQ, enemy.Obj)
        return true
    end
    
    if bot:HasModifier("modifier_bloodseeker_bloodrage") then return false end
    
    bot:Action_UseAbilityOnEntity(abilityQ, bot)
    return true
end

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()
    
    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    if bot:IsChanneling() or bot:IsUsingAbility() then return false end

    if not utils.ValidTarget(getHeroVar("Target")) then return false end

    if UseQ(bot) then return true end
    
    if #nearbyEnemyHeroes == 0 then return false end
    
    if #nearbyEnemyHeroes == 1 then
        local enemy = nearbyEnemyHeroes[1]
        local dmg, castQueue, castTime, stunTime, slowTime, engageDist = nukeDamage( bot, enemy )

        dmg = dmg + fight_simul.estimateRightClickDamage( bot, enemy, 5.0 )

        -- magic immunity is already accounted for by nukeDamage()
        if dmg > enemy:GetHealth() then
            local bKill = queueNuke(bot, enemy, castQueue, engageDist)
            if bKill then
                setHeroVar("Target", {Obj=enemy, Id=enemy:GetPlayerID()})
                return true
            end
        end
    end

    if UseUlt(bot, nearbyEnemyHeroes, nearbyEnemyTowers) or UseW(bot, nearbyEnemyHeroes) then return true end
    
    return false
end

for k,v in pairs( ability_usage_bloodseeker ) do _G._savedEnv[k] = v end
