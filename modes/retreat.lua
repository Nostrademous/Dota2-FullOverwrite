-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/constants")
require( GetScriptDirectory().."/item_usage")
require( GetScriptDirectory().."/modifiers")

----------
local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "retreat"
end

function X:OnStart(myBot)
    utils.IsInLane()
end

function X:OnEnd()
    setHeroVar("RetreatLane", nil)
    setHeroVar("RetreatPos", nil)
    setHeroVar("IsRetreating", false)
end

local function Updates(bot)
    setHeroVar("RetreatPos", utils.PositionAlongLane(bot, getHeroVar("RetreatLane")))
end

function X:PrintReason()
    local reason = getHeroVar("RetreatReason")
    if reason == constants.RETREAT_FOUNTAIN then
        return "FOUNTAIN"
    elseif reason == constants.RETREAT_DANGER then
        return "DANGER"
    elseif reason == constants.RETREAT_TOWER then
        return "TOWER"
    elseif reason == constants.RETREAT_CREEP then
        return "CREEP"
    else
        return "<ERROR>"
    end
end

function X:Think(bot)

    if utils.IsBusy(bot) then return end
    
    Updates(bot)
    
    local rLane = getHeroVar("RetreatLane")
    local rPos = getHeroVar("RetreatPos")

    nextmove = GetLocationAlongLane(rLane, 0.0)
    if getHeroVar("IsInLane") and rPos < 0.75 then
        nextmove = GetLocationAlongLane(rLane, Max(rPos-0.03, 0.0))
    end

    local retreatAbility = getHeroVar("HasMovementAbility")
    if retreatAbility ~= nil and retreatAbility[1]:IsFullyCastable() then
        local behavior = retreatAbility[1]:GetBehavior()
        
        local value = retreatAbility[2]
        -- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
        local scale = utils.GetDistance(GetLocationAlongLane(rLane, 0.5), GetLocationAlongLane(rLane, 0.49))
        value = ((value - 15) / scale)*0.01 -- we subtract 15 to give ourselves a little rounding wiggle room
        if getHeroVar("IsInLane") then
            nextmove = GetLocationAlongLane(rLane, Max(rPos-value, 0.0))
        else
            nextmove = utils.VectorTowards(bot:GetLocation(), nextmove, value-15)
        end
        
        -- we can move to "location"
        if utils.CheckFlag(behavior, ABILITY_BEHAVIOR_POINT) then
            bot:Action_UseAbilityOnLocation(retreatAbility[1], nextmove)
            return
        -- we can move to a "unit"
        elseif utils.CheckFlag(behavior, ABILITY_BEHAVIOR_UNIT_TARGET) then
            local targetType = retreatAbility[1]:GetTargetType()
            
            if utils.CheckFlag(targetType, ABILITY_TARGET_TYPE_CREEP) then
                local viableTargets = utils.GetCreepsBetweenMeAndLoc(nextmove, 200)
                if #viableTargets > 0 then
                    if #viableTargets > 1 then
                        table.sort(viableTargets, function(n1,n2) return GetUnitToUnitDistance(bot, n1) > GetUnitToUnitDistance(bot, n2) end)
                    end
                    bot:Action_UseAbilityOnEntity(retreatAbility[1], viableTargets[1])
                    return
                end
            end
            
            if utils.CheckFlag(targetType, ABILITY_TARGET_TYPE_HERO) then
                local viableTargets = utils.GetFriendlyHeroesBetweenMeAndLoc(nextmove, 200)
                if #viableTargets > 0 then
                    if #viableTargets > 1 then
                        table.sort(viableTargets, function(n1,n2) return GetUnitToUnitDistance(bot, n1) > GetUnitToUnitDistance(bot, n2) end)
                    end
                    bot:Action_UseAbilityOnEntity(retreatAbility[1], viableTargets[1])
                    return
                end
            end
            
            if utils.CheckFlag(targetType, ABILITY_TARGET_TYPE_TREE) then
                utils.pause("Retreat ability to Tree not implemented yet")
            end
        end
    end

    --utils.myPrint("MyLanePos: ", tostring(bot:GetLocation()), ", RetreatPos: ", tostring(nextmove))
    
    if utils.IsItemAvailable("item_blink") then
        local value = 1200 -- max blink distance
        -- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
        local scale = utils.GetDistance(GetLocationAlongLane(rLane, 0.5), GetLocationAlongLane(rLane, 0.49))
        value = ((value - 25) / scale)*0.01 -- we subtract 25 to give ourselves a little rounding wiggle room
        nextmove = GetLocationAlongLane(rLane, Max(rPos-value, 0.0))
        nextmove = utils.VectorTowards(bot:GetLocation(), nextmove, 1150)
        item_usage.UseBlink(nextmove)
        return
    end
    
    if not modifiers.IsInvisible(bot) then
        if item_usage.UseGlimmerCape(bot) then return end
    
        if item_usage.UseRegenItems() then return end
        
        if item_usage.UseMovementItems(nextmove) then return end
    end
    
    bot:Action_MoveToLocation(nextmove)
end

function X:Desire(bot)
    local enemies = gHeroVar.GetNearbyEnemies(bot, 1200)
    local allies  = gHeroVar.GetNearbyAllies(bot, 1200)
    local eTowers = gHeroVar.GetNearbyEnemyTowers(bot, 900)
    local aTowers = gHeroVar.GetNearbyAlliedTowers(bot, 600)

    local nEnemies = #enemies
    local nAllies  = #allies
    local nETowers = #eTowers
    local nATowers = #aTowers
    
    local numbersDiff = nEnemies + nETowers - nAllies - nATowers

    if not utils.IsCore(bot) then
        if numbersDiff > 1 then
            setHeroVar("IsRetreating", true)
            return BOT_MODE_DESIRE_HIGH
        end
	end
    
    if bot:GetHealth()/bot:GetMaxHealth() > 0.9 and bot:GetMana()/bot:GetMaxMana() > 0.9 then
        return BOT_MODE_DESIRE_NONE
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.65 and bot:GetMana()/bot:GetMaxMana() > 0.6 and 
        GetUnitToLocationDistance(bot, GetLocationAlongLane(getHeroVar("CurLane"), 0)) > 6000 then
        return BOT_MODE_DESIRE_NONE
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.8 and bot:GetMana()/bot:GetMaxMana() > 0.36 and 
        GetUnitToLocationDistance(bot, GetLocationAlongLane(getHeroVar("CurLane"), 0)) > 6000 then
        return BOT_MODE_DESIRE_NONE
    end
    
    if getHeroVar("IsRetreating") then
        return BOT_MODE_DESIRE_HIGH
    end
    
    if (bot:GetHealth()<(bot:GetMaxHealth()*0.17*(nEnemies-nAllies+1) + nETowers*110)) or ((bot:GetHealth()/bot:GetMaxHealth()) < 0.25) or 
        (bot:GetMana()/bot:GetMaxMana() < 0.07 and bot.SelfRef:getCurrentMode():GetName() == "laning" and 
         bot:GetManaRegen() < 6.0 ) then
		setHeroVar("IsRetreating", true)
		return BOT_MODE_DESIRE_HIGH
	end
	
	if numbersDiff > 1 then
		local MaxStun = 0
		
		for _,enemy in pairs(enemies) do
			if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.4 then
				MaxStun = Max(MaxStun, Max(enemy:GetStunDuration(true), enemy:GetSlowDuration(true)/1.5))
			end
		end
	
		local enemyDamage = 0
		for _,enemy in pairs(enemies) do
			if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.4 then
				local damage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_ALL)
				enemyDamage = enemyDamage + damage
			end
		end
		
		if 0.55*enemyDamage > bot:GetHealth() then
			setHeroVar("IsRetreating", true)
			return BOT_MODE_DESIRE_HIGH
		end
	end
   
    return BOT_MODE_DESIRE_NONE
end

return X