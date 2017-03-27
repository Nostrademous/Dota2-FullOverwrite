-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local cmAbility = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/fight_simul" )
require( GetScriptDirectory().."/modifiers" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

local Abilities ={
    "crystal_maiden_crystal_nova",
    "crystal_maiden_frostbite",
    "crystal_maiden_brilliance_aura",
    "crystal_maiden_freezing_field"
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

local ManaPerc      = 0.0

function cmAbility:nukeDamage( bot, enemy )
    if not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 10000

    local magicImmune = utils.IsTargetMagicImmune(enemy)

    -- Check Crystal Nova
    if abilityQ:IsFullyCastable() then
        local manaCostQ = abilityQ:GetManaCost()
        if manaCostQ <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostQ
                dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(abilityQ:GetSpecialValueInt("nova_damage"), DAMAGE_TYPE_MAGICAL)
                castTime = castTime + abilityQ:GetCastPoint()
                slowTime = slowTime + abilityQ:GetSpecialValueFloat("duration")
                engageDist = Min(engageDist, abilityQ:GetCastRange())
                table.insert(comboQueue, 1, abilityQ)
            end
        end
    end

    -- Check Frostbite
    if abilityW:IsFullyCastable() then
        local manaCostW = abilityW:GetManaCost()
        if manaCostW <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostW
                dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(abilityW:GetSpecialValueInt("hero_damage_tooltip"), DAMAGE_TYPE_MAGICAL)
                castTime = castTime + abilityW:GetCastPoint()
                stunTime = stunTime + abilityW:GetSpecialValueFloat("duration")
                engageDist = Min(engageDist, abilityW:GetCastRange())
                table.insert(comboQueue, 1, abilityW)
            end
        end
    end

    -- Check Freezing Field
    if abilityR:IsFullyCastable() then
        local manaCostR = abilityR:GetManaCost()
        if manaCostR <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostR

                local distToEdgeOfField = 835 - GetUnitToUnitDistance(bot, enemy)
                -- "movespeed_slow"	"-30"
                local timeInField = 0
                if distToEdgeOfField > 0 then timeInField = math.min(distToEdgeOfField/(enemy:GetCurrentMovementSpeed()-30), 10) end
                if timeInField < 0 then timeInField = 0 end

                dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(abilityR:GetSpecialValueInt("damage")*timeInField, DAMAGE_TYPE_MAGICAL)
                castTime = castTime + abilityR:GetCastPoint()
                slowTime = slowTime + abilityR:GetSpecialValueFloat("slow_duration")
                engageDist = Min(engageDist, 835)
                table.insert(comboQueue, abilityR)
            end
        end
    end

    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function cmAbility:queueNuke(bot, enemy, castQueue, engageDist)
    if not utils.ValidTarget(enemy) then return false end
    
    local dist = GetUnitToUnitDistance(bot, enemy)

    -- if out of range, attack move for one hit to get in range
    if dist < engageDist then
        bot:Action_ClearActions(false)
        utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
        utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
        for i = #castQueue, 1, -2 do
            local skill = castQueue[i]
            local behaviorFlag = skill:GetBehavior()

            --utils.myPrint(" - skill '", skill:GetName(), "' has BehaviorFlag: ", behaviorFlag)

            if skill:GetName() == Abilities[1] then
                if utils.IsCrowdControlled(enemy) then
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
                else
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetExtrapolatedLocation(0.95))
                end
            elseif skill:GetName() == Abilities[2] then
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            elseif skill:GetName() == Abilities[4] then
                gHeroVar.HeroPushUseAbility(bot, skill)
            end
        end
        return true
    end
    return false
end

function cmAbility:AbilityUsageThink(bot)
    if utils.IsBusy(bot) then return true end
    
    if utils.IsUnableToCast(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    local nearbyEnemyHeroes = gHeroVar.GetNearbyEnemies(bot, 1200)
    local nearbyEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)
    
    if #nearbyEnemyHeroes == 0 and #nearbyEnemyCreep == 0 then return false end

    if #nearbyEnemyHeroes >= 1 then
        local nRadius = abilityQ:GetSpecialValueInt( "radius" )
        local nCastRange = abilityQ:GetCastRange()

        --FIXME: in the future we probably want to target a hero that has a disable to my ult, rather than weakest
        local enemy, enemyHealth = utils.GetWeakestHero(bot, nRadius + nCastRange, nearbyEnemyHeroes)
        local dmg, castQueue, castTime, stunTime, slowTime, engageDist = self:nukeDamage( bot, enemy )

        local rightClickTime = stunTime + 0.5*slowTime
        if rightClickTime > 0.5 then
            dmg = dmg + fight_simul.estimateRightClickDamage( bot, enemy, rightClickTime )
        end

        -- magic immunity is already accounted for by nukeDamage()
        if dmg > enemyHealth then
            local bKill = self:queueNuke(bot, enemy, castQueue, engageDist)
            if bKill then
                setHeroVar("Target", enemy)
                return true
            end
        end
    end
    
	ManaPerc      = bot:GetMana()/bot:GetMaxMana()
    
    -- Consider using each ability
	local castQDesire, castQLocation  = ConsiderQ()
	local castWDesire, castWTarget    = ConsiderW()
	local castRDesire                 = ConsiderR()
    
    if castQDesire > 0 and castQDesire > castWDesire and castQDesire > castRDesire then
        gHeroVar.HeroUseAbilityOnLocation( bot, abilityQ, castQLocation )
        return true
    end
    
    if castWDesire > 0 and castWDesire > castRDesire then
        gHeroVar.HeroUseAbilityOnEntity( bot, abilityW, castWTarget )
        return true
    end
    
    if castRDesire > 0 then
        gHeroVar.HeroUseAbility( bot, abilityR )
        return true
    end
    
    return false
end

function ConsiderQ()
    local bot = GetBot()
    
    if not abilityQ:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end
    
    local modeName  = bot.SelfRef:getCurrentMode():GetName()
    
    local CastRange = abilityQ:GetCastRange()
    local Radius    = 425
    local CastPoint = abilityQ:GetCastPoint()
    local Damage    = abilityQ:GetSpecialValueInt("nova_damage")
    
    --------------------------------------
	-- Global high-priorty usage
	--------------------------------------
	--try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange + Radius - 100)
    
	if modeName ~= "retreat" then
		if utils.ValidTarget(WeakestEnemy) then
			if not utils.IsTargetMagicImmune( WeakestEnemy ) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy:GetExtrapolatedLocation( CastPoint )
				end
			end
		end
	end
    
	--------------------------------------
	-- Mode based usage
	--------------------------------------
    
    local nearbyAlliedHeroes = gHeroVar.GetNearbyAllies(bot, 1000)
    local coreNear = false
    for _, ally in pairs(nearbyAlliedHeroes) do
        if not ally:IsIllusion() and utils.IsCore(ally) then
            coreNear = true
            break
        end
    end
    
	-- farming/laning
	if modeName == "jungling" or modeName == "laning" then
		if ManaPerc > 0.4 and not coreNear then
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0, Damage )

			if locationAoE.count >= 2 and GetUnitToLocationDistance(bot, locationAoE.targetloc) <= CastRange then
				return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
			end
		end
		
        -- if we can hit 2+ enemies do it
		if ManaPerc > 0.4 and abilityQ:GetLevel() >= 2 then
			local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), CastRange, Radius, 0, 0 )
			if locationAoE.count >= 2 and GetUnitToLocationDistance(bot, locationAoE.targetloc) <= CastRange then
				return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
			end
		end
	end

	-- If we're pushing or defending a lane and can hit 3+ creeps, go for it
	if modeName == "defendlane" or modeName == "pushlane" then
		local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0, 0 )

		if locationAoE.count >= 3 and GetUnitToLocationDistance(bot, locationAoE.targetloc) <= CastRange then
			return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
		end
	end

	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if modeName == "retreat" or modeName == "shrine" then
		local tableNearbyEnemyHeroes = gHeroVar.GetNearbyEnemies( bot, CastRange + Radius + 200 )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes ) do
			if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
				if not utils.IsTargetMagicImmune( npcEnemy ) then
					return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetExtrapolatedLocation( CastPoint )
				end
			end
		end
	end

	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
			if not utils.IsTargetMagicImmune(npcEnemy) then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetExtrapolatedLocation( CastPoint )
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, {}    
end

function ConsiderW()
    local bot = GetBot()
    
    if not abilityW:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end
    
    local modeName  = bot.SelfRef:getCurrentMode():GetName()
    
    local CastRange = abilityW:GetCastRange()
    local Damage    = abilityW:GetSpecialValueInt("hero_damage_tooltip")

    --------------------------------------
	-- Global high-priorty usage
	--------------------------------------
	-- Check for a channeling enemy
    local enemies = gHeroVar.GetNearbyEnemies(bot, CastRange + 300)
    
	for _, npcEnemy in pairs( enemies ) do
		if npcEnemy:IsChanneling() and not utils.IsTargetMagicImmune(npcEnemy) then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy
		end
	end
	
	-- Try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange + 150)
	if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
		if utils.ValidTarget(WeakestEnemy) then
			if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
				end
			end
		end
	end
	
	-- If we're in a teamfight, use it on the scariest enemy
	local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1000)
	if #tableNearbyAttackingAlliedHeroes >= 2 then
		local npcMostDangerousEnemy = utils.GetScariestEnemy(bot, CastRange)

		if utils.ValidTarget(npcMostDangerousEnemy)	then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy
		end
	end
    
	--------------------------------------
	-- Mode based usage
	--------------------------------------
    
	-- protect myself
	if bot:WasRecentlyDamagedByAnyHero(5) then
        local closeEnemies = gHeroVar.GetNearbyEnemies(bot, 500)
		for _, npcEnemy in pairs( closeEnemies ) do
			if not utils.IsTargetMagicImmune( npcEnemy ) and not utils.IsCrowdControlled(npcEnemy) then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end
	
	-- If my mana is enough, use it on weakest enemy
	if modeName == "jungling" or modeName == "laning" then
		if (ManaPerc > 0.4 and abilityW:GetLevel() >= 2) or
           (ManaPerc > 0.7) then
			if utils.ValidTarget(WeakestEnemy) then
				if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
					return BOT_ACTION_DESIRE_LOW, WeakestEnemy
				end
			end
		end
        
        -- if we are farming, kill strongest creep
        local nearbyAlliedHeroes = gHeroVar.GetNearbyAllies(bot, 1200)
        local coreNear = false
        for _, ally in pairs(nearbyAlliedHeroes) do
            if not ally:IsIllusion() and utils.IsCore(ally) then
                coreNear = true
                break
            end
        end
    
        if not coreNear and ManaPerc > 0.4 and #enemies == 0 then
            local enemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, CastRange+300)
            if #enemyCreep > 0 then
                if #enemyCreep > 1 then
                    table.sort(enemyCreep, function(n1,n2) return n1:GetHealth() > n2:GetHealth() end)
                end
                return BOT_ACTION_DESIRE_LOW, enemyCreep[1]
            end
        end
	end
	
	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
			if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) and 
                GetUnitToUnitDistance(bot, npcEnemy) < (CastRange + 75*#gHeroVar.GetNearbyAllies(bot,1200)) then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy
			end
		end
	end
	
	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if modeName == "retreat" or modeName == "shrine" then
		local tableNearbyEnemyHeroes = gHeroVar.GetNearbyEnemies( bot, CastRange )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes ) do
			if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
				if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderR()
    local bot = GetBot()
    
    if not abilityR:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end
    
    local modeName  = bot.SelfRef:getCurrentMode():GetName()

	local Radius    = abilityR:GetAOERadius()

	--------------------------------------
	-- Global high-priorty usage
	--------------------------------------
    
    local enemies = gHeroVar.GetNearbyEnemies(bot, Radius)
    local disabledHeroCount = 0
	for _, eHero in pairs(enemies) do
		if utils.IsCrowdControlled(eHero) or eHero:GetCurrentMovementSpeed() <= 200 then
			disabledHeroCount = disabledHeroCount + 1
		end
	end
    
    if (modeName == "fight" and #enemies >= 2) or disabledHeroCount >= 2 then
        return BOT_ACTION_DESIRE_HIGH
    end
	
	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
			if not utils.IsTargetMagicImmune(npcEnemy) and utils.IsCrowdControlled(npcEnemy) and 
                npcEnemy:GetHealth() <= npcEnemy:GetActualIncomingDamage(bot:GetOffensivePower(), DAMAGE_TYPE_MAGICAL) and 
                GetUnitToUnitDistance(bot, npcEnemy) <= Radius then
				return BOT_ACTION_DESIRE_MODERATE
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
end

return cmAbility
