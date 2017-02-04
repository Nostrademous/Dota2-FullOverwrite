-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "fight_simul", package.seeall )
-------------------------------------------------------------------------------

local skills = { 
    bloodseeker = {
        "bloodseeker_bloodrage", 
        "bloodseeker_blood_bath", 
        "bloodseeker_thirst", 
        "bloodseeker_rupture"
    },
    lion = {
        "lion_impale", 
        "lion_voodoo", 
        "lion_mana_drain", 
        "lion_finger_of_death"
    },
    lina = {
        "lina_light_strike_array",
        "lina_dragon_slave",
        "lina_fiery_soul",
        "lina_laguna_blade"
    }
}

function considerAbility(ability, hTarget)
    if not ability then return 0, 0, 0, 0, 0 end
    
    local channelTime = ability:GetChannelTime()
    if not ability:IsPassive() and ability:IsFullyCastable() and (not channelTime > 0) then
        local actualOneTimeCastDmg = ability:GetEstimatedDamageToTarget(hTarget, 10.0, ability:GetDamageType())
        return actualOneTimeCastDmg, ability:GetManaCost(), ability:GetCastPoint(), 0, ability:GetCooldown() --FIXME: Duration
    end
    
    if ability:IsFullyCastable() and channelTime > 0 then
        local actualOneTimeCastDmg = ability:GetEstimatedDamageToTarget(hTarget, channelTime, ability:GetDamageType())
        return actualOneTimeCastDmg, ability:GetManaCost(), ability:GetCastPoint(), channelTime, ability:GetCooldown()
    end
    
    if ability:IsPassive() or ability:IsToggle() then
        -- check if it provides a buff
    end
    
    return 0, 0, 0, 0, 0
end

function getLinaDmg(duration, hero, target)
    local manaPool = hero:GetMana()
    local abilityQ = hero:GetAbilityByName(skills.lina[1])
    local abilityW = hero:GetAbilityByName(skills.lina[2])
    local abilityE = hero:GetAbilityByName(skills.lina[3])
    local abilityR = hero:GetAbilityByName(skills.lina[4])
    
    local rightClickDmg = hero:GetAttackDamage()
    local rightClickCastPoint = hero:GetAttackPoint()
    
    local qDmg, qMC, qCP, qDur, qCD = considerAbility(abilityQ, target)
    local wDmg, wMC, wCP, wDur, wCD = considerAbility(abilityW, target)
    local eDmg, eMC, eCP, eDur, eCD = considerAbility(abilityE, target)
    local rDmg, rMC, rCP, rDur, rCD = considerAbility(abilityR, target)
    
    local comboTimeToCast = qCP + wCP + eCP + rCP
    local comboDamage = qDmg + wDmg + eDmg + rDmg
    local comboManaCost = qMc + wMC + eMC + rMC
    
    local startTime = 0
    local totalDmg = 0
    while startTime < duration do
        considerAbility(abilityQ)
        
        totalDmg = totalDmg + target:GetActualIncomingDamage(rightClickDmg, DAMAGE_TYPE_PHYSICAL)
        startTime = startTime + rightClickDmg
    end
    
    return totalDmg
end

function estimateTimeToKill(hero, target)
    local rightClickDmg = hero:GetAttackDamage()
    local rightClickCastPoint = hero:GetAttackPoint()
    local actualDmg = target:GetActualIncomingDamage(rightClickDmg, DAMAGE_TYPE_PHYSICAL)
    
    local numHits = math.ceil(target:GetHealth()/actualDmg)
    return hero:GetSecondsPerAttack()*(numHits-1) + rightClickCastPoint
end

-------------------------------------------------------------------------------
for k,v in pairs( fight_simul ) do _G._savedEnv[k] = v end