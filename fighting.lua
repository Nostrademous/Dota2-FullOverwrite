-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: some inspiration from Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------


_G._savedEnv = getfenv()
module( "fighting", package.seeall )
-------------------------------------------------------------------------------

local utils = require( GetScriptDirectory().."/utility" )

function FindTarget(dist)
	local npcBot = GetBot()

	local mindis = 100000
	local candidate = nil
	local bestScore = -1

	local Enemies = npcBot:GetNearbyHeroes(dist, true, BOT_MODE_NONE);

	if Enemies == nil or #Enemies == 0 then
		setHeroVar("Target", nil)
		return nil, 0.0, 0.0
	end

	local Towers = npcBot:GetNearbyTowers(1100, true)
	local AlliedTowers = npcBot:GetNearbyTowers(950, false)
	local AlliedCreeps = npcBot:GetNearbyCreeps(1000, false)
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
    local fightLength = 5.0
    
    local lvl = npcBot:GetLevel()
	for _, enemy in pairs(Enemies) do
		if utils.NotNilOrDead(enemy) and GetUnitToLocationDistance(enemy, utils.Fountain(utils.GetOtherTeam())) > 1350 then

            for k, enemy2 in pairs(enemyData) do
				if type(k) == "number" and enemy2.Health > 50 then
                    local distance = GetUnitToLocationDistance(enemy, enemy2.Location)
					if distance < 1200 then
                        local dmgTime = fightLength - distance/522
						badHealthPool = badHealthPool + enemy2.Health
                        if enemy2.Obj ~= nil then
                            badDmg = badDmg + enemy2.Obj:GetEstimatedDamageToTarget(true, npcBot, dmgTime, DAMAGE_TYPE_ALL)
                        end
					end
				end
			end

			local allyList = GetUnitList(UNIT_LIST_ALLIED_HEROES)
            for _, ally in pairs(allyList) do
                local timeToLocation = GetUnitToUnitDistance(enemy, ally)/ally:GetBaseMovementSpeed()
				if utils.NotNilOrDead(Ally) and timeToLocation < fightLength then
					local dmgTime = fightLength - timeToLocation
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
    
    if candidate ~= nil then
        utils.myPrint("Best Fight is against: "..utils.GetHeroName(candidate), " :: Score: ", bestScore)
        enemyData.GetEnemyDmgs(candidate:GetPlayerID(), 2.0)
    end

	return candidate, bestScore
end

-------------------------------------------------------------------------------
for k,v in pairs( fighting ) do _G._savedEnv[k] = v end