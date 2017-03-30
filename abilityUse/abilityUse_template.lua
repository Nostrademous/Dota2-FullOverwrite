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

local AttackRange   = 0
local ManaPerc      = 0.0
local HealthPerc    = 0.0
local modeName      = nil

function genericAbility:AbilityUsageThink(bot)
    -- Check if we're already using an ability
    if utils.IsBusy(bot) then return true end
    
    -- Check to see if we are CC'ed
    if utils.IsUnableToCast(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( "FILL ME OUT" ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( "FILL ME OUT" ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( "FILL ME OUT" ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( "FILL ME OUT" ) end
    
    AttackRange   = bot:GetAttackRange()
	ManaPerc      = bot:GetMana()/bot:GetMaxMana()
	HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    local modeDesire    = Max(0.01, bot.SelfRef:getCurrentModeValue())
    
    -- CHECK BELOW TO SEE WHICH ABILITIES ARE NOT PASSIVE AND WHAT RETURN TYPES ARE --
    -- Consider using each ability
	local castQDesire, castQTarget  = ConsiderQ()
	local castWDesire               = ConsiderW()
    local castEDesire, castELoc     = ConsiderE()
	local castRDesire, castRTarget  = ConsiderR()
    
    -- CHECK BELOW TO SEE WHAT PRIORITY OF ABILITIES YOU WANT FOR THIS HERO --
    -- YOU MIGHT ALSO WANT TO ADD OTHER CONDITIONS TO WHEN TO CAST WHAT     --
    -- EXAMPLE: 
    -- if castRDesire >= modeDesire and castRDesire >= Max(CastEDesire, CastWDesire) then
    if castRDesire >= modeDesire then
		gHeroVar.HeroUseAbilityOnEntity(bot, abilityR, castRTarget)
		return true
	end
    
    if castEDesire >= modeDesire then
		gHeroVar.HeroUseAbilityOnLocation(bot, abilityE, castELoc)
		return true
	end
	
	if castWDesire >= modeDesire then
		gHeroVar.HeroUseAbility(bot, abilityW)
		return true
	end

	if castQDesire >= modeDesire then
		gHeroVar.HeroUseAbilityOnEntity(bot, abilityQ, castQTarget)
		return true
	end
    
    return false
end

function ConsiderQ()
    local bot = GetBot()
    
    if not abilityQ:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end
    
    -- WRITE CODE HERE --
    
    return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderW()
    local bot = GetBot()
    
    if not abilityW:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE
	end
    
    -- WRITE CODE HERE --
    
    return BOT_ACTION_DESIRE_NONE
end

function ConsiderE()
    local bot = GetBot()
    
    if not abilityE:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE
	end
    
    -- WRITE CODE HERE --
    
    return BOT_ACTION_DESIRE_NONE
end

function ConsiderR()
    local bot = GetBot()
    
    if not abilityR:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end
    
    -- WRITE CODE HERE --
    
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
    -- local magicImmune = utils.IsTargetMagicImmune(enemy)
    
    if abilityQ:IsFullyCastable() then
    local manaCostQ = abilityQ:GetManaCost()
        if manaCostQ <= manaAvailable then
            manaAvailable = manaAvailable - manaCostQ
            --dmgTotal = dmgTotal + XYZ
            --castTime = castTime + abilityQ:GetCastPoint()
            --stunTime = stunTime + XYZ
            --engageDist = Min(engageDist, abilityQ:GetCastRange())
            table.insert(comboQueue, abilityQ)
        end
    end
    
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
    
    if abilityE:IsFullyCastable() then
        local manaCostE = abilityE:GetManaCost()
        if manaCostE <= manaAvailable then
            manaAvailable = manaAvailable - manaCostE
            --dmgTotal = dmgTotal + XYZ
            --castTime = castTime + abilityE:GetCastPoint()
            --stunTime = stunTime + XYZ
            --engageDist = Min(engageDist, abilityE:GetCastRange())
            table.insert(comboQueue, abilityE)
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
