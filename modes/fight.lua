-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

----------
X.me            = nil

function X:GetName()
    return "fight"
end

function X:OnStart(myBot)
    X.me = gHeroVar.GetVar(GetBot():GetPlayerID(), "Self")
end

function X:OnEnd()
    X.me = gHeroVar.GetVar(GetBot():GetPlayerID(), "Self")
    X.me:setHeroVar("Target", nil)
end

function X:Think(bot)
    X.me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")
    
    local target = X.me:getHeroVar("Target")
    if utils.ValidTarget(target) and target:IsAlive() then
        gHeroVar.HeroAttackUnit(bot, target, true)
    else
        X.me:setHeroVar("Target", nil)
    end
end

function X:Desire(bot, nearbyEnemies, nearbyAllies, nearbyETowers, nearbyATowers, nearbyECreeps, nearbyACreeps)
    X.me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")
    for _, enemy in pairs(nearbyEnemies) do
        if bot:WasRecentlyDamagedByHero( enemy, 1.5 ) then
            if (bot:GetHealth() + bot:GetAttackDamage()) > (enemy:GetHealth() + enemy:GetAttackDamage()) then
                X.me:setHeroVar("Target", enemy)
                return BOT_MODE_DESIRE_MODERATE
            end
        end
    end
    
    if X.me:getHeroVar("Target") then
        return BOT_MODE_DESIRE_LOW
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X