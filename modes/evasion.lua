-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
local utils = require( GetScriptDirectory().."/utility" )
local mods  = require( GetScriptDirectory().."/modifiers" )

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "evasion"
end

function X:OnStart(myBot)
end

function X:OnEnd()
end

function X:Think(bot)
    if mods.IsRuptured(bot) then
        local tp = utils.IsItemAvailable("item_tpscroll")
        if tp then
            bot:Action_UseAbilityOnLocation( tp, utils.Fountain( GetTeam() ) )
        end
    end
end

function X:Desire(bot)
end

return X