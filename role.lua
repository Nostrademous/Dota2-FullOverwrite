-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "role", package.seeall )

require( GetScriptDirectory().."/constants" )
local utils = require( GetScriptDirectory().."/utility" )

local ROLE_UNKNOWN 		= constants.ROLE_UNKNOWN
local ROLE_HARDCARRY 	= constants.ROLE_HARDCARRY
local ROLE_MID 			= constants.ROLE_MID
local ROLE_OFFLANE 		= constants.ROLE_OFFLANE
local ROLE_SEMISUPPORT 	= constants.ROLE_SEMISUPPORT
local ROLE_HARDSUPPORT 	= constants.ROLE_HARDSUPPORT
local ROLE_ROAMER 		= constants.ROLE_ROAMER
local ROLE_JUNGLER 		= constants.ROLE_JUNGLER

roles = {
	[1] = ROLE_UNKNOWN,
	[2] = ROLE_UNKNOWN,
	[3] = ROLE_UNKNOWN,
	[4] = ROLE_UNKNOWN,
	[5] = ROLE_UNKNOWN
};

local listHC = {
--comments by "ByBurton":	I define Hardcarries as heroes that need a lot of money - position 1; usually in safelane and with 1 or 2 supports that help him.
	"npc_dota_hero_alchemist",
	"npc_dota_hero_antimage",
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_bloodseeker",
	"npc_dota_hero_chaos_knight",
	"npc_dota_hero_clinkz",
	"npc_dota_hero_drow_ranger",
	"npc_dota_hero_ember_spirit",
	"npc_dota_hero_faceless_void",
	"npc_dota_hero_gyrocopter",
	"npc_dota_hero_huskar",
	"npc_dota_hero_juggernaut",
	"npc_dota_hero_lone_druid",
	"npc_dota_hero_luna",
	"npc_dota_hero_lycan",
	"npc_dota_hero_medusa",
	"npc_dota_hero_meepo",
	"npc_dota_hero_monkey_king",
	"npc_dota_hero_morphling",
	"npc_dota_hero_naga_siren",
	"npc_dota_hero_necrolyte",
	"npc_dota_hero_phantom_assassin",
	"npc_dota_hero_phantom_lancer",
	--"npc_dota_hero_queen_of_pain",
	--"npc_dota_hero_skeleton_king",
	--"npc_dota_hero_silencer",
	"npc_dota_hero_slark",
	"npc_dota_hero_sniper",
	"npc_dota_hero_spectre",
	"npc_dota_hero_sven",
	"npc_dota_hero_terrorblade",
	"npc_dota_hero_tiny",
	"npc_dota_hero_viper",
	"npc_dota_hero_weaver",
	--"npc_dota_hero_windrunner",
};

local listMID = {
--comments by "ByBurton":	I define Mid as Semicarries. Heroes that need exp and some gold early on, that can easily win lanes 1 vs 1 through skill spamming or harrassing - position 2; always in mid.
--Have skills that scale bad in early and good into lategame - mostly physical dmg.
	"npc_dota_hero_abyssal_underlord",
	"npc_dota_hero_alchemist",
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_brewmaster",
	"npc_dota_hero_batrider",
	"npc_dota_hero_bloodseeker",
	"npc_dota_hero_broodmother",
	"npc_dota_hero_death_prophet",
	"npc_dota_hero_dragon_knight",
	"npc_dota_hero_drow_ranger",
	"npc_dota_hero_ember_spirit",
	"npc_dota_hero_faceless_void",
	"npc_dota_hero_huskar",
	"npc_dota_hero_invoker",
	"npc_dota_hero_juggernaut",
	"npc_dota_hero_leshrac",
	"npc_dota_hero_lina",
	--"npc_dota_hero_lion",
	"npc_dota_hero_magnataur",
	"npc_dota_hero_medusa",
	"npc_dota_hero_meepo",
	"npc_dota_hero_mirana",
	--"npc_dota_hero_monkey_king",
	"npc_dota_hero_necrolyte",
	"npc_dota_hero_nevermore",
	--"npc_dota_hero_night_stalker",
	"npc_dota_hero_obsidian_destroyer",
	"npc_dota_hero_phoenix",
	"npc_dota_hero_puck",
	"npc_dota_hero_pudge",
	"npc_dota_hero_pugna",
	"npc_dota_hero_queen_of_pain",
	"npc_dota_hero_rattletrap",
	"npc_dota_hero_razor",
	"npc_dota_hero_shadow_fiend",
	"npc_dota_hero_silencer",
	--"npc_dota_hero_skywrath_mage",
	"npc_dota_hero_sniper",
	"npc_dota_hero_storm_spirit",
	"npc_dota_hero_templar_assassin",
	"npc_dota_hero_troll_warlord",
	"npc_dota_hero_tinker",
	"npc_dota_hero_tiny",
	"npc_dota_hero_ursa",
	"npc_dota_hero_viper",
	--"npc_dota_hero_warlock",	--He can actually mid, spam the shadow word on the enemy; has good stats, laning phase can be pretty easy. (early bottle).
	"npc_dota_hero_windrunner",
	"npc_dota_hero_zuus",
};

local listOFF = {
--comments by "ByBurton":	I define Offlaner as Semicarries too, but a bit less gold focused. They need mostly exp early on, and they play defensiv / use defensive skills to survive their lane 1 vs 2-3 - position 3;
--always solo or with another support; in offlane aka hardlane. Have abilities that scale good in midgame.
	"npc_dota_hero_abaddon",
	"npc_dota_hero_abyssal_underlord",
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_axe",
	"npc_dota_hero_batrider",
	"npc_dota_hero_beastmaster",
	--"npc_dota_hero_bloodseeker",
	"npc_dota_hero_bounty_hunter",
	"npc_dota_hero_brewmaster",
	"npc_dota_hero_bristleback",
	"npc_dota_hero_broodmother",
	"npc_dota_hero_clinkz",
	"npc_dota_hero_centaur",
	"npc_dota_hero_chen",
	"npc_dota_hero_dark_seer",
	"npc_dota_hero_doom_bringer",
	"npc_dota_hero_dragon_knight",
	"npc_dota_hero_earth_spirit",
	"npc_dota_hero_earthshaker",
	"npc_dota_hero_elder_titan",
	"npc_dota_hero_enchantress",
	"npc_dota_hero_faceless_void",
	"npc_dota_hero_furion",
	"npc_dota_hero_huskar",
	"npc_dota_hero_kunkka",
	"npc_dota_hero_legion_commander",
	"npc_dota_hero_lifestealer",
	"npc_dota_hero_lone_druid",
	"npc_dota_hero_lycan",
	"npc_dota_hero_magnataur",
	"npc_dota_hero_meepo",
	"npc_dota_hero_mirana",
	--"npc_dota_hero_monkey_king",
	"npc_dota_hero_morphling",
	"npc_dota_hero_necrolyte",
	"npc_dota_hero_night_stalker",
	"npc_dota_hero_nyx_assassin",
	"npc_dota_hero_ogre_magi",
	"npc_dota_hero_phoenix",
	"npc_dota_hero_puck",
	"npc_dota_hero_pudge",
	"npc_dota_hero_rattletrap",
	"npc_dota_hero_riki",
	"npc_dota_hero_sandking",
	"npc_dota_hero_skeleton_king",
	--"npc_dota_hero_silencer",
	"npc_dota_hero_slardar",
	"npc_dota_hero_spirit_breaker",
	"npc_dota_hero_sven",
	"npc_dota_hero_techies", --TECHIES EXIST! ACCEPT IT!
	"npc_dota_hero_tidehunter",
	"npc_dota_hero_tiny",
	"npc_dota_hero_shredder",
	"npc_dota_hero_troll_warlord",
	"npc_dota_hero_tusk",
	"npc_dota_hero_undying",
	"npc_dota_hero_ursa",
	"npc_dota_hero_viper",
	"npc_dota_hero_weaver",
	--"npc_dota_hero_windrunner",
};

local listROAMER = {
--comments by "ByBurton":	I define roaming heroes as heroes who need no or very few gold and levels, and gank lanes to help the team. gets little gold / exp by this.
--Typically invisible heroes or heroes with a skill to surprise their targets / roam around the map fast - Position 3; Starts usually in the offlane? for some levels to start roaming
	"npc_dota_hero_bounty_hunter",
	--"npc_dota_hero_bloodseeker",
	"npc_dota_hero_clinkz",
	"npc_dota_hero_mirana",
	"npc_dota_hero_nyx_assassin",
	"npc_dota_hero_riki",
	"npc_dota_hero_spirit_breaker",
};

local listJUNGLER = {
--comments by "ByBurton":	I define junglers as heroes, who sacrifice some exp for steady gold income through clearing the jungle early on. They have skills that allow them to do so.
--Grants the rest of the team more exp, because one hero less on the lane. Can help the safelane by ganking. Requires starting gold to become scary for enemy heroes - position 2 or 3; in jungle.
	"npc_dota_hero_axe",
	--"npc_dota_hero_beastmaster",
	"npc_dota_hero_bloodseeker",
	"npc_dota_hero_chen",
	"npc_dota_hero_doom_bringer",
	"npc_dota_hero_enchantress",
	"npc_dota_hero_enigma",
	"npc_dota_hero_furion",
	"npc_dota_hero_legion_commander",
	"npc_dota_hero_lifestealer",
	--"npc_dota_hero_lycan",
};

local listSEMISUPPORT = {
--comments by "ByBurton":	I define semi supports as supports who need a little money. they usually do not buy the wards and smokes. Usually have supporting abilities. They help in ganks, and buy other utility items. Require some more
--gold / exp than full supports - Position 4 - usually helping the offlaner or in a trilane with the safelane carry.
	"npc_dota_hero_abaddon",
	--"npc_dota_hero_ancient_apparition",
	--"npc_dota_hero_arc_warden",
	"npc_dota_hero_bane",
	"npc_dota_hero_brewmaster",
	"npc_dota_hero_chen",
	--"npc_dota_hero_crystal_maiden",
	"npc_dota_hero_dazzle",
	--"npc_dota_hero_disruptor",
	"npc_dota_hero_earth_spirit",
	"npc_dota_hero_earthshaker",
	"npc_dota_hero_elder_titan",
	"npc_dota_hero_enigma",
	"npc_dota_hero_jakiro",
	"npc_dota_hero_leshrac",			--not sure here
	"npc_dota_hero_lich",
	--"npc_dota_hero_lina",	-- not really a good support
	"npc_dota_hero_lion",
	"npc_dota_hero_ogre_magi",
	"npc_dota_hero_omniknight",
	"npc_dota_hero_phoenix",
	"npc_dota_hero_pudge",
	"npc_dota_hero_pugna",
	"npc_dota_hero_sandking",
	"npc_dota_hero_silencer",
	"npc_dota_hero_skywrath_mage",
	"npc_dota_hero_slardar",
	"npc_dota_hero_tidehunter",
	"npc_dota_hero_tiny",
	"npc_dota_hero_treant_protector",
	"npc_dota_hero_tusk",
	"npc_dota_hero_undying",
	"npc_dota_hero_vengefulspirit",
	--"npc_dota_hero_venomancer",
	"npc_dota_hero_warlock",
	"npc_dota_hero_windrunner",
	--"npc_dota_hero_winter_wyvern",
	"npc_dota_hero_witch_doctor",
	--"npc_dota_hero_zuus",
};

local listHARDSUPPORT = {
--comments by "ByBurton":	I define full supports or hard supports as heroes that hardly need money to be helpful to their carry. Usually possess helpful abilities, stuns, heals. Harass the enemy offlaner out
--of the lane / exp range. No money, little exp - Position 5; usually in the safelane protecting its carry. stacking and pulling.
	"npc_dota_hero_abaddon",
	"npc_dota_hero_ancient_apparition",
	"npc_dota_hero_bane",
	"npc_dota_hero_crystal_maiden",
	"npc_dota_hero_dazzle",
	"npc_dota_hero_disruptor",
	"npc_dota_hero_earthshaker",
	"npc_dota_hero_jakiro",
	"npc_dota_hero_keeper_of_the_light",
	"npc_dota_hero_lich",
	"npc_dota_hero_lion",
	"npc_dota_hero_omniknight",
	"npc_dota_hero_oracle",
	"npc_dota_hero_rubick",
	"npc_dota_hero_sandking",
	"npc_dota_hero_shadow_demon",
	"npc_dota_hero_shadow_shaman",
	"npc_dota_hero_skywrath_mage",
	"npc_dota_hero_tidehunter",
	"npc_dota_hero_treant_protector",
	"npc_dota_hero_undying",
	"npc_dota_hero_visage",
	"npc_dota_hero_vengefulspirit",
	"npc_dota_hero_venomancer",
	"npc_dota_hero_winter_wyvern",
	"npc_dota_hero_wisp",
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

local function findRole(name)
	local tMatrix = { [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {} }
	if checkRoleMid(name) then table.insert(tMatrix[ROLE_MID], name) end
	if checkRoleOff(name) then table.insert(tMatrix[ROLE_OFFLANE], name) end
	if checkRoleHardCarry(name) then table.insert(tMatrix[ROLE_HARDCARRY], name) end
	if checkRoleJungler(name) then table.insert(tMatrix[ROLE_JUNGLER], name) end
	if checkRoleRoamer(name) then table.insert(tMatrix[ROLE_ROAMER], name) end
	if checkRoleHardSupport(name) then table.insert(tMatrix[ROLE_HARDSUPPORT], name) end
	if checkRoleSemiSupport(name) then table.insert(tMatrix[ROLE_SEMISUPPORT], name) end
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
	return math.max(0, #matrix[1]-1) + math.max(0, #matrix[2]-1) + math.max(0, #matrix[3]-1) + math.max(0, #matrix[4]-1) + math.max(0, #matrix[5]-1) + math.max(0, #matrix[6]-1) + math.max(0, #matrix[7]-1)
end

local function everyObjectAssigned(matrix)
	for i = 1, 5, 1 do
		local slot = GetTeamMember( i )
		if not existsInMatrix(matrix, slot:GetUnitName()) then
			return i
		end
	end
	return 0
end

local rMatrix = { [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {} }
local best = nil
local function fillRoles(rMatrix)
	obj = everyObjectAssigned(rMatrix)

	if obj ~= 0 then
		local slot = GetTeamMember( obj )
		validRoles = findRole(slot:GetUnitName())
		for k,v in pairs (validRoles) do
			if #v > 0 then
				new = utils.deepcopy(rMatrix)
				table.insert(new[k], slot:GetUnitName())

				new = fillRoles(new)
				if everyObjectAssigned(new) == 0 and best == nil then
					best = utils.deepcopy(new)
				end

				if everyObjectAssigned(new) == 0 and everyObjectAssigned(best) == 0 and countOverlap(new) < countOverlap(best) then
					best = utils.deepcopy(new)
					if countOverlap(best) == 0 and everyObjectAssigned(best) == 0 then
						break
					end
				end
			end
		end

	end
	return rMatrix
end

-------------------------------------------------------------------------------

function RolesFilled()
	return not contains(roles, ROLE_UNKNOWN);
end

function SetRoles()
	print( "SetRoles()" );
	rMatrix = fillRoles(rMatrix)

	for k, v in pairs( best ) do
		for k2, v2 in pairs (v) do
			for i = 1, 5, 1 do
				local slot = GetTeamMember( i )
				if v2 == slot:GetUnitName() then
					roles[i] = k
                    print("Role: "..k.." - "..v2)
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

	return roles
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
	elseif rl == ROLE_JUNGLER then
		return LANE_NONE, rl
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
