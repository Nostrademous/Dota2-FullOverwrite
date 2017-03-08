-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "defendlane"
end

function X:OnStart(myBot)
end

function X:OnEnd()
end

function X:Think(bot)
end

function X:Desire(bot)
    --[[
    local defInfo = getHeroVar("DoDefendLane")
    if #defInfo > 0 then
        return BOT_MODE_DESIRE_VERYHIGH
    end
    --]]
    return BOT_MODE_DESIRE_NONE
end

return X