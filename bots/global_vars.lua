----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "global_vars", package.seeall )

require( GetScriptDirectory().."/role" )

function GetHeroLevel(bot)
    local respawnTable = {8, 10, 12, 14, 16, 26, 28, 30, 32, 34, 36, 46, 48, 50, 52, 54, 56, 66, 70, 74, 78,  82, 86, 90, 100};
    local nRespawnTime = bot:GetRespawnTime() +1; -- It gives 1 second lower values.
	
    for k,v in pairs(respawnTable) do
        if v == nRespawnTime then
			return k;
        end
    end
	return 1;
end

function GetTimeDelta(prevTime)
	local delta = RealTime() - prevTime;
	return delta;
end

function TimePassed(prevTime, amount)
	if ( GetTimeDelta(prevTime) > amount ) then
		return true, RealTime();
	else
		return false, RealTime();
	end
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