-------------------------------------------------------------------------------
--- AUTHOR: Keithen, Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local bsAbility = BotsInit.CreateGeneric()

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

local bsTarget = nil

local Abilities = {
    "bloodseeker_bloodrage",
    "bloodseeker_blood_bath",
    "bloodseeker_thirst",
    "bloodseeker_rupture"
}

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

local modeName      = nil

function bsAbility:nukeDamage( bot, enemy )
    if enemy == nil or enemy:IsNull() then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 10000

    local magicImmune = utils.IsTargetMagicImmune(enemy)
    
    -- Check Rupture
    if abilityR:IsFullyCastable() then
        local manaCostR = abilityR:GetManaCost()
        if manaCostR <= manaAvailable then
            manaAvailable = manaAvailable - manaCostR
            dmgTotal = dmgTotal + 200  -- 200 pure damage every 1/4 second if moving
            castTime = castTime + abilityR:GetCastPoint()
            stunTime = stunTime + 12.0
            engageDist = Min(engageDist, abilityR:GetCastRange())
            table.insert(comboQueue, abilityR)
        end
    end

    -- Check Blood Bath
    if abilityW:IsFullyCastable() then
        local manaCostW = abilityW:GetManaCost()
        if manaCostW <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostW
                dmgTotal = dmgTotal + abilityW:GetSpecialValueInt("damage") -- damage is pure, silence is magic
                castTime = castTime + abilityW:GetCastPoint()
                engageDist = Min(engageDist, abilityW:GetCastRange())
                table.insert(comboQueue, 1, abilityW)
            end
        end
    end
    
    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end
    
function bsAbility:queueNuke(bot, enemy, castQueue, engageDist)
    local dist = GetUnitToUnitDistance(bot, enemy)

    -- if out of range, attack move for one hit to get in range
    if dist < engageDist then
        bot:Action_ClearActions(true)
        utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
        utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
        for i = #castQueue, 1, -1 do
            local skill = castQueue[i]

            if skill:GetName() == Abilities[2] then
                if utils.IsCrowdControlled(enemy) or modifiers.IsRuptured(enemy) then
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
                else
                    gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetExtrapolatedLocation(3.0))
                end
            elseif skill:GetName() == Abilities[4] then
                gHeroVar.HeroPushUseAbilityOnEntity(bot, skill, enemy)
            end
        end
        gHeroVar.HeroQueueAttackUnit( bot, enemy, false )
        bot:ActionQueue_Delay(0.01)
        return true
    end
    return false
end

function ComboDamage(bot, enemy)
    local dmg, castQueue, castTime, stunTime, slowTime, engageDist = bsAbility:nukeDamage( bot, enemy )

    dmg = dmg + fight_simul.estimateRightClickDamage( bot, enemy, 5.0 )

    return dmg
end

function ConsiderQ()
    local bot = GetBot()
    
    if not abilityQ:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end
    
    -- WRITE CODE HERE --
    
    -- If we're in a teamfight, use it on the scariest enemy
	local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1000)
	if #tableNearbyAttackingAlliedHeroes >= 2 then
        local targetCountTable = {}
		for _, ally in pairs(tableNearbyAttackingAlliedHeroes) do
            local allyTarget = gHeroVar.GetVar(ally:GetPlayerID(), "Target")
            if utils.ValidTarget(allyTarget) then
                local pos = utils.PosInTable(targetCountTable, allyTarget)
                if pos == -1 then
                    targetCountTable[allyTarget] = 1
                else
                    targetCountTable[allyTarget] = targetCountTable[allyTarget] + 1
                end
            end
            table.sort(targetCountTable)
            
            if #targetCountTable > 0 and utils.ValidTarget(targetCountTable[1])	then
                return BOT_ACTION_DESIRE_HIGH, targetCountTable[1]
            end
        end
	end
    
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
                if not roshan:HasModifier("modifier_bloodseeker_bloodrage") then
                    return BOT_ACTION_DESIRE_LOW, roshan
                end
            end
        end 
    end
    
    if modeName == "jungling" or modeName == "laning" or modeName == "pushlane" or modeName == "roshan" then
        if not bot:HasModifier("modifier_bloodseeker_bloodrage") and #gHeroVar.GetNearbyEnemyCreep(bot, 1200) > 0 then
            return BOT_ACTION_DESIRE_LOW, bot
        end
    end
    
    return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderW()
    local bot = GetBot()
    
    if not abilityW:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, {}
	end
    
    local CastRange = abilityW:GetCastRange()
    local Radius = 600
    local Delay = abilityW:GetSpecialValueFloat("delay_plus_castpoint_tooltip")
    
    -- Check for a channeling enemy
    local enemies = gHeroVar.GetNearbyEnemies(bot, 1600)
    
	for _, npcEnemy in pairs( enemies ) do
		if npcEnemy:IsChanneling() and not utils.IsTargetMagicImmune(npcEnemy) then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
		end
	end
    
    -- If we're in a teamfight, use it
	local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1600)
	if #tableNearbyAttackingAlliedHeroes >= 2 then
        local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), CastRange, Radius, Delay, 0 )
        if locationAoE.count >= 2 and GetUnitToLocationDistance(bot, locationAoE.targetloc) <= CastRange then
            return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
        end
    end
    
    -- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
			if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) and 
                GetUnitToUnitDistance(bot, npcEnemy) < (CastRange + 75*#gHeroVar.GetNearbyAllies(bot,1200)) then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetExtrapolatedLocation(Delay)
			end
		end
	end
    
    -- farming/laning
	if modeName == "jungling" or modeName == "laning" then		
        -- if we can hit 2+ enemies do it
		if abilityR:GetLevel() >= 1 and bot:GetMana() > abilityR:GetManaCost() then
			local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), CastRange, Radius, Delay, 0 )
			if locationAoE.count >= 2 and GetUnitToLocationDistance(bot, locationAoE.targetloc) <= CastRange then
				return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
			end
        else
            local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), CastRange, Radius, Delay, 0 )
			if locationAoE.count >= 2 and GetUnitToLocationDistance(bot, locationAoE.targetloc) <= CastRange then
				return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc
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
    
    -- If we're in a teamfight, use it on the scariest enemy
	local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1000)
	if #tableNearbyAttackingAlliedHeroes >= 2 then
		local npcMostDangerousEnemy = utils.GetScariestEnemy(bot, CastRange, true)

		if utils.ValidTarget(npcMostDangerousEnemy)	then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy
		end
	end
    
    --Try to kill enemy hero
    local WeakestEnemy, HeroHealth = utils.GetWeakestHero(bot, CastRange + 150)   
	if modeName ~= "retreat" then
		if utils.ValidTarget(WeakestEnemy) then
            local timeToKillRightClicking = fight_simul.estimateTimeToKill(bot, WeakestEnemy)
			if timeToKillRightClicking > 4.0 and not utils.IsCrowdControlled(WeakestEnemy) then
				if HeroHealth <= (fight_simul.estimateRightClickDamage( bot, WeakestEnemy, 12.0 ) + 200) then
                    setHeroVar("Target", WeakestEnemy)
					return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
				end
			end
		end
	end
    
    -- If we're going after someone
	if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
		local npcEnemy = getHeroVar("RoamTarget")
        if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

		if utils.ValidTarget(npcEnemy) then
            local timeToKillRightClicking = fight_simul.estimateTimeToKill(bot, npcEnemy)
            if timeToKillRightClicking > 4.0 and not utils.IsCrowdControlled(npcEnemy) and 
                GetUnitToUnitDistance(bot, npcEnemy) < CastRange then
                return BOT_ACTION_DESIRE_MODERATE, npcEnemy
            end
		end
	end
    
    return BOT_ACTION_DESIRE_NONE, nil
end

function bsAbility:AbilityUsageThink(bot)
    if utils.IsBusy(bot) then return true end
    
    if utils.IsCrowdControlled(bot) then return false end
    
    if abilityQ == "" then abilityQ = bot:GetAbilityByName( Abilities[1] ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( Abilities[2] ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( Abilities[3] ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( Abilities[4] ) end

    modeName      = bot.SelfRef:getCurrentMode():GetName()

    -- CHECK BELOW TO SEE WHICH ABILITIES ARE NOT PASSIVE AND WHAT RETURN TYPES ARE --
    -- Consider using each ability
	local castQDesire, castQTarget  = ConsiderQ()
	local castWDesire, castWLoc     = ConsiderW()
	local castRDesire, castRTarget  = ConsiderR()
    
    -- CHECK BELOW TO SEE WHAT PRIORITY OF ABILITIES YOU WANT FOR THIS HERO --
    if castWDesire > 0 then
		gHeroVar.HeroUseAbilityOnLocation(bot, abilityW, castWLoc)
		return true
	end
    
    if castRDesire > 0 then
		gHeroVar.HeroUseAbilityOnEntity(bot, abilityR, castRTarget)
		return true
	end

	if castQDesire > 0 then
		gHeroVar.HeroUseAbilityOnEntity(bot, abilityQ, castQTarget)
		return true
	end
    
    return false
end

return bsAbility
