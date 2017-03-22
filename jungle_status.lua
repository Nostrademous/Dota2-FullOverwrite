--------------------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by ironmano
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
--------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "jungle_status", package.seeall )

require(GetScriptDirectory() .. "/constants")
local utils = require(GetScriptDirectory() .. "/utility")
local isJungleFresh = false
local jungle = {}
local next_refresh = 30

----------------------------------------------------------------------------------------------------

function checkSpawnTimer()
    if DotaTime() >= next_refresh then
        print("Refresh jungle")
        NewJungle()
        next_refresh = utils.NextNeutralSpawn()
    end
end

--reset the jungle camps
function NewJungle ()
    if not isJungleFresh then
        jungle = utils.deepcopy(utils.tableNeutralCamps)
        isJungleFresh = true
        GetBot().jungleReloaded = true
    end
end

----------------------------------------------------------------------------------------------------

--get currently known alive / unknown camps
function GetJungle ( nTeam )
    if jungle[nTeam] == nil or #jungle[nTeam] == 0 then
        return {}
    end
    return jungle[nTeam]
end

----------------------------------------------------------------------------------------------------

--announce a camp dead
function JungleCampClear ( nTeam, vector )
    for i=#jungle[nTeam],1,-1 do
        if jungle[nTeam][i][constants.VECTOR] == vector then
            table.remove(jungle[nTeam], i)
        end
    end
    isJungleFresh = false
end

----------------------------------------------------------------------------------------------------

for k,v in pairs( jungle_status ) do _G._savedEnv[k] = v end
