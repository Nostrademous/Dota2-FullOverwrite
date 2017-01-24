-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

local EnemyData = {}

-- GLOBAL ENEMY INFORMATION ARRAY

EnemyData.Lock = false

-------------------------------------------------------------------------------
-- FUNCTIONS - implement rudimentary atomic operation insurance
-------------------------------------------------------------------------------
local function EnemyEntryValidAndAlive(entry)
	return entry.obj ~= nil and entry.last_seen ~= -1000.0 and entry.obj:GetHealth() ~= -1
end

function EnemyData.UpdateEnemyInfo()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
	
	if ( EnemyData.Lock ) then return end
	
	EnemyData.Lock = true
	
	local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES)
	
	if #enemies == 0 then return end
	
	for _, enemy in pairs(enemies) do
		local pid = enemy:GetPlayerID()
		local name = utils.GetHeroName(enemy)
		
		if EnemyData[pid] == nil then
			EnemyData[pid] = { Name = name, Time = -100, Obj = nil, Level = 1, Health = -1, Mana = -1, Location = nil, Items = {}, PhysDmg = {}, MagicDmg = {}, PureDmg = {} }
		end

		local tDelta = RealTime() - EnemyData[pid].Time
		-- throttle our update to once every 5 second for each enemy
		if tDelta >= 5.0 and enemy:GetHealth() ~= -1 then
			EnemyData[pid].Time = RealTime()
			EnemyData[pid].Obj = enemy
			EnemyData[pid].Level = enemy:GetLevel()
			EnemyData[pid].Health = enemy:GetHealth()
			EnemyData[pid].MaxHealth = enemy:GetMaxHealth()
			EnemyData[pid].Mana = enemy:GetMana()
			EnemyData[pid].MaxMana = enemy:GetMaxMana()
			EnemyData[pid].Location = enemy:GetLocation()
			for i = 0, 5, 1 do
				local item = enemy:GetItemInSlot(i)
				if item ~= nil then
					EnemyData[pid].Items[i] = item:GetName()
				end
			end
			
			EnemyData[pid].SlowDur = enemy:GetSlowDuration(false) -- FIXME: does this count abilities only, or Items too?
			EnemyData[pid].StunDur = enemy:GetStunDuration(false) -- FIXME: does this count abilities only, or Items too?
			EnemyData[pid].HasSilence = enemy:HasSilence(false) -- FIXME: does this count abilities only, or Items too?
			EnemyData[pid].HasTruestrike = enemy:IsUnableToMiss()
			
			local allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
			for _, ally in pairs(allies) do
				EnemyData[pid].PhysDmg[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 5.0, DAMAGE_TYPE_PHYSICAL)
				EnemyData[pid].MagicDmg[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 5.0, DAMAGE_TYPE_MAGICAL)
				EnemyData[pid].PureDmg[ally:GetPlayerID()] = enemy:GetEstimatedDamageToTarget(true, ally, 5.0, DAMAGE_TYPE_PURE)
			end
		end
	end

	EnemyData.Lock = false
end

function EnemyData.GetEnemyDmgs(ePID)
	if ( EnemyData.Lock ) then return 0 end
	EnemyData.Lock = true

	local physDmg = 0
	local magicDmg = 0
	local pureDmg = 0
	for k, v in pairs(EnemyData) do
		if type(k) == "number"  and k == ePID then
			physDmg = v.PhysDmg[GetBot():GetPlayerID()]
			magicDmg = v.MagicDmg[GetBot():GetPlayerID()]
			pureDmg = v.PureDmg[GetBot():GetPlayerID()]
			break
		end
	end

	EnemyData.Lock = false
	
	return physDmg, magicDmg, pureDmg
end

function EnemyData.GetEnemySlowDuration(ePID)
	if ( EnemyData.Lock ) then return 0 end
	EnemyData.Lock = true

	local duration = 0
	for k, v in pairs(EnemyData) do
		if type(k) == "number"  and k == ePID then
			duration = v.SlowDur
			break
		end
	end

	EnemyData.Lock = false
	
	return duration
end

function EnemyData.GetEnemyStunDuration(ePID)
	if ( EnemyData.Lock ) then return 0 end
	EnemyData.Lock = true

	local duration = 0
	for k, v in pairs(EnemyData) do
		if type(k) == "number"  and k == ePID then
			duration = v.StunDur
			break
		end
	end

	EnemyData.Lock = false
	
	return duration
end

function EnemyData.GetEnemyTeamSlowDuration()
	if ( EnemyData.Lock ) then return 0 end
	EnemyData.Lock = true
	
	local duration = 0
	for k, v in pairs(EnemyData) do
		if type(k) == "number" then
			duration = duration + v.SlowDur
		end
	end

	EnemyData.Lock = false
	
	return duration
end

function EnemyData.GetEnemyTeamStunDuration()
	if ( EnemyData.Lock ) then return 0 end
	EnemyData.Lock = true
	
	local duration = 0
	for k, v in pairs(EnemyData) do
		if type(k) == "number" then
			duration = duration + v.StunDur
		end
	end

	EnemyData.Lock = false
	
	return duration
end

function EnemyData.GetEnemyTeamNumSilences()
	if ( EnemyData.Lock ) then return 0 end
	EnemyData.Lock = true
	
	local num = 0
	for k, v in pairs(EnemyData) do
		if type(k) == "number" then
			if v.HasSilence then
				num = num + 1
			end
		end
	end

	EnemyData.Lock = false
	
	return num
end

function EnemyData.GetEnemyTeamNumTruestrike()
	if ( EnemyData.Lock ) then return 0 end
	EnemyData.Lock = true
	
	local num = 0
	for k, v in pairs(EnemyData) do
		if type(k) == "number" then
			if v.HasTruestrike then
				num = num + 1
			end
		end
	end

	EnemyData.Lock = false
	
	return num
end

function EnemyData.PrintEnemyInfo()

	if ( EnemyData.Lock ) then return end
	EnemyData.Lock = true
	
	for k, v in pairs(EnemyData) do
		if type(k) == "number" then
			print("")
			print("     Name: ", v.Name)
			print("    Level: ", v.Level)
			print("Last Seen: ", v.Time)
			print("   Health: ", v.Health)
			print("     Mana: ", v.Mana)
			if v.Location then
				print(" Location: <", v.Location[1]..", "..v.Location[2]..", "..v.Location[3]..">")
			else
				print(" Location: <UNKNOWN>")
			end
			local iStr = ""
			for k2, v2 in pairs(v.Items) do
				iStr = iStr .. v2 .. " "
			end
			print("    Items: { "..iStr.." }")
		end
	end

	EnemyData.Lock = false
end

return EnemyData