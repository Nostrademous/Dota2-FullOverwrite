
-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

----------
X.me            = nil
X.runeLoc       = nil
X.runeTarget    = nil

function X:GetName()
    return "rune"
end

function X:OnStart(myBot)
    X.me = gHeroVar.GetVar(GetBot():GetPlayerID(), "Self")
    X.runeLoc = X.me:getHeroVar("RuneLoc")
    X.runeTarget = X.me:getHeroVar("RuneTarget")
end

function X:OnEnd()
    X.me = gHeroVar.GetVar(GetBot():GetPlayerID(), "Self")
    X.me:setHeroVar("RuneTarget", nil)
    X.me:setHeroVar("RuneLoc", nil)
end

function X:Think(bot)
    assert(X.runeLoc ~= nil, "[runes.lua] Think() - runeLoc is 'false'")
    X.me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")

    if utils.IsBusy(bot) then return end

    local dist = utils.GetDistance(bot:GetLocation(), X.runeLoc)
    if dist > 500 then
        gHeroVar.HeroMoveToLocation(bot, X.runeLoc)
    else
        if GetRuneStatus(X.runeTarget) ~= RUNE_STATUS_MISSING then
            bot:Action_PickUpRune(X.runeTarget)
        end
    end
end

return X