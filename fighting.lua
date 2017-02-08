-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: minor inspiration from Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "fighting", package.seeall )
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )

function GlobalFindTarget(heroToEnemyDist)
    local viableEnemiesToFight = {}
    for k, enemy in pairs(enemyData) do
        if type(k) == "number" and enemy.Alive then
            table.insert(viableEnemiesToFight, enemy)
        end
    end

    local listAllies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    for _, enemy in ipairs(viableEnemiesToFight) do
        enemy.alliesThatCanAttack = {}
        for _, ally in pairs(listAllies) do
            if ally:IsAlive() and (ally:GetHealth()/ally:GetMaxHealth()) > 0.4 then
                local timeToLocation = GetUnitToUnitDistance(enemy, ally)/ally:GetCurrentMovementSpeed()
                if timeToLocation < 3.0 then
                    table.insert(enemy.alliesThatCanAttack, ally)
                end
            end
        end
    end
    
    -- sort by high-to-low number of allies that can converge on target
    table.sort(viableEnemiesToFight, function(n1, n2) return #n1.alliesThatCanAttack > #n2.alliesThatCanAttack end)
    
    
end

function FindTarget(listEnemies, listEnemyTowers, listAlliedTowers, listEnemyCreeps, listAlliedCreeps)
	local npcBot = GetBot()

	local mindis = 100000
	local candidate = nil
	local bestScore = -1

	if #listEnemies == 0 then
		return nil, 0.0
	end

	local nEc = #listEnemyCreeps
	local nAc = #listAlliedCreeps

	local nTo = #listEnemyTowers
    local fTo = #listAlliedTowers

    local goodHealthPool = 0
    local badHealthPool = 0
    local goodDmg = 0
    local badDmg = 0
    local goodFightLength = 10.0
    local badfightLength = 10.0
    
    local deadBaddies = {}
    
    local lvl = npcBot:GetLevel()
	for _, enemy in pairs(listEnemies) do
		if utils.NotNilOrDead(enemy) and GetUnitToLocationDistance(enemy, utils.Fountain(utils.GetOtherTeam())) > 1350 then
            
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
				if type(k) == "number" and enemy2.Alive and (enemy2.Health/enemy2.MaxHealth) > 0.1 then
                    local distance = 100000
                    if enemy2.Obj then
                        distance = GetUnitToUnitDistance(enemy, enemy2.Obj)
                    else
                        if GetHeroLastSeenInfo(k).time <= 0.5 then
                            distance = GetUnitToLocationDistance(enemy, enemy2.LocExtra1)
                        elseif GetHeroLastSeenInfo(k).time <= 3.0 then
                            distance = GetUnitToLocationDistance(enemy, enemy2.LocExtra2)
                        else
                            distance = GetUnitToLocationDistance(enemy, GetHeroLastSeenInfo(k).location)
                        end
                    end
                    
					if distance < 1200 then
                        badfightLength = badfightLength + enemy2.StunDur + 0.5*enemy2.SlowDur
					end
				end
			end
            
            for k, enemy2 in pairs(enemyData) do
				if type(k) == "number" and enemy2.Alive and (enemy2.Health/enemy2.MaxHealth) > 0.1 then
                    local distance = 100000
                    if enemy2.Obj then
                        distance = GetUnitToUnitDistance(enemy, enemy2.Obj)
                    else
                        if GetHeroLastSeenInfo(k).time <= 0.5 then
                            distance = GetUnitToLocationDistance(enemy, enemy2.LocExtra1)
                        elseif GetHeroLastSeenInfo(k).time <= 3.0 then
                            distance = GetUnitToLocationDistance(enemy, enemy2.LocExtra2)
                        else
                            distance = GetUnitToLocationDistance(enemy, GetHeroLastSeenInfo(k).location)
                        end
                    end
                    
					if distance < 1200 then
                        local dmgTime = badfightLength - distance/enemy2.MoveSpeed
						badHealthPool = badHealthPool + enemy2.Health
                        if utils.ValidTarget(enemy2) then
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