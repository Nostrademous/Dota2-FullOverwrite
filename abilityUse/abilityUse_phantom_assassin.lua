-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local genericAbility = BotsInit.CreateGeneric()

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

require( GetScriptDirectory().."/modifiers" )

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

function ConsiderQ()
    local bot = GetBot()
    
    if not abilityQ:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local daggerCastRange = abilityQ:GetCastRange()
    local daggerDamage = abilityQ:GetSpecialValueInt("base_damage") + abilityQ:GetSpecialValueInt("attack_factor_tooltip") / 100 * bot:GetAttackDamage()
    
    -- Try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, daggerCastRange)
	if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
		if utils.ValidTarget(WeakestEnemy) then
			if not modifiers.IsPhysicalImmune(WeakestEnemy) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(daggerDamage, DAMAGE_TYPE_PHYSICAL) then
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
				end
			end
		end
	end
    
    -- farming/laning
	if modeName == "jungling" or modeName == "laning" then
        if ManaPerc > 0.25 then
            -- in lane harass
            if utils.ValidTarget(WeakestEnemy) then
                if not modifiers.IsPhysicalImmune(WeakestEnemy) then
                    return BOT_ACTION_DESIRE_LOW, WeakestEnemy
                end
            end
            
            local eCreep = gHeroVar.GetNearbyEnemyCreep(bot, daggerCastRange)
            local weakestCreep, weakestCreepHealth = utils.GetWeakestCreep(eCreep)
            if utils.ValidTarget(weakestCreep) then
                local dist = GetUnitToUnitDistance(bot, weakestCreep)
                if dist > 1.25*AttackRange and 
                    weakestCreepHealth < weakestCreep:GetActualIncomingDamage(daggerDamage, DAMAGE_TYPE_PHYSICAL) then
                    return BOT_ACTION_DESIRE_LOW, weakestCreep
                end
            end
        end
    end
    
    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if modeName == "retreat" then
		local tableNearbyEnemyHeroes = gHeroVar.GetNearbyEnemies( bot, daggerCastRange )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes ) do
			if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
				if not modifiers.IsPhysicalImmune( npcEnemy ) then
					return BOT_ACTION_DESIRE_MODERATE, npcEnemy
				end
			end
		end
	end

	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
			if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderW()
    local bot = GetBot()
    
    if not abilityW:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local phantomStrikeCastRange = abilityW:GetCastRange()
    local totalAttackDamage = 4 * bot:GetAttackDamage() -- phantom_assassin_phantom_strike adds 4 very fast attacks

    -- Try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, phantomStrikeCastRange + 300)
	if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
		if utils.ValidTarget(WeakestEnemy) then
			if not modifiers.IsPhysicalImmune(WeakestEnemy) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(totalAttackDamage, DAMAGE_TYPE_PHYSICAL) then
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
				end
			end
		end
	end

    --phantom_assassin_phantom_strike to roshan
    if modeName == "roshan" then
        if GetUnitToLocationDistance(bot, utils.ROSHAN) < 600 then
            local eCreep = gHeroVar.GetNearbyEnemyCreep(bot, 600)
            local roshan = nil
            for _, creep in pairs(eCreep) do
                if creep:GetUnitName() == "npc_dota_roshan" then
                    roshan = creep
                    break
                end
            end
            if utils.ValidTarget(roshan) then
                return BOT_ACTION_DESIRE_LOW, roshan
            end
        end
    end

    --[[
    --phantom_assassin_phantom_strike to farm, pushlane, defendlane
    if (modeName == "jungling" and ManaPerc > 0.5) or
       (modeName == "defendlane" and ManaPerc > 0.3) or
       (modeName == "pushlane" and ManaPerc > 0.25) then
        local eCreep = gHeroVar.GetNearbyEnemyCreep(bot, phantomStrikeCastRange)
        table.sort(eCreep, function(n1,n2) return n1:GetHealth() > n2:GetHealth() end)
        if utils.ValidTarget(eCreep[1]) then
            return BOT_ACTION_DESIRE_LOW, eCreep[1]
        end
    end
    --]]
    
    -- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) and not modifiers.IsPhysicalImmune(npcEnemy) then
			return BOT_ACTION_DESIRE_MODERATE, npcEnemy
		end
	end
    
    --phantom_assassin_phantom_strike to escape
    if modeName == "retreat" or modeName == "shrine" then
        local nearAllies = gHeroVar.GetNearbyAllies(bot, phantomStrikeCastRange + 100)
        local nearAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, phantomStrikeCastRange + 100)
        local combinedList = { unpack(nearAllies), unpack(nearAlliedCreep) }
        if #combinedList > 0 then
            table.sort(combinedList, function(n1,n2) return n1:DistanceFromFountain() < n2:DistanceFromFountain() end)
            return BOT_ACTION_DESIRE_HIGH, combinedList[1]
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end


function genericAbility:AbilityUsageThink(bot)
    -- Check if we're already using an ability
    if utils.IsBusy(bot) then return true end

    -- Check to see if we are CC'ed
    if utils.IsUnableToCast(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( "phantom_assassin_stifling_dagger" ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( "phantom_assassin_phantom_strike" ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( "phantom_assassin_blur" ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( "phantom_assassin_coup_de_grace" ) end

    AttackRange   = bot:GetAttackRange() + bot:GetBoundingRadius()
    ManaPerc      = bot:GetMana()/bot:GetMaxMana()
	HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    -- WRITE CODE HERE --
    -- Consider using each ability
	local castQDesire, castQTarget  = ConsiderQ()
	local castWDesire, castWTarget  = ConsiderW()

    if castWDesire > 0 and castWDesire > castQDesire then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityW, castWTarget)
        local numAttacks = math.ceil(3/bot:GetSecondsPerAttack())
        for i = 1, numAttacks, 1 do
            gHeroVar.HeroQueueAttackUnit(bot, castWTarget, true)
        end
		return true
    end
    
    if castQDesire > 0 then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityQ, castQTarget)
		return true
    end
    
    return false
end

function genericAbility:nukeDamage( bot, enemy )
    if not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

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
    if not utils.ValidTarget(enemy) then return false end

    -- WRITE CODE HERE --

    return false
end

return genericAbility