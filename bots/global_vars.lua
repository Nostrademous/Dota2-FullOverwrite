----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "global_vars", package.seeall )

require( GetScriptDirectory().."/role" )

purchase_index = {
	[TEAM_RADIANT] = {
		[role.ROLE_HARDCARRY] = 1,
		[role.ROLE_MID] = 1,
		[role.ROLE_OFFLANE] = 1,
		[role.ROLE_SEMISUPPORT] = 1,
		[role.ROLE_HARDSUPPORT] = 1
	},
	[TEAM_DIRE] = {
		[role.ROLE_HARDCARRY] = 1,
		[role.ROLE_MID] = 1,
		[role.ROLE_OFFLANE] = 1,
		[role.ROLE_SEMISUPPORT] = 1,
		[role.ROLE_HARDSUPPORT] = 1
	}
};

----------------------------------------------------------------------------------------------------

for k,v in pairs( global_vars ) do	_G._savedEnv[k] = v end