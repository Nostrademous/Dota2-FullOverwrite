-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_antimage", package.seeall )

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
	local bot = bot or GetBot()
	gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
	local bot = bot or GetBot()
	return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

function AbilityUsageThink()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end
	
	local npcBot = GetBot()
	if not npcBot:IsAlive() then return false end
	
	local EnemyHeroes = npcBot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
	
	if #EnemyHeroes == 0 then return false end

	-- Check if we're already using an ability
	if npcBot:IsUsingAbility() then return false end

	abilityMV = npcBot:GetAbilityByName( "antimage_mana_void" )

	-- Consider using each ability
	castMVDesire, castMVTarget = ConsiderManaVoid( abilityMV )

	if castMVDesire > 0 then
		npcBot:Action_UseAbilityOnEntity( abilityMV, castMVTarget )
		return true
	end
	
	return false
end

----------------------------------------------------------------------------------------------------

function CanCastManaVoidOnTarget( npcTarget )
	return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

----------------------------------------------------------------------------------------------------

function ConsiderManaVoid(abilityMV)

	local npcBot = GetBot()

	-- Make sure it's castable
	if not abilityMV:IsFullyCastable() then 
		return BOT_ACTION_DESIRE_NONE, 0;
	end

	-- Get some of its values
	local nRadius = abilityMV:GetSpecialValueInt( "mana_void_aoe_radius" )
	local nDmgPerMana = abilityMV:GetSpecialValueFloat( "mana_void_damage_per_mana" )
	local nCastRange = abilityMV:GetCastRange()

	--------------------------------------
	-- Global high-priorty usage
	--------------------------------------

	local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE )
	local channelingHero = nil
	local lowestManaHero = nil
	local highestManaDiff = 0
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
		if npcEnemy:IsChanneling() then
			channelingHero = npcEnemy
		end
		local manaDiff = npcEnemy:GetMaxMana() - npcEnemy:GetMana()
		if manaDiff > highestManaDiff then
			lowestManaHero = npcEnemy
			highestManaDiff = manaDiff
		end
	end
	
	if lowestManaHero == nil then return BOT_ACTION_DESIRE_NONE, nil end
	
	local aoeDmg = highestManaDiff * nDmgPerMana
	local actualDmgLowest = lowestManaHero:GetActualDamage( aoeDmg, DAMAGE_TYPE_MAGICAL )
	
	if channelingHero ~= nil and channelingHero:GetHealth() < channelingHero:GetActualDamage( aoeDmg, DAMAGE_TYPE_MAGICAL ) 
		and GetUnitToUnitDistance(channelingHero, lowestManaHero) < nRadius then
		return BOT_ACTION_DESIRE_HIGH, lowestManaHero
	elseif lowestManaHero:GetHealth() < actualDmgLowest then
		--FIXME: Figure out how many deaths ulting each hero would result in - pick greatest # if above 0
		return BOT_ACTION_DESIRE_HIGH, lowestManaHero
	end

	--------------------------------------
	-- Mode based usage
	--------------------------------------

	-- If we're going after someone
	local npcTarget = getHeroVar("Target")

	if npcTarget.Obj ~= nil then
		local manaDiff = npcTarget.Obj:GetMaxMana() - npcTarget.Obj:GetMana()
		aoeDmg = manaDiff * nDmgPerMana
		if CanCastManaVoidOnTarget( npcTarget.Obj ) and (npcTarget.Obj:IsChanneling() or npcTarget.Obj:GetHealth() < aoeDmg) then
			return BOT_ACTION_DESIRE_HIGH, npcTarget.Obj
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

for k,v in pairs( ability_usage_antimage ) do _G._savedEnv[k] = v end