-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local linaAbility = BotsInit.CreateGeneric()

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

local castLSADesire = 0
local castDSDesire  = 0
local castLBDesire  = 0

local ManaPerc      = 0.0
local modeName      = nil

function linaAbility:nukeDamage( bot, enemy )
    if not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 10000

    local magicImmune = utils.IsTargetMagicImmune(enemy)

    -- Check Laguna Blade
    if abilityR:IsFullyCastable() then
        local manaCostR = abilityR:GetManaCost()
        if manaCostR <= manaAvailable then
            if bot:HasScepter() then
                manaAvailable = manaAvailable - manaCostR
                dmgTotal = dmgTotal + abilityR:GetAbilityDamage()
                castTime = castTime + abilityR:GetCastPoint()
                engageDist = Min(engageDist, abilityR:GetCastRange())
                table.insert(comboQueue, abilityR)
            else
                if not magicImmune then
                    manaAvailable = manaAvailable - manaCostR
                    dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(abilityR:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
                    castTime = castTime + abilityR:GetCastPoint()
                    engageDist = Min(engageDist, abilityR:GetCastRange())
                    table.insert(comboQueue, abilityR)
                end
            end
        end
    end

    -- Check Dragon Slave
    if abilityQ:IsFullyCastable() then
        local manaCostQ = abilityQ:GetManaCost()
        if manaCostQ <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostQ
                dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(abilityQ:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
                castTime = castTime + abilityQ:GetCastPoint()
                engageDist = Min(engageDist, abilityQ:GetCastRange())
                table.insert(comboQueue, 1, abilityQ)
            end
        end
    end

    -- Check Light Strike Array
    if abilityW:IsFullyCastable() then
        local manaCostW = abilityW:GetManaCost()
        if manaCostW <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostW
                dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(abilityW:GetAbilityDamage(), DAMAGE_TYPE_MAGICAL)
                castTime = castTime + abilityW:GetCastPoint()
                stunTime = stunTime + abilityW:GetSpecialValueFloat("light_strike_array_stun_duration")
                engageDist = Min(engageDist, abilityW:GetCastRange())
                table.insert(comboQueue, 1, abilityW)
                
                -- using Eul's only makes sense if we can LSA too
                local euls = utils.IsItemAvailable("item_cyclone")
                if euls then
                    local manaCostEuls = euls:GetManaCost()
                    if manaCostEuls <= manaAvailable then
                        manaAvailable = manaAvailable - manaCostW
                        dmgTotal = dmgTotal + 50
                        engageDist = 575
                        table.insert(comboQueue, 1, euls)
                    end
                end
            end
        end
    end

    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function linaAbility:queueNuke(bot, enemy, castQueue, engageDist)
    if not utils.ValidTarget(enemy) then return false end
    
    local dist = GetUnitToUnitDistance(bot, enemy)

    -- if out of range, attack move for one hit to get in range
    if dist < engageDist then
        bot:Action_ClearActions(false)
        utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
        utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
        for i = #castQueue, 1, -1 do
            local skill = castQueue[i]
            local behaviorFlag = skill:GetBehavior()

            --utils.myPrint(" - skill '", skill:GetName(), "' has BehaviorFlag: ", behaviorFlag)

            if skill:GetName() == "lina_light_strike_array" then
                if enemy:HasModifier("modifier_eul_cyclone") then
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
                    bot:ActionPush_Delay(modifiers.GetModifierRemainingDuration(enemy, "modifier_eul_cyclone") - .95)
                elseif utils.IsCrowdControlled(enemy) then
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
                else
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, utils.PredictPosition(enemy, 0.95))
                end
            elseif skill:GetName() == "lina_dragon_slave" then
                if enemy:HasModifier("modifier_eul_cyclone") then
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
                    bot:ActionPush_Delay(modifiers.GetModifierRemainingDuration(enemy, "modifier_eul_cyclone") - (0.45 + dist/1200))
                elseif utils.IsCrowdControlled(enemy) then
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
                else
                    -- account for 0.45 cast point and speed of wave (1200) needed to travel the distance between us
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, utils.PredictPosition(enemy, 0.45 + dist/1200))
                end
            elseif skill:GetName() == "lina_laguna_blade" then
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            elseif skill:GetName() == "item_cyclone" then
                bot:ActionPush_Delay(0.35)
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            end
        end
        return true
    end
    return false
end

function linaAbility:AbilityUsageThink(bot)
    -- Check if we're already using an ability
    if utils.IsBusy(bot) then return true end
    
    if utils.IsUnableToCast(bot) then return false end
    
    if abilityQ == "" then abilityQ = bot:GetAbilityByName( "lina_dragon_slave" ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( "lina_light_strike_array" ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( "lina_fiery_soul" ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( "lina_laguna_blade" ) end
    
    local nearbyEnemyHeroes = gHeroVar.GetNearbyEnemies(bot, 1200)
    local nearbyEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)
    
    if #nearbyEnemyHeroes == 0 and #nearbyEnemyCreep == 0 then return false end

    if #nearbyEnemyHeroes == 1 and nearbyEnemyHeroes[1]:GetHealth() > 0 then
        local enemy = nearbyEnemyHeroes[1]
        local dmg, castQueue, castTime, stunTime, slowTime, engageDist = self:nukeDamage( bot, enemy )

        local rightClickTime = stunTime + 0.5*slowTime
        if rightClickTime > 0.5 then
            dmg = dmg + fight_simul.estimateRightClickDamage( bot, enemy, rightClickTime )
        end

        -- magic immunity is already accounted for by nukeDamage()
        if utils.ValidTarget(enemy) and dmg > enemy:GetHealth() then
            local bKill = self:queueNuke(bot, enemy, castQueue, engageDist)
            if bKill then
                setHeroVar("Target", enemy)
                return true
            end
        end
    end

    ManaPerc      = bot:GetMana()/bot:GetMaxMana()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    local modeDesire = Max(0.01, bot.SelfRef:getCurrentModeValue())
    
    -- Consider using each ability
	local castQDesire, castQLocation  = ConsiderQ()
	local castWDesire, castWLocation  = ConsiderW()
	local castRDesire, castRTarget    = ConsiderR()
    
    if castQDesire >= modeDesire and castQDesire >= castWDesire and castQDesire >= castRDesire then
        gHeroVar.HeroUseAbilityOnLocation( bot, abilityQ, castQLocation )
        return true
    end
    
    if castWDesire >= modeDesire and castWDesire >= castRDesire then
        gHeroVar.HeroUseAbilityOnLocation( bot, abilityW, castWLocation )
        return true
    end
    
    if castRDesire >= modeDesire then
        gHeroVar.HeroUseAbilityOnEntity( bot, abilityR, castRTarget )
        return true
    end
    
    return false
end

function ConsiderQ()
    local bot = GetBot()
    
    if not abilityQ:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end
    
    -- Get some of its values
    local Radius    = abilityQ:GetSpecialValueInt( "dragon_slave_width_end" )
    local CastRange = abilityQ:GetCastRange()
    local Damage    = abilityQ:GetAbilityDamage()
    
    -- Try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange + Radius + 150)
	if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
		if utils.ValidTarget(WeakestEnemy) then
			if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
                    local d = GetUnitToUnitDistance(bot, WeakestEnemy)
					return BOT_ACTION_DESIRE_HIGH, utils.PredictPosition(WeakestEnemy, 0.45 + d/1200 + getHeroVar("AbilityDelay"))
				end
			end
		end
	end
    
    -- If we're in a teamfight
	local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1000)
	if #tableNearbyAttackingAlliedHeroes >= 2 then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), CastRange, Radius, 0.45 + getHeroVar("AbilityDelay"), 0 )
        if locationAoE.count >= 2 then
            return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc
        end
	end

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    -- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
            local d = GetUnitToUnitDistance(bot, npcEnemy)
			if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) and 
                d < (CastRange + 75*#gHeroVar.GetNearbyAllies(bot,1200)) then
				return BOT_ACTION_DESIRE_HIGH, utils.PredictPosition(npcEnemy, 0.45 + d/1200 + getHeroVar("AbilityDelay"))
			end
		end
	end
    
    -- If we're farming and can kill 3+ creeps
    if modeName == "jungling" or modeName == "laning" then
        if ManaPerc > 0.4 then
            local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0.45 + getHeroVar("AbilityDelay"), Damage )
            if locationAoE.count >= 3 then
                return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
            end
        end
    end

    -- If we're pushing or defending a lane and can hit 3+ creeps, go for it
    if modeName == "pushlane" or (modeName == "defendlane" and ManaPerc > 0.4) then
        local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0.45 + getHeroVar("AbilityDelay"), 0 )
        if locationAoE.count >= 3 then
            return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc
        end
        
        -- if we want to maintain max fiery soul stacks and have mana
        local fierySoulTimeRemaining = modifiers.GetModifierRemainingDuration(bot, "lina_fiery_soul")
        if fierySoulTimeRemaining > 0.45 and fierySoulTimeRemaining < 0.9 then
            return BOT_ACTION_DESIRE_MODERATE, bot:GetLocation() + RandomVector(RandomInt(10, 50))
        end
    end
    
    return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderW()
    local bot = GetBot()
    
    if not abilityW:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end


    -- Get some of its values
    local Radius    = abilityW:GetSpecialValueInt( "light_strike_array_aoe" )
    local CastRange = abilityW:GetCastRange()
    local Damage    = abilityW:GetAbilityDamage()

    --------------------------------------
    -- Global high-priorty usage
    --------------------------------------

    -- Check for a channeling enemy
    local enemies = gHeroVar.GetNearbyEnemies(bot, CastRange + Radius + 200 )
    for _, npcEnemy in pairs( enemies ) do
        if utils.ValidTarget(npcEnemy) and npcEnemy:IsChanneling() then
            if not utils.IsTargetMagicImmune( npcEnemy ) then
                return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
            end
        end
    end
    
    -- Try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange + Radius + 150)
	if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
		if utils.ValidTarget(WeakestEnemy) then
			if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
					return BOT_ACTION_DESIRE_HIGH, utils.PredictPosition(WeakestEnemy, 0.95 + getHeroVar("AbilityDelay"))
				end
			end
		end
	end

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    -- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
			if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) and 
                GetUnitToUnitDistance(bot, npcEnemy) < (CastRange + 75*#gHeroVar.GetNearbyAllies(bot,1200)) then
				return BOT_ACTION_DESIRE_HIGH, utils.PredictPosition(npcEnemy, 0.95 + getHeroVar("AbilityDelay"))
			end
		end
	end
    
    -- If we're farming and can kill 3+ creeps with LSA
    if modeName == "jungling" or modeName == "laning" then
        if ManaPerc > 0.4 then
            local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0.95 + getHeroVar("AbilityDelay"), Damage )
            if locationAoE.count >= 3 then
                return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
            end
        end
    end

    if modeName == "pushlane" or (modeName == "defendlane" and ManaPerc > 0.4) then
        local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), CastRange, Radius, 0.95 + getHeroVar("AbilityDelay"), 0 )
        if locationAoE.count >= 3 then
            return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
        end
        
        -- if we want to maintain max fiery soul stacks and have mana
        local fierySoulTimeRemaining = modifiers.GetModifierRemainingDuration(bot, "lina_fiery_soul")
        if fierySoulTimeRemaining > 0.95 and fierySoulTimeRemaining < 1.5 then
            return BOT_ACTION_DESIRE_MODERATE, bot:GetLocation() + RandomVector(RandomInt(10, 50))
        end
    end

    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
    if modeName == "retreat" or modeName == "shrine" then
        local tableNearbyEnemyHeroes = gHeroVar.GetNearbyEnemies( bot, CastRange )
        for _, npcEnemy in pairs( tableNearbyEnemyHeroes ) do
            if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
				if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) then
					return BOT_ACTION_DESIRE_HIGH, utils.PredictPosition(npcEnemy, 0.95 + getHeroVar("AbilityDelay"))
				end
			end
        end
    end

    return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderR()
    local bot = GetBot()

    -- Make sure it's castable
    if not abilityR:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    -- Get some of its values
    local CastRange     = abilityR:GetCastRange()
    local Damage        = abilityR:GetSpecialValueInt( "damage" )
    local DamageType    = DAMAGE_TYPE_MAGICAL
    if bot:HasScepter() then
        DamageType      = DAMAGE_TYPE_PURE
    end

    -- kill people
    if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
        local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange + 150)
        if utils.ValidTarget(WeakestEnemy) then
            if DamageType == DAMAGE_TYPE_MAGICAL then
                if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
                    if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
                        return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
                    end
                end
            else
                if not utils.IsCrowdControlled(WeakestEnemy) then
                    if HeroHealth <= Damage then
                        return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
                    end
                end
            end
        end
    end
    
    -- If we're in a teamfight, use it on the scariest enemy
	local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1000)
	if #tableNearbyAttackingAlliedHeroes >= 2 then
		local npcMostDangerousEnemy = utils.GetScariestEnemy(bot, CastRange, true)

		if utils.ValidTarget(npcMostDangerousEnemy)	then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

return linaAbility