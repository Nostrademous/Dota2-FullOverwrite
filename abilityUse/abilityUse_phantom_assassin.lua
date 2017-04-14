-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local genericAbility = BotsInit.CreateGeneric()

local heroData = require( GetScriptDirectory().."/hero_data" )
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

local Abilities = {
    heroData.phantom_assassin.SKILL_0,
    heroData.phantom_assassin.SKILL_1,
    heroData.phantom_assassin.SKILL_2,
    heroData.phantom_assassin.SKILL_3
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

local AvgCritMult   = 0.0
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
    daggerDamage = daggerDamage * AvgCritMult
    
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
        if ManaPerc > 0.5 then            
            local eCreep = gHeroVar.GetNearbyEnemyCreep(bot, daggerCastRange)
            local weakestCreep, weakestCreepHealth = utils.GetWeakestCreep(eCreep)
            if utils.ValidTarget(weakestCreep) then
                local dist = GetUnitToUnitDistance(bot, weakestCreep)
                if dist > 1.25*AttackRange and 
                    weakestCreepHealth < weakestCreep:GetActualIncomingDamage(daggerDamage, DAMAGE_TYPE_PHYSICAL) then
                    return BOT_ACTION_DESIRE_LOW, weakestCreep
                end
            end
            
            -- in lane harass
            if utils.ValidTarget(WeakestEnemy) and weakestCreepHealth > 150 then
                if not modifiers.IsPhysicalImmune(WeakestEnemy) then
                    return BOT_ACTION_DESIRE_LOW, WeakestEnemy
                end
            end
        end
    end
    
    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if modeName == "retreat" then
		local tableNearbyEnemyHeroes = gHeroVar.GetNearbyEnemies( bot, daggerCastRange )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes ) do
			if utils.ValidTarget(npcEnemy) and bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
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
    -- phantom_assassin_phantom_strike adds 4 very fast attacks
    local totalAttackDamage = 4 * bot:GetAttackDamage() * AvgCritMult

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
                if utils.ValidTarget(creep) and creep:GetUnitName() == "npc_dota_roshan" then
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
            return BOT_ACTION_DESIRE_VERYHIGH, combinedList[1]
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end


function genericAbility:AbilityUsageThink(bot)
    -- Check if we're already using an ability
    if utils.IsBusy(bot) then return true end

    -- Check to see if we are CC'ed
    if utils.IsUnableToCast(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    AttackRange   = bot:GetAttackRange() + bot:GetBoundingRadius()
    ManaPerc      = bot:GetMana()/bot:GetMaxMana()
	HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    local modeDesire = Max(0.01, bot.SelfRef:getCurrentModeValue())
    
    local critChance = 0.0
    local critDmg = 0.0
    if abilityR:GetLevel() >= 1 then
        critChance = 0.15
        critDmg = abilityR:GetSpecialValueInt("crit_chance")/100.0
    end
    AvgCritMult = (1 + critChance * critDmg)
    
    -- WRITE CODE HERE --
    local nearbyEnemyHeroes = gHeroVar.GetNearbyEnemies(bot, 1200)
    local nearbyEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)
    
    if #nearbyEnemyHeroes == 0 and #nearbyEnemyCreep == 0 then return false end

    if #nearbyEnemyHeroes == 1 and nearbyEnemyHeroes[1]:GetHealth() > 0 then
        local enemy = nearbyEnemyHeroes[1]
        local dmg, castQueue, castTime, stunTime, slowTime, engageDist = self:nukeDamage( bot, enemy )

        local rightClickTime = stunTime + 0.5*slowTime
        if rightClickTime > 0.5 then
            dmg = dmg + fight_simul.estimateRightClickDamage( bot, enemy, rightClickTime ) * AvgCritMult
        end

        -- magic/physical immunity is already accounted for by nukeDamage()
        if utils.ValidTarget(enemy) and dmg > enemy:GetHealth() then
            local bKill = self:queueNuke(bot, enemy, castQueue, engageDist)
            if bKill then
                setHeroVar("Target", enemy)
                return true
            end
        end
    end
    
    -- Consider using each ability
	local castQDesire, castQTarget  = ConsiderQ()
	local castWDesire, castWTarget  = ConsiderW()

    if castWDesire >= modeDesire and castWDesire >= castQDesire then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityW, castWTarget)
        local numAttacks = math.ceil(3/bot:GetSecondsPerAttack())
        for i = 1, numAttacks, 1 do
            gHeroVar.HeroQueueAttackUnit(bot, castWTarget, true)
        end
		return true
    end
    
    if castQDesire >= modeDesire then
        gHeroVar.HeroUseAbilityOnEntity(bot, abilityQ, castQTarget)
		return true
    end
    
    return false
end

function genericAbility:nukeDamage( bot, enemy )
    if not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = bot:GetOffensivePower()
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 0

    -- WRITE CODE HERE --
    local physImmune = modifiers.IsPhysicalImmune(enemy)
    --local magicImmune = utils.IsTargetMagicImmune(enemy)
    
    if abilityQ:IsFullyCastable() then
    local manaCostQ = abilityQ:GetManaCost()
        if manaCostQ <= manaAvailable then
            if not physImmune then
                manaAvailable = manaAvailable - manaCostQ
                local damageQ = abilityQ:GetSpecialValueInt("base_damage") + abilityQ:GetSpecialValueInt("attack_factor_tooltip") / 100 * bot:GetAttackDamage()
                dmgTotal = dmgTotal + damageQ*AvgCritMult
                castTime = castTime + abilityQ:GetCastPoint()
                slowTime = slowTime + abilityQ:GetDuration()
                engageDist = Min(engageDist, abilityQ:GetCastRange())
                table.insert(comboQueue, abilityQ)
            end
        end
    end
    
    if abilityW:IsFullyCastable() then
        local manaCostW = abilityW:GetManaCost()
        if manaCostW <= manaAvailable then
            if not physImmune then
                manaAvailable = manaAvailable - manaCostW
                dmgTotal = dmgTotal + 4*bot:GetAttackDamage()*AvgCritMult
                castTime = castTime + abilityW:GetCastPoint()
                engageDist = Min(engageDist, abilityW:GetCastRange())
                table.insert(comboQueue, abilityW)
            end
        end
    end

    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function genericAbility:queueNuke(bot, enemy, castQueue, engageDist)
    if not utils.ValidTarget(enemy) then return false end

    -- WRITE CODE HERE --
    local dist = GetUnitToUnitDistance(bot, enemy)

    -- if out of range, attack move for one hit to get in range
    if dist < engageDist then
        bot:Action_ClearActions(true)
        utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
        utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
        for i = #castQueue, 1, -1 do
            local skill = castQueue[i]

            if skill:GetName() == "phantom_assassin_stifling_dagger" then
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            elseif skill:GetName() == "phantom_assassin_phantom_strike" then
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            end
        end
        gHeroVar.HeroQueueAttackUnit( bot, enemy, false )
        bot:ActionQueue_Delay(0.01)
        return true
    end

    return false
end

return genericAbility