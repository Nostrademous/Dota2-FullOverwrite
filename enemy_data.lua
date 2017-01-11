-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
---  
---  
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

X = {}

-- GLOBAL ENEMY INFORMATION ARRAY
X.Enemies = {}
X.Enemies[1] = { obj = nil, last_seen = -1000.0 }
X.Enemies[2] = { obj = nil, last_seen = -1000.0 }
X.Enemies[3] = { obj = nil, last_seen = -1000.0 }
X.Enemies[4] = { obj = nil, last_seen = -1000.0 }
X.Enemies[5] = { obj = nil, last_seen = -1000.0 }

X.Missing = {}

X.Lock = false;
X.MissingThreshold = 10.0;

-------------------------------------------------------------------------------
-- FUNCTIONS - implement rudimentary atomic operation insurance
-------------------------------------------------------------------------------
local function EnemyEntryValidAndAlive(entry)
	return entry.obj ~= nil and entry.last_seen ~= -1000.0 and entry.obj:GetHealth() ~= -1
end

local function UpdateEnemiesMissing()
	
	X.Missing = {}; -- clear it first
	
	for p = 1, 5, 1 do
		local entry = X.Enemies[p]
		if EnemyEntryValidAndAlive(entry) then
			local tDelta = RealTime() - entry.last_seen;
			if tDelta > X.MissingThreshold then
				local enemy = entry.obj;
				X.Missing[utils.GetHeroName(enemy)] = tDelta;
			end
		end
	end
end

function X.SetMissingThreshold(value)
	X.MissingThreshold = value;
end

function X.UpdateEnemyInfo()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end;
	
	if ( X.Lock ) then return end;
	
	X.Lock = true;
	
	for p = 1, 5, 1 do
		local tDelta = RealTime() - X.Enemies[p].last_seen;
		-- throttle our update to once every 1 second for each enemy
		if tDelta >= 1.0 then
			local enemy = GetTeamMember(utils.GetOtherTeam(), p);
			if ( enemy ~= nil and enemy:GetHealth() ~= -1 ) then
				X.Enemies[p].obj = enemy;
				X.Enemies[p].last_seen = RealTime();
			end
		end
	end
	
	UpdateEnemiesMissing();
	
	X.Lock = false;
end

function X.PrintEnemyInfo()

	if ( X.Lock ) then return end;
	X.Lock = true;
	
	for p = 1, 5, 1 do
		local entry = X.Enemies[p]
		if EnemyEntryValidAndAlive(entry) then
			local enemy = entry.obj;
			local eLoc = enemy:GetLocation();
			print( "Enemy["..p.."] "..utils.GetHeroName(enemy).." last seen at "..entry.last_seen );
			print( "    Health: "..enemy:GetHealth()..", Mana: "..enemy:GetMana());
			print( "    Location: <"..eLoc[1].." , "..eLoc[2]..">");
		end
	end
	
	X.Lock = false;
end

function X.GetMissingEnemies()
	if ( X.Lock ) then return end;
	X.Lock = true;
	
	local copy = utils.deepcopy(X.Missing);
	
	X.Lock = false;
	
	return copy;
end

return X;