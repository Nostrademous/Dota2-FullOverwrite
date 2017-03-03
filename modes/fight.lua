-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
X.me            = nil
X.Attacking     = false

function X:GetName()
    return "fight"
end

function X:OnStart(myBot)
    X.me = myBot
    X.Attacking = false
end

function X:OnEnd()
end

function X:Think(bot)
    
end

return X