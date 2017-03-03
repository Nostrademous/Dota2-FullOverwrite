-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
local utils = require( GetScriptDirectory().."/utility" )
local mods  = require( GetScriptDirectory().."/modifiers" )

----------
X.me            = nil

function X:GetName()
    return "evasion"
end

function X:OnStart(myBot)
    X.me = myBot
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

return X