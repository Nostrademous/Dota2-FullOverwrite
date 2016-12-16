----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "global_vars", package.seeall )

require( GetScriptDirectory().."/role" )

respawn_table = {
	[1] = 7,
	[2] = 9,
	[3] = 11,
	[4] = 13,
	[5] = 15,
	[6] = 25,
	[7] = 27,
	[8] = 29,
	[9] = 31,
	[10]= 33,
	[11]= 35,
	[12]= 45,
	[13]= 47,
	[14]= 49,
	[15]= 51,
	[16]= 53,
	[17]= 55,
	[18]= 65,
	[19]= 69,
	[20]= 73,
	[21]= 77,
	[22]= 81,
	[23]= 85,
	[24]= 89,
	[25]= 99
};

local function contains(table, value)
	for i=1,#table do
		if table[i] == value then
			return i;
		end
	end
	print( "LEVEL CALCULATION BUG!!! VALUE PASSED: " .. value );
	return 0;
end

function GetCurrentLevel(bot)
	--FIXME: will not work correctly for bots that took SpawnReduction Talents
	--print( "RST: ", bot:GetRespawnTime() );
	return contains( respawn_table, bot:GetRespawnTime() );
end	

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