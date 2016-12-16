_G._savedEnv = getfenv()
module( "mode_ward_generic", package.seeall )

function GetDesire()
	--FIXME: this disable all desire to ward for now until we implement
	--       smart logic for it
	return BOT_MODE_DESIRE_NONE;

end

for k,v in pairs( mode_ward_generic ) do	_G._savedEnv[k] = v end