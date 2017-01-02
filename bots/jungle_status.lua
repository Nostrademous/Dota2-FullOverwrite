_G._savedEnv = getfenv()
module( "jungle_status", package.seeall )

local utils = require(GetScriptDirectory() .. "/util")
local isJungleFresh = true
local jungle = utils.deepcopy(utils.tableNeutralCamps)
----------------------------------------------------------------------------------------------------

--reset the jungle camps
function NewJungle ()
	if not isJungleFresh then
		jungle = utils.deepcopy(utils.tableNeutralCamps)
		isJungleFresh = true
	end
end

----------------------------------------------------------------------------------------------------

--get currently known alive / unknown camps
function GetJungle ( nTeam )
	if jungle[nTeam] == nil or #jungle[nTeam] == 0 then
		return nil
	end
	return jungle[nTeam]
end

----------------------------------------------------------------------------------------------------

--announce a camp dead
function JungleCampClear ( nTeam, vector )
  	for i=#jungle[nTeam],1,-1 do

	    if jungle[nTeam][i][VECTOR] == vector then
	        table.remove(jungle[nTeam], i)
	    end
	end
  isJungleFresh = false
end

----------------------------------------------------------------------------------------------------

for k,v in pairs( jungle_status ) do _G._savedEnv[k] = v end