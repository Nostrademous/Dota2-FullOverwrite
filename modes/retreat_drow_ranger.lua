-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/constants")

local retreatMode = dofile( GetScriptDirectory().."/modes/retreat" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function X:GetName()
    return "retreat_drow_ranger"
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
    local me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")
    local defDesire = retreatMode:Desire(bot, nearbyEnemies, nearbyETowers, nearbyAllies)
    if defDesire == BOT_MODE_DESIRE_NONE then return BOT_MODE_DESIRE_NONE end

    local defReason = me:getHeroVar("RetreatReason")

	local healthThreshold = math.max(bot:GetMaxHealth()*0.15, 100)

    if defReason == constants.RETREAT_CREEP and me:getCurrentMode() == constants.MODE_JUNGLING then
        if bot:GetHealth() >= healthThreshold then -- we're fine..
            return BOT_MODE_DESIRE_NONE
        end
    end

    return defDesire
end

return X
