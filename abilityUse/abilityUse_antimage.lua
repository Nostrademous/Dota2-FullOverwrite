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
    heroData.antimage.SKILL_0,
    heroData.antimage.SKILL_1,
    heroData.antimage.SKILL_2,
    heroData.antimage.SKILL_3
}

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

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end
    
    AttackRange   = bot:GetAttackRange()
	ManaPerc      = bot:GetMana()/bot:GetMaxMana()
	HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    local modeDesire    = Max(0.01, bot.SelfRef:getCurrentModeValue())
    
    -- CHECK BELOW TO SEE WHICH ABILITIES ARE NOT PASSIVE AND WHAT RETURN TYPES ARE --
    -- Consider using each ability
	local castWDesire, castWLoc     = ConsiderW()
	local castRDesire, castRTarget  = ConsiderR()
    
    -- CHECK BELOW TO SEE WHAT PRIORITY OF ABILITIES YOU WANT FOR THIS HERO --
    -- YOU MIGHT ALSO WANT TO ADD OTHER CONDITIONS TO WHEN TO CAST WHAT     --
    -- EXAMPLE: 
    -- if castRDesire >= modeDesire and castRDesire >= Max(CastEDesire, CastWDesire) then
    if castRDesire >= modeDesire and castRDesire > castWDesire then
		gHeroVar.HeroUseAbilityOnEntity(bot, abilityR, castRTarget)
		return true
	end
	
	if castWDesire >= modeDesire then
		gHeroVar.HeroUseAbilityOnLocation(bot, abilityW, castWLoc)
		return true
	end
    
    return false
end

function ConsiderW()
    local bot = GetBot()
    
    if not abilityW:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE
	end
    
    -- WRITE CODE HERE --

    end
    
    return BOT_ACTION_DESIRE_NONE
end

function ConsiderR()
    local bot = GetBot()
    
    if not abilityR:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end
    
    -- WRITE CODE HERE --
    -- Get some of its values
	local Radius = abilityR:GetSpecialValueInt( "mana_void_aoe_radius" )
	local DmgPerMana = abilityR:GetSpecialValueFloat( "mana_void_damage_per_mana" )
	local CastRange = abilityR:GetCastRange()
    
    --------------------------------------
	-- Global high-priorty usage
	--------------------------------------
    
    -- Do max damage in a team-fight
    local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1000)
	if #tableNearbyAttackingAlliedHeroes >= 2 then
		local enemies = gHeroVar.GetNearbyEnemies(bot, CastRange + 250)

        local bigManaDiffEnemy = nil
        local bigManaDiffDamage = 0
        for _, enemy in pairs(enemies) do
            if utils.ValidTarget(enemy) then
                if not utils.IsTargetMagicImmune(enemy) then
                    local manaDiff = enemy:GetMaxMana() - enemy:GetMana()
                    local soloDmg = manaDiff * DmgPerMana
                    
                    local enemiesInRadiusRangeOfTarget = gHeroVar.GetNearbyAllies(enemy, Radius)
                    
                    local totalDmg = #enemiesInRadiusRangeOfTarget * soloDmg
                    if bigManaDiffDamage < totalDmg then
                        bigManaDiffEnemy = enemy
                        bigManaDiffDamage = totalDmg
                    end
                end
            end
        end
        
		if utils.ValidTarget(bigManaDiffEnemy)	then
			return BOT_ACTION_DESIRE_HIGH, bigManaDiffEnemy
		end
	end
    
	-- Try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, 1200)
	if modeName ~= "retreat" or (modeName == "retreat" and bot.SelfRef:getCurrentModeValue() < BOT_MODE_DESIRE_VERYHIGH) then
		if utils.ValidTarget(WeakestEnemy) and GetUnitToUnitDistance(bot, WeakestEnemy) < (CastRange + 150) then
			if not utils.IsTargetMagicImmune(WeakestEnemy) and not utils.IsCrowdControlled(WeakestEnemy) then
                local Damage = (WeakestEnemy:GetMaxMana() - WeakestEnemy:GetMana())*DmgPerMana
				if HeroHealth <= WeakestEnemy:GetActualIncomingDamage(Damage, DAMAGE_TYPE_MAGICAL) then
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
				end
			end
		end
	end
    
    -- Check for a channeling enemy
    local enemies = gHeroVar.GetNearbyEnemies(bot, CastRange + 250)
    
	for _, npcEnemy in pairs( enemies ) do
		if utils.ValidTarget(npcEnemy) and npcEnemy:IsChanneling() and not utils.IsTargetMagicImmune(npcEnemy) then
            local myTarget = getHeroVar("Target")
            -- only use our ult if we are fighting the target, not simply because they are channeling
            if utils.ValidTarget(myTarget) and myTarget:GetPlayerID() == npcEnemy:GetPlayerID() then
                return BOT_ACTION_DESIRE_HIGH, npcEnemy
            end
		end
	end
    
    return BOT_ACTION_DESIRE_NONE, nil
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
    -- local physImmune = modifiers.IsPhysicalImmune(enemy)
    local magicImmune = utils.IsTargetMagicImmune(enemy)
    
    if abilityW:IsFullyCastable() then
        local manaCostW = abilityW:GetManaCost()
        if manaCostW <= manaAvailable then
            manaAvailable = manaAvailable - manaCostW
            --dmgTotal = dmgTotal + XYZ
            --castTime = castTime + abilityW:GetCastPoint()
            --stunTime = stunTime + XYZ
            --engageDist = Min(engageDist, abilityW:GetCastRange())
            table.insert(comboQueue, abilityW)
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
