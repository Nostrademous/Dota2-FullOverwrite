----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "role", package.seeall )

local utils = require( GetScriptDirectory().."/utility" )

ROLE_UNKNOWN = 0
ROLE_HARDCARRY = 1
ROLE_MID = 2
ROLE_OFFLANE = 3
ROLE_SEMISUPPORT = 4
ROLE_HARDSUPPORT = 5
ROLE_ROAMER = 6
ROLE_JUNGLER = 7

roles = {
	[1] = ROLE_UNKNOWN,
	[2] = ROLE_UNKNOWN,
	[3] = ROLE_UNKNOWN,
	[4] = ROLE_UNKNOWN,
	[5] = ROLE_UNKNOWN
};

local listHC = {
	"npc_dota_hero_alchemist",
	"npc_dota_hero_antimage",
	"npc_dota_hero_bloodseeker",
	"npc_dota_hero_chaos_knight",
	"npc_dota_hero_clinkz",
	"npc_dota_hero_drow_ranger",
	"npc_dota_hero_dragon_knight",
	"npc_dota_hero_ember_spirit",
	"npc_dota_hero_faceless_void",
	"npc_dota_hero_gyrocopter",
	"npc_dota_hero_huskar",
	"npc_dota_hero_juggernaut",
	"npc_dota_hero_sniper",
};
	
local listMID = {
	"npc_dota_hero_alchemist",
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_brewmaster",
	"npc_dota_hero_death_prophet",
	"npc_dota_hero_dragon_knight",
	"npc_dota_hero_ember_spirit",
	"npc_dota_hero_faceless_void",
	"npc_dota_hero_huskar",
	"npc_dota_hero_invoker",
	"npc_dota_hero_juggernaut",
	"npc_dota_hero_lina",
	"npc_dota_hero_nevermore",
	"npc_dota_hero_sniper",
	"npc_dota_hero_viper",
	"npc_dota_hero_zuus",
};
	
local listOFF = {
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_axe",
	"npc_dota_hero_batrider",
	"npc_dota_hero_beastmaster",
	"npc_dota_hero_bounty_hunter",
	"npc_dota_hero_brewmaster",
	"npc_dota_hero_bristleback",
	"npc_dota_hero_broodmother",
	"npc_dota_hero_centaur",
	"npc_dota_hero_clinkz",
	"npc_dota_hero_rattletrap",
	"npc_dota_hero_dark_seer",
	"npc_dota_hero_doom_bringer",
	"npc_dota_hero_dragon_knight",
	"npc_dota_hero_elder_titan",
	"npc_dota_hero_enchantress",
	"npc_dota_hero_faceless_void",
	"npc_dota_hero_huskar",
	"npc_dota_hero_spirit_breaker",
	"npc_dota_hero_viper",
};

local listROAMER = {
	"npc_dota_hero_bounty_hunter",
	"npc_dota_hero_mirana",
};

local listJUNGLER = {
	"npc_dota_hero_axe",
	"npc_dota_hero_bloodseeker",
	"npc_dota_hero_chen",
	"npc_dota_hero_doom_bringer",
	"npc_dota_hero_enchantress",
	"npc_dota_hero_enigma",
};
	
local listSEMISUPPORT = {
	"npc_dota_hero_abaddon",
	"npc_dota_hero_ancient_apparition",
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_bane",
	"npc_dota_hero_brewmaster",
	"npc_dota_hero_dazzle",
	"npc_dota_hero_earth_spirit",
	"npc_dota_hero_earthshaker",
	"npc_dota_hero_elder_titan",
	"npc_dota_hero_enigma",
	"npc_dota_hero_jakiro",
	"npc_dota_hero_witch_doctor",
};

local listHARDSUPPORT = {
	"npc_dota_hero_ancient_apparition",
	"npc_dota_hero_crystal_maiden",
	"npc_dota_hero_dazzle",
	"npc_dota_hero_disruptor",
	"npc_dota_hero_earthshaker",
	"npc_dota_hero_wisp",
	"npc_dota_hero_jakiro",
	"npc_dota_hero_lion",
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

local function checkRoleJungler(value)
	for i=1,#listJUNGLER do
		if listJUNGLER[i] == value then
			return true;
		end
	end
	return false;
end

local function checkRoleRoamer(value)
	for i=1,#listROAMER do
		if listROAMER[i] == value then
			return true;
		end
	end
	return false;
end

local rMatrix = { [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {} }

local function findRole(name)
	local tMatrix = { [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {} }
	if checkRoleMid(name) then table.insert(tMatrix[2], name) end
	if checkRoleOff(name) then table.insert(tMatrix[3], name) end
	if checkRoleHardCarry(name) then table.insert(tMatrix[1], name) end
	if checkRoleHardSupport(name) then table.insert(tMatrix[5], name) end
	if checkRoleJungler(name) then table.insert(tMatrix[6], name) end
	if checkRoleRoamer(name) then table.insert(tMatrix[7], name) end
	if checkRoleSemiSupport(name) then table.insert(tMatrix[4], name) end
	return tMatrix
end

local function existsInMatrix(matrix, value)
	for k,v in pairs( matrix ) do
		for k2,v2 in pairs (v) do
			if v2 == value then
				return true
			end
		end
	end
	return false
end

local function countOverlap(matrix)
	return math.max(0, #rMatrix[1]-1) + math.max(0, #rMatrix[2]-1) + math.max(0, #rMatrix[3]-1) + math.max(0, #rMatrix[4]-1) + math.max(0, #rMatrix[5]-1) + math.max(0, #rMatrix[6]-1) + math.max(0, #rMatrix[7]-1)
end

local function everyObjectAssigned(matrix)
	for i = 1, 5, 1 do
		local slot = GetTeamMember( GetTeam(), i )
		if not existsInMatrix(matrix, slot:GetUnitName()) then
			return i
		end
	end
	return 0
end

local function fillRoles(rMatrix)
	obj = everyObjectAssigned(rMatrix)
	best = utils.deepcopy(rMatrix)
	
	if obj ~= 0 then
		local slot = GetTeamMember( GetTeam(), obj )
		validRoles = findRole(slot:GetUnitName())
		for k,v in pairs (validRoles) do
			if #v > 0 then
				new = utils.deepcopy(rMatrix)
				table.insert(new[k], slot:GetUnitName())
				
				new = fillRoles(new)
				if countOverlap(new) < countOverlap(best) then
					best = utils.deepcopy(new)
					if countOverlap(best) == 0 and everyObjectAssigned(best) == 0 then
						break
					end
				end
			end
		end
	end
	
	return best
end

-------------------------------------------------------------------------------

function RolesFilled()
	return not contains(roles, ROLE_UNKNOWN);
end

function SetRoles()
	print( "SetRoles()" );
	rMatrix = fillRoles(rMatrix)

	for k, v in pairs( rMatrix ) do
		print(k)
		for k2, v2 in pairs (v) do
			print("    ", k2, v2)
			for i = 1, 5, 1 do
				local slot = GetTeamMember( GetTeam(), i )
				if v2 == slot:GetUnitName() then
					roles[i] = k
				end
			end
		end
	end
end

function GetRoles()
	--print ( "GetRoles()" );
	if ( not RolesFilled() ) then
		SetRoles()
	end
	
	return roles;
end

function GetLaneAndRole(team, role_indx)
	local r = GetRoles()
	local rl = roles[role_indx]
	
	if rl == ROLE_MID then
		return LANE_MID, rl
	elseif rl == ROLE_OFFLANE then
		if team == TEAM_RADIANT then
			return LANE_TOP, rl
		else
			return LANE_BOT, rl
		end
	else
		if team == TEAM_RADIANT then
			return LANE_BOT, rl
		else
			return LANE_TOP, rl
		end
	end
end

----------------------------------------------------------------------------------------------------

for k,v in pairs( role ) do	_G._savedEnv[k] = v end