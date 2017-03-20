-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local genericAbility = BotsInit.CreateGeneric()

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

local castQDesire   = 0
local castWDesire   = 0
local castRDesire   = 0

local AttackRange   = 0
local ManaPerc      = 0.0
local HealthPerc    = 0.0

function ConsiderQ()
    local bot = GetBot()
    
    if not abilityQ:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, {}
	end
	
	local CastRange = abilityQ:GetCastRange()
	local Damage    = abilityQ:GetSpecialValueInt("strike_damage")+5*(abilityQ:GetSpecialValueInt("tick_damage"))
	local Radius    = abilityQ:GetAOERadius()
	
	local HeroHealth    = 10000
	local CreepHealth   = 10000
    
    
	local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange+150)
    
    local modeName = getHeroVar("Self"):getCurrentMode():GetName()

    --------------------------------------
	-- Global high-priorty usage
	--------------------------------------
	--try to kill enemy hero
	if modeName ~= "retreat" then
		if WeakestEnemy ~= nil then
			if not utils.IsTargetMagicImmune( WeakestEnemy ) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
                    local dist = GetUnitToUnitDistance(bot, WeakestEnemy)
                    if dist < (CastRange + Radius) then
                        return BOT_ACTION_DESIRE_HIGH, utils.VectorTowards(bot:GetLocation(), WeakestEnemy:GetLocation(), 100)
                    else
                        return BOT_ACTION_DESIRE_HIGH, utils.VectorTowards(bot:GetLocation(), WeakestEnemy:GetLocation(), dist+100)
                    end
				end
			end
		end
	end
    
	--------------------------------------
	-- Mode based usage
	--------------------------------------
	-- fighting (team fight) and can hit 2+ enemies
	if modeName == "fight" then
		if ManaPerc > 0.25 then
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0, 0 )
			if locationAoE.count >= 2 then
				return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc
			end
		end
	end
	
	-- If we're pushing or defending a lane and can hit 3+ creeps, go for it
	if modeName == "defendlane" or modeName == "pushlane" then
		if ManaPerc > 0.4 then
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0, 0 )
			if locationAoE.count >= 3 then
				return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc
			end
		end
	end

	-- If my mana is enough and we have at least level 2 of ability, and can hit 2 enemies
	if ManaPerc > 0.4 and abilityQ:GetLevel() >= 2 then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), CastRange, Radius, 0, 0 )
		if locationAoE.count >= 2 then
			return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
		end
	end
    
    -- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end
        
		if utils.ValidTarget(npcEnemy) then
			if not utils.IsTargetMagicImmune( npcEnemy ) and utils.IsCrowdControlled(npcEnemy) then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetLocation()
			end
		end
	end
	
	-- If we're farming and can kill 3+ creeps
	if modeName == "jungling" or modeName == "laning" then
		if ManaPerc > 0.25 then
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0, Damage )
			if ( locationAoE.count >= 3 ) then
				return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderE()
    local bot = GetBot()
    
    if not abilityE:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end
    
    local CastRange = abilityE:GetCastRange()
    local modeName = getHeroVar("Self"):getCurrentMode():GetName()
    
    --------------------------------------
	-- Global high-priorty usage
	--------------------------------------
    local enemies = gHeroVar.GetNearbyEnemies( bot, 1200 )
	
    -- if I'm retreating
	if modeName == "retreat" then
		if #enemies >= 1 or bot:WasRecentlyDamagedByAnyHero(5.0) then
            return BOT_ACTION_DESIRE_MODERATE, bot:GetLocation() + RandomVector( RandomInt(0, CastRange) )
		end
	end
    
    --------------------------------------
	-- Mode based usage
	--------------------------------------

	-- If we're pushing a lane and attacking a tower
	if modeName == "pushlane" or modeName == "defendlane" then
		local target = bot:GetAttackTarget()
		if utils.NotNilOrDead(target) then
			if ManaPerc > 0.4 and target:IsTower() then
                if not utils.IsTargetMagicImmune( bot ) then
                    return BOT_ACTION_DESIRE_LOW, target:GetLocation() + RandomVector( RandomInt(0, CastRange) )
                end
			end
		end
        
        local friendlyTower = gHeroVar.GetNearbyAlliedTowers(bot, CastRange+300)
        if #friendlyTower >= 1 then
            if ManaPerc > 0.4 and #gHeroVar.GetNearbyEnemyCreep(bot, 900) > 1 then
                return BOT_ACTION_DESIRE_LOW, friendlyTower[1]:GetLocation() + RandomVector( RandomInt(0, CastRange) )
            end
        end
	end

	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end
		
		if ManaPerc > 0.4 then
			if utils.ValidTarget(npcEnemy) then
				return BOT_ACTION_DESIRE_MODERATE, utils.VectorTowards(bot:GetLocation(), npcEnemy:GetLocation(), RandomInt(0, CastRange))
			end
		end
	end
	
	-- If we're farming
    local creeps = gHeroVar.GetNearbyEnemyCreep( bot, 900 )
	if modeName == "laning" or modeName == "jungling" then
		if #creeps >= 2 then
			if ManaPerc > 0.4 then
                return BOT_ACTION_DESIRE_LOW, utils.VectorTowards(bot:GetLocation(), creeps[1]:GetLocation(), RandomInt(0, CastRange))
			end	
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderR()
    local bot = GetBot()
    
    if not abilityR:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end

    local CastRange = abilityR:GetCastRange()
    local Radius    = abilityR:GetAOERadius()
    
    local modeName = getHeroVar("Self"):getCurrentMode():GetName()
    
	--------------------------------------
	-- Global high-priorty usage
	--------------------------------------
    
	--try to kill enemy heroes
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
	
	--------------------------------------
	-- Mode based usage
	--------------------------------------
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

function genericAbility:AbilityUsageThink(bot)
    -- Check if we're already using an ability
    if utils.IsBusy(bot) then return true end
    
    -- Check to see if we are CC'ed
    if utils.IsCrowdControlled(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( "venomancer_venomous_gale" ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( "venomancer_poison_sting" ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( "venomancer_plague_ward" ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( "venomancer_poison_nova" ) end
    
    -- WRITE CODE HERE --
    AttackRange   = bot:GetAttackRange()
	ManaPerc      = bot:GetMana()/bot:GetMaxMana()
	HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    
    -- Consider using each ability
	local castQDesire, castQLocation  = ConsiderQ()
	local castEDesire, castELocation  = ConsiderE()
	local castRDesire, castRTarget    = ConsiderR()
    
    if castRDesire > 0 then
        bot:Action_UseAbility( abilityR )
        return true
    end
    
    if castEDesire > 0 then
        bot:Action_UseAbilityOnLocation( abilityE, castELocation )
        return true
    end
    
    if castQDesire > 0 then
        bot:Action_UseAbilityOnLocation( abilityQ, castQLocation )
        return true
    end
    
    return false
end

function genericAbility:nukeDamage( bot, enemy )
    if enemy == nil or enemy:IsNull() then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 10000
    
    -- WRITE CODE HERE --
    
    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function genericAbility:queueNuke(bot, enemy, castQueue, engageDist)
    -- WRITE CODE HERE --
    
    return false
end

return genericAbility
