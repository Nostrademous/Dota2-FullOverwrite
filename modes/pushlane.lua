-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
X.me            = nil

function X:GetName()
    return "pushlane"
end

function X:OnStart(myBot)
    X.me = myBot
end

function X:OnEnd()
end

function X:Think(bot)
end

return X