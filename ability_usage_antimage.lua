-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_antimage", package.seeall )

function AbilityUsageThink()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
	
	local npcBot = GetBot();
	
	local EnemyHeroes = npcBot:GetNearbyHeroes(1200, true, BOT_MODE_NONE);
	
	if #EnemyHeroes == 0 then return end

	-- Check if we're already using an ability
	if ( npcBot:IsUsingAbility() ) then return end;

	abilityMV = npcBot:GetAbilityByName( "antimage_mana_void" );

	-- Consider using each ability
	castMVDesire, castMVTarget = ConsiderManaVoid(abilityMV);

	if castMVDesire > 0 then
		npcBot:Action_UseAbilityOnEntity( abilityMV, castMVTarget );
		return;
	end
end

----------------------------------------------------------------------------------------------------

function CanCastManaVoidOnTarget( npcTarget )
	return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end

----------------------------------------------------------------------------------------------------

function ConsiderManaVoid(abilityMV)

	local npcBot = GetBot();

	-- Make sure it's castable
	if not abilityMV:IsFullyCastable() then 
		return BOT_ACTION_DESIRE_NONE, 0;
	end

	-- Get some of its values
	local nRadius = abilityMV:GetSpecialValueInt( "mana_void_aoe_radius" )
	local nDmgPerMana = abilityMV:GetSpecialValueFloat( "mana_void_damage_per_mana" )
	local nCastRange = abilityMV:GetCastRange();

	--------------------------------------
	-- Global high-priorty usage
	--------------------------------------

	local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE );
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
	
	local aoeDmg = highestManaDiff * nDmgPerMana
	
	if channelingHero ~= nil and channelingHero:GetHealth() < aoeDmg and GetUnitToUnitDistance(channelingHero, lowestManaHero) < nRadius then
		return BOT_ACTION_DESIRE_HIGH, lowestManaHero
	elseif channelingHero ~= nil then
		return BOT_ACTION_DESIRE_HIGH, channelingHero
	end

	--------------------------------------
	-- Mode based usage
	--------------------------------------

	-- If we're going after someone
	local npcTarget = npcBot:GetTarget();

	if ( npcTarget ~= nil ) then
		local manaDiff = npcTarget:GetMaxMana() - npcTarget:GetMana()
		aoeDmg = manaDiff * nDmgPerMana
		if CanCastManaVoidOnTarget( npcTarget ) and (npcTarget:IsChanneling() or npcTarget:GetHealth() < aoeDmg) then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

for k,v in pairs( ability_usage_antimage ) do _G._savedEnv[k] = v end