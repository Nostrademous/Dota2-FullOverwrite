----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "role", package.seeall )

roles = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
		[4] = 0,
		[5] = 0,
		[6] = 0,
		[7] = 0,
		[8] = 0,
		[9] = 0,
		[10] = 0
	};

----------------------------------------------------------------------------------------------------

local function contains(table, value)
	for i=1,#table do
		if table[i] == value then
			return true;
		end
	end
	return false;
end

function SetRoles()

	print( "SetRoles()" );
	
	print( "Setting Radiant Roles..." );
	local radiant = {}
	local slot1 = GetTeamMember( TEAM_RADIANT, 1 )
	
	roles[1] = 1;
	roles[2] = 3;
	roles[3] = 4;
	roles[4] = 2;
	roles[5] = 5;
	
	print( "Setting Dire Roles..." );
	roles[6] = 3;
	roles[7] = 4;
	roles[8] = 1;
	roles[9] = 5;
	roles[10]= 2;
	
end


function GetRoles()

	--print ( "GetRoles()" );
	if contains(roles, 0) then
		SetRoles()
	end
	
	return roles;
end
----------------------------------------------------------------------------------------------------

for k,v in pairs( role ) do	_G._savedEnv[k] = v end