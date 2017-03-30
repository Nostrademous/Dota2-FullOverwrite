-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local genericAbility = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/fight_simul" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

local AttackRange   = 0
local ManaPerc      = 0.0
local HealthPerc    = 0.0
local modeName      = nil

function genericAbility:AbilityUsageThink(bot)
    -- Check if we're already using an ability
    if utils.IsBusy(bot) then return true end
    
    -- Check to see if we are CC'ed
    if utils.IsUnableToCast(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( "spirit_breaker_charge_of_darkness" ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( "spirit_breaker_empowering_haste" ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( "spirit_breaker_greater_bash" ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( "spirit_breaker_nether_strike" ) end
    
    AttackRange   = bot:GetAttackRange()
	ManaPerc      = bot:GetMana()/bot:GetMaxMana()
	HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    local modeDesire    = bot.SelfRef:getCurrentModeValue()
    
    -- WRITE CODE HERE --
    
    -- Consider using each ability
	local castQDesire, castQTarget  = ConsiderQ()
	local castWDesire               = ConsiderW()
	local castRDesire, castRTarget  = ConsiderR()
    
    if castRDesire >= modeDesire and castRDesire >= Max(castWDesire, castQDesire) then
		gHeroVar.HeroUseAbilityOnEntity(bot, abilityR, castRTarget )
		return true
	end
	
	if castWDesire >= modeDesire and castWDesire >= castQDesire then
		gHeroVar.HeroUseAbility(bot,  abilityW )
		return true
	end

	if castQDesire >= modeDesire then
        bot:ActionPush_Delay(0.25)
		gHeroVar.HeroPushUseAbilityOnEntity(bot, abilityQ, castQTarget )
		return true
	end
    
    return false
end

function ConsiderQ()
    local bot = GetBot()
    
    if not abilityQ:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end
    
    --------------------------------------
	-- Global high-priorty usage
	--------------------------------------
    
    local enemies   = gHeroVar.GetNearbyEnemies(bot, 1600)
    
	-- Check for a channeling enemy
	if modeName ~= "retreat" then
		for _, npcEnemy in pairs( enemies ) do
			if npcEnemy:IsChanneling() and not utils.IsTargetMagicImmune(npcEnemy) then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end
	
	-- Try to kill enemy hero
	if modeName ~= "retreat" then
		local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, 1600, enemies)
		if utils.ValidTarget(WeakestEnemy) then
            if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(ComboDmg(bot, WeakestEnemy), DAMAGE_TYPE_PHYSICAL) then
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
				end
			end
		end
	end
	
	-- Gank
	if modeName ~= "retreat" and modeName ~= "fight" and HealthPerc >= 0.75 and ManaPerc >= 0.4	then
		-- protect teammate
		for _, npcAlly in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
			local enemies3  = gHeroVar.GetNearbyEnemies(npcAlly, 1200)
			local allies3   = gHeroVar.GetNearbyAllies(npcAlly, 1200)
            if npcAlly:GetPlayerID() ~= bot:GetPlayerID() then
                if not npcAlly:IsIllusion() and (npcAlly.SelfRef:getCurrentMode():GetName() == "retreat" or
                    npcAlly:GetHealth()/npcAlly:GetMaxHealth() <= (0.4+0.1*#enemies3)) then
                    if #enemies3 == 1 then
                        local npcEnemy = enemies3[1]
                        local timeToGetThere = GetUnitToUnitDistance(bot, npcAlly)/abilityQ:GetSpecialValueInt("movement_speed")
                        if npcAlly:GetHealth() > npcEnemy:GetEstimatedDamageToTarget(true, npcAlly, timeToGetThere, DAMAGE_TYPE_ALL) then
                            return BOT_ACTION_DESIRE_HIGH, npcEnemy
                        end
                    end
                end
            end
		end
		
		-- we have a roam target
		local roamTarget = getHeroVar("RoamTarget")
        if utils.ValidTarget(roamTarget) then
			local enemies3  = gHeroVar.GetNearbyAllies(roamTarget, Min(1600, roamTarget:GetCurrentVisionRange()))
			local allies3   = gHeroVar.GetNearbyEnemies(roamTarget, Min(1600, roamTarget:GetCurrentVisionRange()))
			local sumdamage = bot:GetEstimatedDamageToTarget(true, roamTarget, 4.0, DAMAGE_TYPE_ALL)
			
			if #enemies3 <= 2 then
				for _, npcAlly in pairs(allies3) do
					if not npcAlly:IsIllusion() and npcAlly:GetHealth()/npcAlly:GetMaxHealth() >= 0.7 and 
                        npcAlly.SelfRef:getCurrentMode():GetName() ~= "retreat" then
						sumdamage = sumdamage + npcAlly:GetEstimatedDamageToTarget(true, roamTarget, 4.0, DAMAGE_TYPE_ALL)
					end
				end
                
				if roamTarget:GetHealth()*1.1 <= sumdamage then
                    setHeroVar("Target", roamTarget)
					return BOT_ACTION_DESIRE_HIGH, roamTarget
				end
			end
		end
	end
	
	--------------------------------------
	-- Mode based usage
	--------------------------------------
	-- If we're retreating, see if we can run to another safe lane
	if modeName == "retreat" or modeName == "shrine" then
        if bot:WasRecentlyDamagedByAnyHero( 2.0 ) then
            for _, npcAlly in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
                if npcAlly:IsAlive() then
                    local enemies3 = gHeroVar.GetNearbyEnemies(npcAlly, 1600)
                    local creep    = gHeroVar.GetNearbyEnemyCreep(npcAlly, 1600)
                    if #enemies3 == 0 and #creep > 0 then
                        return BOT_ACTION_DESIRE_HIGH, creep[1]
                    elseif #enemies3 == 1 and #creep > 0 then
                        return BOT_ACTION_DESIRE_HIGH, creep[1]
                    end
                end
			end
		end
	end
	
	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end
		
        if utils.ValidTarget(npcEnemy) then
            local enemies3  = gHeroVar.GetNearbyAllies(npcEnemy, Min(1200, npcEnemy:GetCurrentVisionRange()))
            local allies3   = gHeroVar.GetNearbyEnemies(npcEnemy, Min(1600, npcEnemy:GetCurrentVisionRange()))
		
			if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) and 
                #enemies3 <= #allies3 then
                setHeroVar("Target", npcEnemy)
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy
			end
		end
	end
    
    return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderW()
    local bot = GetBot()
    
    if not abilityW:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE
	end
    
    --------------------------------------
	-- Mode based usage
	--------------------------------------
	-- If we're retreating
	if modeName == "retreat" or modeName == "shrine" then
		if bot:WasRecentlyDamagedByAnyHero( 2.0 ) then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) and ManaPerc > 0.4 then
            if GetUnitToUnitDistance(bot, npcEnemy) < 900 then
                return BOT_ACTION_DESIRE_MODERATE
            end
		end
	end
    
    return BOT_ACTION_DESIRE_NONE
end

function ConsiderR()
    local bot = GetBot()
    
    if not abilityR:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end
    
    local CastRange = abilityR:GetCastRange()
    local Damage    = abilityR:GetSpecialValueInt("damage")
    
    --------------------------------------
	-- Global high-priorty usage
	--------------------------------------
    
    local enemies = gHeroVar.GetNearbyEnemies(bot, CastRange+300)
    
	-- Check for a channeling enemy
	for _, npcEnemy in pairs( enemies )	do
		if npcEnemy:IsChanneling() and not utils.IsTargetMagicImmune( npcEnemy ) then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy
		end
	end
	
	-- Try to kill enemy hero
	if modeName ~= "retreat" then
        local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange+300, enemies)
		if utils.ValidTarget(WeakestEnemy) then
            if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
				end
			end
		end
	end
	
	--------------------------------------
	-- Mode based usage
	--------------------------------------
	-- If we're retreating, see if we can land a stun on someone who's damaged us recently
	if modeName == "retreat" or modeName == "shrine" then
		for _, npcEnemy in pairs( enemies ) do
			if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
				if not utils.IsTargetMagicImmune( npcEnemy ) and not utils.IsCrowdControlled(npcEnemy) and
                    GetUnitToUnitDistance(bot, npcEnemy) < CastRange then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy
				end
			end
		end
	end
	
	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
            local allies = gHeroVar.GetNearbyAllies( bot, 1200 )
			if not utils.IsTargetMagicImmune( npcEnemy ) and not utils.IsCrowdControlled(npcEnemy) and 
                GetUnitToUnitDistance(bot, npcEnemy) < (CastRange + 75*#allies) then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy
			end
		end
	end
    
    return BOT_ACTION_DESIRE_NONE, nil
end

function ComboDmg(bot, enemy)
    return bot:GetOffensivePower() + fight_simul.estimateRightClickDamage( bot, enemy, 4.0 )
end

function genericAbility:nukeDamage( bot, enemy )
    if not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = bot:GetOffensivePower()
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 500
    
    -- WRITE CODE HERE --
    
    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function genericAbility:queueNuke(bot, enemy, castQueue, engageDist)
    if not utils.ValidTarget(enemy) then return false end
    
    -- WRITE CODE HERE --
    
    return false
end

return genericAbility
