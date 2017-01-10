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
};

local listROAMER = {
	"npc_dota_hero_bounty_hunter",
	"npc_dota_hero_mirana"
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

local function findRole(value)
	if checkRoleMid(value) and not contains(roles, ROLE_MID) then
		return ROLE_MID;
	elseif checkRoleOff(value) and not contains(roles, ROLE_OFFLANE) then
		return ROLE_OFFLANE;
	elseif checkRoleHardSupport(value) and not contains(roles, ROLE_HARDSUPPORT) then
		return ROLE_HARDSUPPORT;
	elseif checkRoleHardCarry(value) then
		return ROLE_HARDCARRY;
	else
		return ROLE_SEMISUPPORT;
	end
end

-------------------------------------------------------------------------------

function RolesFilled()
	return not contains(roles, ROLE_UNKNOWN);
end

function SetRoles()
	print( "SetRoles()" );
	
	local team = GetTeam()
	
	for i=1,5 do
		if roles[i] == ROLE_UNKNOWN then
			local slot = GetTeamMember( team, i )
			if slot == nil then
				return
			end
			local name = slot:GetUnitName();
			roles[i] = findRole( name );
			print( "Role for "..utils.GetHeroName(slot).." is", roles[i] )
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