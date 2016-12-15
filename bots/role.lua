----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "role", package.seeall )

ROLE_UNKNOWN = 0
ROLE_HARDCARRY = 1
ROLE_MID = 2
ROLE_OFFLANE = 3
ROLE_SEMISUPPORT = 4
ROLE_HARDSUPPORT = 5

roles = {
		[1] = ROLE_UNKNOWN,
		[2] = ROLE_UNKNOWN,
		[3] = ROLE_UNKNOWN,
		[4] = ROLE_UNKNOWN,
		[5] = ROLE_UNKNOWN,
		[6] = ROLE_UNKNOWN,
		[7] = ROLE_UNKNOWN,
		[8] = ROLE_UNKNOWN,
		[9] = ROLE_UNKNOWN,
		[10] = ROLE_UNKNOWN
	};

local listHC = {
		"npc_dota_hero_antimage",
		"npc_dota_hero_juggernaut",
	};
	
local listMID = {
		"npc_dota_hero_nevermore",
		"npc_dota_hero_lina",
	};
	
local listOFF = {
		"npc_dota_hero_bristleback",
		"npc_dota_hero_drow_ranger",
		"npc_dota_hero_rattletrap",
		"npc_dota_hero_faceless_void",
	};
	
local listSEMISUPPORT = {
		"npc_dota_hero_bane",
		"npc_dota_hero_witch_doctor",
	};

local listHARDSUPPORT = {
		"npc_dota_hero_crystal_maiden",
		"npc_dota_hero_lion",
	};
	
----------------------------------------------------------------------------------------------------

local function contains(table, value)
	for i=1,#table do
		if table[i] == value then
			return i;
		end
	end
	return 0;
end

local function checkRoleHardCarry(value)
	for i=1,#listHC do
		if listHC[i] == value then
			return true;
		end
	end
	return false;
end

local function checkRoleMid(value)
	for i=1,#listMID do
		if listMID[i] == value then
			return true;
		end
	end
	return false;
end

local function checkRoleOff(value)
	for i=1,#listOFF do
		if listOFF[i] == value then
			return true;
		end
	end
	return false;
end

local function checkRoleSemiSupport(value)
	for i=1,#listSEMISUPPORT do
		if listSEMISUPPORT[i] == value then
			return true;
		end
	end
	return false;
end

local function checkRoleHardSupport(value)
	for i=1,#listHARDSUPPORT do
		if listHARDSUPPORT[i] == value then
			return true;
		end
	end
	return false;
end

local function findRole(value)
	if checkRoleHardCarry(value) then
		return ROLE_HARDCARRY;
	elseif checkRoleMid(value) then
		return ROLE_MID;
	elseif checkRoleOff(value) then
		return ROLE_OFFLANE;
	elseif checkRoleSemiSupport(value) then
		return ROLE_SEMISUPPORT;
	elseif checkRoleHardSupport(value) then
		return ROLE_HARDSUPPORT;
	else
		return ROLE_UNKNOWN;
	end
end

-------------------------------------------------------------------------------

function SetRoles()

	print( "SetRoles()" );
	
	print( "Setting Radiant Roles..." );
	
	for i=1,5 do
		if roles[i] == ROLE_UNKNOWN then
			local slot = GetTeamMember( TEAM_RADIANT, i )
			if slot == nil then
				return
			end
			local name = slot:GetUnitName();
			roles[i] = findRole( name );
			print( "[RADIANT] Role for "..name.." is", roles[i] )
		end
	end

	print( "Setting Dire Roles..." );
	for i=1,5 do
		if roles[i+5] == ROLE_UNKNOWN then
			local slot = GetTeamMember( TEAM_DIRE, i )
			if slot == nil then
				return
			end
			local name = slot:GetUnitName();
			roles[i+5] = findRole( name );
			print( "[DIRE] Role for "..name.." is", roles[i+5] )
		end
	end
end


function GetRoles()

	--print ( "GetRoles()" );
	local unknown_idx = contains(roles, ROLE_UNKNOWN);
	if ( unknown_idx > 0 and unknown_idx < 11 ) then
		SetRoles()
	end
	
	return roles;
end
----------------------------------------------------------------------------------------------------

for k,v in pairs( role ) do	_G._savedEnv[k] = v end