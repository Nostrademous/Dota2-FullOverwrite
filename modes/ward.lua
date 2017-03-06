-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )

----------
X.me            = nil

function X:GetName()
    return "ward"
end

function X:OnStart(myBot)
    X.me = myBot
end

function X:OnEnd()
    X.me:setHeryVar("WardType", nil)
    X.me:setHeroVar("WardLocation", nil)
    X.me:setHeroVar("WardCheckTimer", GameTime())
end

function X:Think(bot)
    local wardType = X.me:getHeryVar("WardType") or "item_ward_observer"
    local dest = X.me:getHeroVar("WardLocation")
    if dest ~= nil then
        local dist = GetUnitToLocationDistance(bot, dest)
        if dist <= constants.WARD_CAST_DISTANCE then
            local ward = item_usage.HaveWard(wardType)
            if ward then
                gHeroVar.HeroPushUseAbilityOnLocation(bot, ward, dest, constants.WARD_CAST_DISTANCE)
                X.me:ClearMode()
            end
        else
            bot:Action_MoveToLocation(bot, dest)
        end
    end
end

return X