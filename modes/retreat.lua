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
    local bot = GetBot()
    setHeroVar("RetreatLane", nil)
    setHeroVar("RetreatPos", nil)
    bot.IsRetreating = false
    bot.retreat_desire_debug = ""
end

local function Updates(bot)
    setHeroVar("RetreatPos", utils.PositionAlongLane(bot, getHeroVar("RetreatLane")))
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

    --utils.myPrint("MyLanePos: ", tostring(bot:GetLocation()), ", RetreatPos: ", tostring(nextmove))
    
    local nearbyEnemies = gHeroVar.GetNearbyEnemies(bot, 1600)
    local nearbyETowers = gHeroVar.GetNearbyEnemyTowers(bot, 1600)
    if #nearbyEnemies > 0 or #nearbyETowers > 0 then
        local listDangerHandles = { unpack(nearbyEnemies), unpack(nearbyETowers) }
        nextmove = utils.DirectionAwayFromDanger(listDangerHandles, nextmove)
    end
    
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
        if item_usage.UseGlimmerCape() then return end
    
        if item_usage.UseRegenItems() then return end
        
        if item_usage.UseMovementItems(nextmove) then return end
    end
    
    gHeroVar.HeroMoveToLocation(bot, nextmove)
end

function X:Desire(bot)
    local enemies = gHeroVar.GetNearbyEnemies(bot, 1200)
    local allies  = gHeroVar.GetNearbyAllies(bot, 1200)
    
    local MaxStun = 0
    for _,enemy in pairs(enemies) do
        if utils.ValidTarget(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.25 then
            MaxStun = Max(MaxStun, Max(enemy:GetStunDuration(true), enemy:GetSlowDuration(true)/1.5))
        end
    end

    local enemyDamage = 0
    for _,enemy in pairs(enemies) do
        if utils.ValidTarget(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.25 then
            local damage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun, DAMAGE_TYPE_ALL)
            enemyDamage = enemyDamage + damage
        end
    end
    
    local HealthPerc    = bot:GetHealth()/bot:GetMaxHealth()
    local ManaPerc      = bot:GetMana()/bot:GetMaxMana()
    
    if enemyDamage/#allies > bot:GetHealth() then
        if #allies == 1 and HealthPerc > 0.6 then
            --utils.myPrint("What to do... I'm almost at full health but can die to enemy burst!")
            -- TODO: need to request support from allies
        else
            bot.IsRetreating = true
        end

        bot.retreat_desire_debug = "enemyDamage/#allies > bot:GetHealth()"
        return BOT_MODE_DESIRE_VERYHIGH
    end
    
    if HealthPerc > 0.9 and ManaPerc > 0.9 then
        return BOT_MODE_DESIRE_NONE
    end

    if HealthPerc > 0.65 and ManaPerc > 0.6 and bot:DistanceFromFountain() > 6000 then
        return BOT_MODE_DESIRE_NONE
    end

    if HealthPerc > 0.8 and ManaPerc > 0.36 and bot:DistanceFromFountain() > 6000 then
        return BOT_MODE_DESIRE_NONE
    end
    
    if bot.IsRetreating then
        return BOT_MODE_DESIRE_HIGH
    end
    
    if HealthPerc < bot.RetreatHealthPerc and bot:GetHealthRegen() < 7.9 or 
        (ManaPerc < 0.07 and bot.SelfRef:getCurrentMode():GetName() == "laning" and
        bot:GetManaRegen() < 6.0 and not utils.IsCore(bot) ) then
		bot.IsRetreating = true
        bot.retreat_desire_debug = "low health% or very low mana%"
		return BOT_MODE_DESIRE_HIGH
	end
   
    return BOT_MODE_DESIRE_NONE
end

return X