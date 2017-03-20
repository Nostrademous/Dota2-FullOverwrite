-------------------------------------------------------------------------------
--- AUTHOR: Keithen, Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local bsAbility = BotsInit.CreateGeneric()

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

local bsTarget = nil

local Abilities = {
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
        bot:Action_ClearActions(true)
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
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            end
        end
        gHeroVar.HeroQueueAttackUnit( bot, enemy, false )
        bot:ActionQueue_Delay(0.01)
        return true
    end
    return false
end

local function UseW(bot, nearbyEnemyHeroes)
    if not abilityW:IsFullyCastable() then return false end

    if #nearbyEnemyHeroes == 1 and abilityR:IsFullyCastable() then
        setHeroVar("Target", nearbyEnemyHeroes[1])
        return false
    end

    if bsTarget and GetUnitToUnitDistance(bot, bsTarget) > 1500 then
        return false
    end
    
    local delay = abilityW:GetSpecialValueFloat("delay_plus_castpoint_tooltip")
    if #nearbyEnemyHeroes == 1 then
        gHeroVar.HeroUseAbilityOnLocation(bot, abilityW, nearbyEnemyHeroes[1]:GetExtrapolatedLocation(delay))
        return true
    else
        local center = utils.GetCenter(nearbyEnemyHeroes)
        if center ~= nil then
            gHeroVar.HeroUseAbilityOnLocation(bot, abilityW, center)
            return true
        end
    end

    return false
end

local function UseUlt(bot)
    if not abilityR:IsFullyCastable() then return false end

    if not utils.NotNilOrDead(bsTarget) then return false end
    
    local timeToKillRightClicking = fight_simul.estimateTimeToKill(bot, bsTarget)
    --utils.myPrint("Estimating Time To Kill with Right Clicks: ", timeToKillRightClicking)
    if timeToKillRightClicking < 4.0 then
        utils.myPrint("Not Using Ult")
        return false
    end

    if GetUnitToUnitDistance(bsTarget, bot) < (abilityR:GetCastRange() - 100) then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityR, bsTarget)
        return true
    end

    return false
end

local function UseQ(bot)
    if not abilityQ:IsFullyCastable() then return false end

    if utils.NotNilOrDead(bsTarget) and GetUnitToUnitDistance(bsTarget, bot) < (abilityQ:GetCastRange() - 100) then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityQ, bsTarget)
        return true
    end
    
    if bot:HasModifier("modifier_bloodseeker_bloodrage") then return false end
    
    gHeroVar.HeroUseAbilityOnEntity(bot, abilityQ, bot)
    return true
end

function bsAbility:AbilityUsageThink(bot)
    if utils.IsBusy(bot) then return true end
    
    if getHeroVar("IsRetreating") then return true end
    
    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    bsTarget = getHeroVar("Target")
    if bsTarget == nil then bsTarget = getHeroVar("RoamTarget") end

    if UseQ(bot) then return end
    
    local nearbyEnemyHeroes = gHeroVar.GetNearbyEnemies(bot, 1600)
    if not bsTarget then
        if #nearbyEnemyHeroes == 0 then return end
        
        if #nearbyEnemyHeroes == 1 then
            local enemy = nearbyEnemyHeroes[1]
            local dmg, castQueue, castTime, stunTime, slowTime, engageDist = nukeDamage( bot, enemy )

            dmg = dmg + fight_simul.estimateRightClickDamage( bot, enemy, 5.0 )

            -- magic immunity is already accounted for by nukeDamage()
            if dmg > enemy:GetHealth() then
                local bKill = queueNuke(bot, enemy, castQueue, engageDist)
                if bKill then
                    setHeroVar("Target", enemy)
                    return 
                end
            end
        end
    end

    if UseUlt(bot) or UseW(bot, nearbyEnemyHeroes) then return true end
    return false
end

return bsAbility
