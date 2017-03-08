
-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "rune"
end

function X:OnStart(myBot)
end

function X:OnEnd()
    setHeroVar("RuneTarget", nil)
    setHeroVar("RuneLoc", nil)
end

function X:Think(bot)
    assert(getHeroVar("RuneLoc") ~= nil, "[runes.lua] Think() - runeLoc is 'false'")

    if utils.IsBusy(bot) then return end

    local dist = utils.GetDistance(bot:GetLocation(), getHeroVar("RuneLoc"))
    if dist > 500 then
        gHeroVar.HeroMoveToLocation(bot, getHeroVar("RuneLoc"))
    else
        if GetRuneStatus(getHeroVar("RuneTarget")) ~= RUNE_STATUS_MISSING then
            bot:Action_PickUpRune(getHeroVar("RuneTarget"))
        end
    end
end

function X:Desire(bot)
end

return X