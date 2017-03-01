
-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "runes", package.seeall )

----------
local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

----------
local me            = nil
local runeLoc       = nil
local runeTarget    = nil

function OnStart(myBot)
    me = myBot
    runeLoc = self:getHeroVar("RuneLoc")
    runeTarget = self:getHeroVar("RuneTarget")
end

function OnEnd()
    me:setHeroVar("RuneTarget", nil)
    me:setHeroVar("RuneLoc", nil)
    think.UpdatePlayerAssignment(bot, "GetRune", nil)
end

function Think(bot)
    assert(runeLoc ~= nil, "[runes.lua] Think() - runeLoc is 'false'")

    if utils.IsBusy(bot) then return end

    local dist = utils.GetDistance(bot:GetLocation(), runeLoc)
    if dist > 500 then
        gHeroVar.HeroMoveToLocation(bot, runeLoc)
    elseif GetRuneStatus(runeTarget) ~= RUNE_STATUS_MISSING then
        bot:Action_PickUpRune(runeTarget)
    end
end

----------
for k,v in pairs( runes ) do _G._savedEnv[k] = v end
