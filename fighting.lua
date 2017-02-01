-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: some inspiration from Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------


_G._savedEnv = getfenv()
module( "fighting", package.seeall )
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )

function GlobalFindTarget(heroToEnemyDist)

    enemyData.UpdateEnemyInfo()
    for k, enemy in pairs(enemyData) do
        if type(k) == "number" then
        end
    end
    

    local listAllies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    for _, ally in ipairs(listAllies) do
    end
    
end

function FindTarget(dist)
	local npcBot = GetBot()

	local mindis = 100000
	local candidate = nil
	local bestScore = -1

	local Enemies = npcBot:GetNearbyHeroes(dist, true, BOT_MODE_NONE);

	if Enemies == nil or #Enemies == 0 then
		setHeroVar("Target", nil)
		return nil, 0.0
	end

	local Towers = npcBot:GetNearbyTowers(750, true)
	local AlliedTowers = npcBot:GetNearbyTowers(750, false)
	local AlliedCreeps = npcBot:GetNearbyCreeps(700, false)
	local EnemyCreeps = npcBot:GetNearbyCreeps(700 ,true)
	local nEc = 0
	local nAc = 0
    
	if AlliedCreeps ~= nil then
		nAc = #AlliedCreeps
	end
	if EnemyCreeps ~= nil then
		nEc = #EnemyCreeps
	end

	local nTo = 0
	if Towers ~= nil then
		nTo = #Towers
	end

	local fTo = 0
	if AlliedTowers ~= nil then
		fTo = #AlliedTowers
	end

    local goodHealthPool = 0
    local badHealthPool = 0
    local goodDmg = 0
    local badDmg = 0
    local goodFightLength = 10.0
    local badfightLength = 10.0
    
    local deadBaddies = {}
    
    local lvl = npcBot:GetLevel()
	for _, enemy in pairs(Enemies) do
		if utils.NotNilOrDead(enemy) and GetUnitToLocationDistance(enemy, utils.Fountain(utils.GetOtherTeam())) > 1350 
            and enemy:GetTimeSinceLastSeen() < 1.0 then
            
            -- get our stun/slow duration
            local sd = npcBot:GetStunDuration(true) + 0.5*npcBot:GetSlowDuration(true)
            
            -- get stun/slow duration of allies that can reach us during my stun/slow duration
            local allyList = GetUnitList(UNIT_LIST_ALLIED_HEROES)
            local goodStunDuration = sd
            for _, ally in pairs(allyList) do
                if ally:GetPlayerID() ~= npcBot:GetPlayerID() then -- remove ourselves from consideration
                    local timeToLocation = GetUnitToUnitDistance(enemy, ally)/ally:GetCurrentMovementSpeed()
                    if utils.NotNilOrDead(Ally) and timeToLocation <= sd then
                        goodStunDuration = goodStunDuration + ally:GetStunDuration(true) + 0.5*ally:GetSlowDuration(true)
                    end
                end
			end
            
            local boomDmg = 0
            for _, ally in pairs(allyList) do
                local timeToLocation = GetUnitToUnitDistance(enemy, ally)/ally:GetCurrentMovementSpeed()
                if timeToLocation < goodStunDuration then
                    boomDmg = boomDmg + ally:GetEstimatedDamageToTarget(true, enemy, goodStunDuration - timeToLocation, DAMAGE_TYPE_ALL)
                end
            end
            if boomDmg >= enemy:GetHealth()+50 then
                utils.myPrint("I/We can smoke this target: ", utils.GetHeroName(enemy))
                table.insert(deadBaddies, enemy)
                break -- no need to do rest of math
            end
            
            -- OTHERWISE: we need to do some math about the upcoming team fight
            
            -- first check for stun duration
            for k, enemy2 in pairs(enemyData) do
				if type(k) == "number" and enemy2.Health > 0 and (enemy2.Health/enemy2.MaxHealth) > 0.1 then
                    local distance = GetUnitToLocationDistance(enemy, enemy2.Location)
					if distance < 1200 then
                        badfightLength = badfightLength + enemy2.StunDur + 0.5*enemy2.SlowDur
					end
				end
			end
            
            for k, enemy2 in pairs(enemyData) do
				if type(k) == "number" and enemy2.Health > 0 and (enemy2.Health/enemy2.MaxHealth) > 0.1 then
                    local distance = GetUnitToLocationDistance(enemy, enemy2.Location)
					if distance < 1200 then
                        local dmgTime = badfightLength - distance/enemy2.MoveSpeed
						badHealthPool = badHealthPool + enemy2.Health
                        if enemy2.Obj ~= nil then
                            badDmg = badDmg + enemy2.Obj:GetEstimatedDamageToTarget(true, npcBot, dmgTime, DAMAGE_TYPE_ALL)
                        end
					end
				end
			end

            -- get our stun duration
            local allyList = GetUnitList(UNIT_LIST_ALLIED_HEROES)
            for _, ally in pairs(allyList) do
                local timeToLocation = GetUnitToUnitDistance(enemy, ally)/ally:GetCurrentMovementSpeed()
				if utils.NotNilOrDead(Ally) and timeToLocation < goodFightLength then
					goodFightLength = goodFightLength + ally:GetStunDuration(true) + 0.5*ally:GetSlowDuration(true)
				end
			end
            
			local allyList = GetUnitList(UNIT_LIST_ALLIED_HEROES)
            for _, ally in pairs(allyList) do
                local timeToLocation = GetUnitToUnitDistance(enemy, ally)/ally:GetCurrentMovementSpeed()
				if utils.NotNilOrDead(Ally) and timeToLocation < goodFightLength then
					local dmgTime = goodFightLength - timeToLocation
                    goodHealthPool = goodHealthPool + ally:GetHealth()
                    goodDmg = goodDmg + ally:GetEstimatedDamageToTarget(true, enemy, dmgTime, DAMAGE_TYPE_ALL)
				end
			end

			local score = (goodHealthPool - badDmg) - (badHealthPool - goodDmg) + (fTo - nTo)/(Min(lvl/8,3)) + (nAc - nEc)/(2*lvl)
			if score > bestScore then
				candidate = enemy
				bestScore = score
			end
		end
	end
    
    --[[
    if candidate ~= nil then
        --utils.myPrint("Best Fight is against: "..utils.GetHeroName(candidate), " :: Score: ", bestScore)
        enemyData.GetEnemyDmgs(candidate:GetPlayerID(), 2.0)
    end
    --]]
    
    if #deadBaddies == 1 then
        return deadBaddies[1], 100.0
    elseif #deadBaddies > 1 then
        -- kill the one with the most health
        table.sort(deadBaddies, function(n1, n2) return n1:GetHealth() > n2:GetHealth() end)
        return deadBaddies[1], 100.0
    end

	return candidate, bestScore
end

-------------------------------------------------------------------------------
for k,v in pairs( fighting ) do _G._savedEnv[k] = v end