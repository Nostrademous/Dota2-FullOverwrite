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
    if utils.IsCrowdControlled(bot) or bot:IsSilenced() then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( "FILL ME OUT" ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( "FILL ME OUT" ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( "FILL ME OUT" ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( "FILL ME OUT" ) end
    
    AttackRange   = bot:GetAttackRange()
	ManaPerc      = bot:GetMana()/bot:GetMaxMana()
	HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    modeName      = bot.SelfRef:getCurrentMode():GetName()
    
    -- CHECK BELOW TO SEE WHICH ABILITIES ARE NOT PASSIVE AND WHAT RETURN TYPES ARE --
    -- Consider using each ability
	local castQDesire, castQTarget  = ConsiderQ()
	local castWDesire               = ConsiderW()
    local castEDesire, castELoc     = ConsiderE()
	local castRDesire, castRTarget  = ConsiderR()
    
    -- CHECK BELOW TO SEE WHAT PRIORITY OF ABILITIES YOU WANT FOR THIS HERO --
    if castRDesire > 0 then
		gHeroVar.HeroUseAbilityOnEntity(bot, abilityR, castRTarget)
		return true
	end
    
    if castEDesire > 0 then
		gHeroVar.HeroUseAbilityOnLocation(bot, abilityE, castELoc)
		return true
	end
	
	if castWDesire > 0 then
		gHeroVar.HeroUseAbility(bot, abilityW)
		return true
	end

	if castQDesire > 0 then
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
