-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

local ED = {}

-- GLOBAL ENEMY INFORMATION ARRAY
ED.Enemies = {}
ED.Enemies[1] = { obj = nil, last_seen = -1000.0 }
ED.Enemies[2] = { obj = nil, last_seen = -1000.0 }
ED.Enemies[3] = { obj = nil, last_seen = -1000.0 }
ED.Enemies[4] = { obj = nil, last_seen = -1000.0 }
ED.Enemies[5] = { obj = nil, last_seen = -1000.0 }

ED.Lock = false

-------------------------------------------------------------------------------
-- FUNCTIONS - implement rudimentary atomic operation insurance
-------------------------------------------------------------------------------
local function EnemyEntryValidAndAlive(entry)
	return entry.obj ~= nil and entry.last_seen ~= -1000.0 and entry.obj:GetHealth() ~= -1
end

function ED.UpdateEnemyInfo()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
	
	if ( ED.Lock ) then return end
	
	ED.Lock = true
	
	for p = 1, 5, 1 do
		local tDelta = RealTime() - ED.Enemies[p].last_seen
		-- throttle our update to once every 1 second for each enemy
		if tDelta >= 1.0 then
			local enemy = GetTeamMember(utils.GetOtherTeam(), p)
			if ( enemy ~= nil and enemy:GetHealth() ~= -1 ) then
				ED.Enemies[p].obj = enemy
				ED.Enemies[p].last_seen = RealTime()
			end
		end
	end
	
	ED.Lock = false
end

function ED.PrintEnemyInfo()

	if ( ED.Lock ) then return end
	ED.Lock = true
	
	for p = 1, 5, 1 do
		local entry = ED.Enemies[p]
		if EnemyEntryValidAndAlive(entry) then
			local enemy = entry.obj
			local eLoc = enemy:GetLocation()
			print( "Enemy["..p.."] "..utils.GetHeroName(enemy).." last seen at "..entry.last_seen )
			print( "    Health: "..enemy:GetHealth()..", Mana: "..enemy:GetMana())
			print( "    Location: <"..eLoc[1].." , "..eLoc[2]..">")
		end
	end
	
	ED.Lock = false;
end

return ED