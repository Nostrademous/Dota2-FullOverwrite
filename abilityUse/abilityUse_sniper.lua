-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local genericAbility = BotsInit.CreateGeneric()

local heroData = require( GetScriptDirectory().."/hero_data" )
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

local Abilities = {
    heroData.sniper.SKILL_0,
    heroData.sniper.SKILL_1,
    heroData.sniper.SKILL_2,
    heroData.sniper.SKILL_3
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

local AttackRange   = 0
local ManaPerc      = 0.0
local HealthPerc    = 0.0
local modeName      = nil

local shrapnelLoc = {}

local function UpdateShrapnelLocTable()
    if #shrapnelLoc == 0 then return end
    
    for indx, entry in pairs(shrapnelLoc) do
        if (GameTime() - entry[1]) >= 10.0 then
            table.remove(shrapnelLoc, indx)
            return
        end
    end
end

local function IsValidShrapnelLoc( loc, radius )
    if #shrapnelLoc == 0 then return true end
    
    for _, entry in pairs(shrapnelLoc) do
        if utils.GetDistance(entry[2], loc) < radius then
            return false
        end
    end
    return true
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
    
    AttackRange   = bot:GetAttackRange()
	ManaPerc      = bot:GetMana()/bot:GetMaxMana()
	HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    local modeDesire    = Max(0.01, bot.SelfRef:getCurrentModeValue())
    
    -- remove shrpanel vectors that have expired
    -- only need to remove 1 per frame, as you can't shoot off more than 1 per frame
    UpdateShrapnelLocTable()
    
    -- CHECK BELOW TO SEE WHICH ABILITIES ARE NOT PASSIVE AND WHAT RETURN TYPES ARE --
    -- Consider using each ability
	local castQDesire, castQLoc     = ConsiderQ()
	local castRDesire, castRTarget  = ConsiderR()
    
    -- CHECK BELOW TO SEE WHAT PRIORITY OF ABILITIES YOU WANT FOR THIS HERO --
    -- YOU MIGHT ALSO WANT TO ADD OTHER CONDITIONS TO WHEN TO CAST WHAT     --
    -- EXAMPLE: 
    -- if castRDesire >= modeDesire and castRDesire >= Max(CastEDesire, CastWDesire) then
    if castRDesire >= modeDesire and castRDesire > castQDesire then
		gHeroVar.HeroUseAbilityOnEntity(bot, abilityR, castRTarget)
		return true
	end

	if castQDesire >= modeDesire then
        if IsValidShrapnelLoc( castQLoc, 450 ) then
            table.insert(shrapnelLoc, {GameTime(), castQLoc})
            gHeroVar.HeroUseAbilityOnLocation(bot, abilityQ, castQLoc)
            return true
        end
	end
    
    return false
end

-- This function calculate the amount of Shrapnel Damage done to enemy hero assuming 
-- we start the AOE centered on him and he immediately starts walking away when it becomes visible
local function CalculateShrapnelDamage( hBot, hEnemyUnit, aoeRadius, shrapnelDmg, numCharges )
    if not utils.ValidTarget(hEnemyUnit) then return 0 end
    
    local moveSpeedSlow = abilityQ:GetSpecialValueInt("slow_movement_speed")/100.0 -- this will be a negative percentage
    local enemySpeedInAoE = hEnemyUnit:GetCurrentMovementSpeed() * (1 + moveSpeedSlow) -- plus b/c it's negative
    local dmg = (aoeRadius/enemySpeedInAoE) * shrapnelDmg * numCharges
    return hEnemyUnit:GetActualIncomingDamage(dmg, DAMAGE_TYPE_MAGICAL)
end

function ConsiderQ()
    local bot = GetBot()
    
    if not abilityQ:IsFullyCastable() or abilityQ:GetCurrentCharges() == 0 then
		return BOT_ACTION_DESIRE_NONE, {}
	end
    
    -- WRITE CODE HERE --
    local CastRange = abilityQ:GetCastRange()
    local CastPoint = abilityQ:GetCastPoint() + abilityQ:GetSpecialValueFloat( "damage_delay" )
    local Radius = abilityQ:GetSpecialValueInt( "radius" )
    local Damage = abilityQ:GetSpecialValueInt( "shrapnel_damage" )
    
    local hasTalent = bot:GetAbilityByName(heroData.sniper.TALENT_2):GetLevel() >= 1
    if hasTalent then Damage = Damage + 20 end
    
    local numCharges = abilityQ:GetCurrentCharges()
    
    -- TODO: Implement use for Vision
    
    --------------------------------------
	-- Global high-priorty usage
	--------------------------------------
	--try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange, GetUnitList(UNIT_LIST_ENEMY_HEROES))
    
	if modeName ~= "retreat" then
		if utils.ValidTarget(WeakestEnemy) then
			if not utils.IsTargetMagicImmune( WeakestEnemy ) then            
				if HeroHealth <= CalculateShrapnelDamage( bot, WeakestEnemy, Radius, Damage, numCharges ) then
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy:GetExtrapolatedLocation(CastPoint + 0.25)
				end
			end
		end
	end
    
    --------------------------------------
	-- Mode based usage
	--------------------------------------
    -- fighting (team fight) and can hit 2+ enemies
	if modeName == "fight" then
        local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), 1300, Radius, CastPoint, 0 )
        if locationAoE.count >= 2 then
            return BOT_ACTION_DESIRE_HIGH+0.01, locationAoE.targetloc
        end
	end
	
	-- If we're pushing or defending a lane
	if modeName == "defendlane" or modeName == "pushlane" then
		if ManaPerc > 0.4 and numCharges > 1 then
            -- if we can hit 4+ creeps, go for it
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), 1300, Radius, CastPoint, 0 )
			if locationAoE.count >= 4 then
				return BOT_ACTION_DESIRE_MODERATE+0.01, locationAoE.targetloc
			end
            
            -- if we can hit 2+ heroes, go for it
            local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), 1300, Radius, CastPoint, 0 )
			if locationAoE.count >= 2 then
				return BOT_ACTION_DESIRE_MODERATE+0.01, locationAoE.targetloc
			end
		end
    end
    
	-- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then           
			if not utils.IsTargetMagicImmune(npcEnemy) and GetUnitToUnitDistance(bot, npcEnemy) < CastRange then
                if HeroHealth <= CalculateShrapnelDamage( bot, npcEnemy, Radius, Damage, numCharges ) then
                    return BOT_ACTION_DESIRE_MODERATE+0.01, npcEnemy:GetExtrapolatedLocation(CastPoint + 0.25)
                end
			end
		end
	end
    
    return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderR()
    local bot = GetBot()
    
    if not abilityR:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end
    
    -- WRITE CODE HERE --
    local CastRange = abilityR:GetCastRange()
    local Damage = abilityR:GetAbilityDamage()
     
    --try to kill enemy hero
    if not bot:HasScepter() then
        if modeName ~= "retreat" or #gHeroVar.GetNearbyEnemies( bot, 1500 ) == 0 then
            local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES)
            local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange, enemies)
            
            if utils.ValidTarget(WeakestEnemy) then
                if not utils.IsTargetMagicImmune(WeakestEnemy) then
                    if HeroHealth < WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
                        return BOT_ACTION_DESIRE_VERYHIGH+0.01, WeakestEnemy
                    end
                end
            end
        end
    else
        if modeName ~= "retreat" or #gHeroVar.GetNearbyEnemies( bot, 1500 ) == 0 then
            local Radius = abilityR:GetSpecialValueInt( "scepter_radius" )
            local CritMultiplier = abilityR:GetSpecialValueInt( "scepter_crit_bonus" )/100.0
            -- TODO: Technically the kills are not guaranteed as I don't think FindAoELocation takes armor/magic-resistance into consideration
            -- NOTE: Aghs Assassinate is PHYSICAL DAMAGE
            local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), CastRange, Radius, abilityR:GetCastPoint(), CritMultiplier*Damage )
            if locationAoE.count >= 1 then
				return BOT_ACTION_DESIRE_VERYHIGH+0.01, locationAoE.targetloc
			end
        end
    end
    
    return BOT_ACTION_DESIRE_NONE, nil
end

function CalcRightClickDmg(bot, target)
    if not utils.ValidTarget(target) then return 0 end
    
    local bonusDmg = 0
    if abilityW:GetLevel() > 0 then
        bonusDmg = abilityW:GetAbilityDamage()
    end

    local rightClickDmg = bot:GetAttackDamage() + bonusDmg * 0.4 -- 40% proc chance
    local actualDmg = target:GetActualIncomingDamage(rightClickDmg, DAMAGE_TYPE_PHYSICAL)
    return actualDmg
end

function genericAbility:nukeDamage( bot, enemy )
    if not utils.ValidTarget(enemy) then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = bot:GetOffensivePower() + 1.0 * CalcRightClickDmg(bot, enemy)
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 500
    
    -- WRITE CODE HERE --
    -- local physImmune = modifiers.IsPhysicalImmune(enemy)
    local magicImmune = utils.IsTargetMagicImmune(enemy)
    
    if abilityQ:IsFullyCastable() then
    local manaCostQ = abilityQ:GetManaCost()
        if manaCostQ <= manaAvailable then
            manaAvailable = manaAvailable - manaCostQ
            --dmgTotal = dmgTotal + XYZ
            --castTime = castTime + abilityQ:GetCastPoint()
            --stunTime = stunTime + XYZ
            engageDist = Min(engageDist, abilityQ:GetCastRange())
            table.insert(comboQueue, abilityQ)
        end
    end
    
    if abilityR:IsFullyCastable() then
        local manaCostR = abilityR:GetManaCost()
        if manaCostR <= manaAvailable then
            manaAvailable = manaAvailable - manaCostR
            --dmgTotal = dmgTotal + 200  -- 200 pure damage every 1/4 second if moving
            --castTime = castTime + abilityR:GetCastPoint()
            --stunTime = stunTime + 12.0
            --engageDist = Min(engageDist, abilityR:GetCastRange())
            table.insert(comboQueue, abilityR)
        end
    end
    
    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function genericAbility:queueNuke(bot, enemy, castQueue, engageDist)
    if not utils.ValidTarget(enemy) then return false end
    
    -- WRITE CODE HERE --
    
    return false
end

return genericAbility
