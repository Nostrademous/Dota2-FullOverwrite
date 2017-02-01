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
    }
}

function considerAbility(ability, hTarget)
    if not ability then return 0, 0, 0, 0, 0 end
    
    local channelTime = ability:GetChannelTime()
    if not ability:IsPassive() and ability:IsFullyCastable() and (not channelTime > 0) then
        local actualOneTimeCastDmg = ability:GetEstimatedDamageToTarget(hTarget, 10.0, ability:GetDamageType())
        return actualOneTimeCastDmg, ability:GetManaCost(), ability:GetCastPoint() --FIXME: Duration, Cooldown
    end
    
    if ability:IsFullyCastable() and channelTime > 0 then
        local actualOneTimeCastDmg = ability:GetEstimatedDamageToTarget(hTarget, channelTime, ability:GetDamageType())
        return actualOneTimeCastDmg, ability:GetManaCost(), ability:GetCastPoint(), channelTime --FIXME:, Cooldown
    end
    
    if ability:IsPassive() or ability:IsToggle() then
        -- check if it provides a buff
    end
    
    return 0, 0, 0, 0, 0
end

function getDmg(duration, hero, target)
    local manaPool = hero:GetMana()
    local abilityQ = hero:GetAbilityByName(skills.bloodseeker[1])
    local abilityW = hero:GetAbilityByName(skills.bloodseeker[2])
    local abilityE = hero:GetAbilityByName(skills.bloodseeker[3])
    local abilityR = hero:GetAbilityByName(skills.bloodseeker[4])
    
    local rightClickDmg = hero:GetAttackDamage()
    local rightClickCastPoint = hero:GetAttackPoint()
    
    local startTime = 0
    local totalDmg = 0
    while startTime < duration do
        --[[
        if considerAbility(abilityQ) then
            startTime = startTime + abilityQ:GetCastPoint()
            manaPool = manaPool - abilityQ:GetManaCost()
        end
        --]]
        
        totalDmg = totalDmg + target:GetActualDamage(rightClickDmg, DAMAGE_TYPE_PHYSICAL)
        startTime = startTime + rightClickDmg
    end
    
    return totalDmg
end

function estimateTimeToKill(hero, target)
    local rightClickDmg = hero:GetAttackDamage()
    local rightClickCastPoint = hero:GetAttackPoint()
    local actualDmg = target:GetActualDamage(rightClickDmg, DAMAGE_TYPE_PHYSICAL)
    
    local numHits = math.ceil(target:GetHealth()/actualDmg)
    return hero:GetSecondsPerAttack()*(numHits-1) + rightClickCastPoint
end

-------------------------------------------------------------------------------
for k,v in pairs( fight_simul ) do _G._savedEnv[k] = v end