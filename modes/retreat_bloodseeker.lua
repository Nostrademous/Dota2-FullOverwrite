-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

local retreatMode = dofile( GetScriptDirectory().."/modes/retreat" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function X:GetName()
    return "retreat_bloodseeker"
end

function X:OnStart(myBot)
    retreatMode:OnStart(myBot)
end

function X:OnEnd()
    retreatMode:OnEnd()
end

function X:Think(bot)
    retreatMode:Think(bot)
end

function X:Desire(bot, nearbyEnemies, nearbyETowers, nearbyAllies)
    local neutrals = bot:GetNearbyCreeps(500, true)
    if #neutrals == 0 then
        return retreatMode:Desire(bot, nearbyEnemies, nearbyETowers, nearbyAllies)
    end
    table.sort(neutrals, function(n1, n2) return n1:GetHealth() < n2:GetHealth() end)

    local bloodrage = bot:GetAbilityByName("bloodseeker_bloodrage")
    local bloodragePct =  bloodrage:GetSpecialValueInt("health_bonus_creep_pct")/100
    local estimatedDamage = bot:GetEstimatedDamageToTarget(true, neutrals[1], bot:GetSecondsPerAttack(), DAMAGE_TYPE_PHYSICAL)
    local bloodrageHeal = bloodragePct * neutrals[1]:GetMaxHealth() 

    -- if we are a JUNGLER do special stuff
    local me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")
    if me:getCurrentMode():GetName() == "jungling" then
        -- if our health is lower than maximum( 15% health, 100 health )
        local healthThreshold = math.max(bot:GetMaxHealth()*0.15, 100)
        
        if bot:GetHealth() < healthThreshold then
            local totalCreepDamage = 0

            for i, neutral in ipairs(neutrals) do
                local estimatedNCDamage = neutral:GetEstimatedDamageToTarget(true, bot, neutral:GetSecondsPerAttack(), DAMAGE_TYPE_ALL)
                totalCreepDamage = (totalCreepDamage + estimatedNCDamage)
            end

            if (estimatedDamage < neutrals[1]:GetHealth()) and (bot:GetHealth() + bloodrageHeal) < healthThreshold
                and (bot:GetHealth() < totalCreepDamage) then
                
                return retreatMode:Desire(bot, nearbyEnemies, nearbyETowers, nearbyAllies)
            end
        end
        return BOT_MODE_DESIRE_NONE
    end
    
    return retreatMode:Desire(bot, nearbyEnemies, nearbyETowers, nearbyAllies)
end

return X