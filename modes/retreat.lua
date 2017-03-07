-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/constants")
require( GetScriptDirectory().."/item_usage")

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
    if getHeroVar("IsInLane") then
        setHeroVar("RetreatPos", utils.PositionAlongLane(bot, getHeroVar("RetreatLane")))
    else
        setHeroVar("RetreatLane", LANE_MID)
    end
end

local function DoFartherRetreat(bot, loc)

    Updates(bot)
    
    local rLane = getHeroVar("RetreatLane")
    local rPos = getHeroVar("RetreatPos")

    local nextmove = loc or nil
    
    if nextmove == nil then
        if getHeroVar("IsInLane") then
            nextmove = GetLocationAlongLane(rLane, Max(rPos-0.03, 0.0))
        else
            nextmove = utils.Fountain(GetTeam())
        end
    end

    local retreatAbility = getHeroVar("HasMovementAbility")
    if retreatAbility ~= nil and retreatAbility[1]:IsFullyCastable() then
        -- same name for bot AM and QoP, "tooltip_range" for "riki_blink_strike"
        local value = retreatAbility[2]
        -- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
        local scale = utils.GetDistance(GetLocationAlongLane(rLane, 0.5), GetLocationAlongLane(rLane, 0.49))
        value = ((value - 15) / scale)*0.01 -- we subtract 15 to give ourselves a little rounding wiggle room
        if getHeroVar("IsInLane") then
            nextmove = GetLocationAlongLane(rLane, Max(rPos-value, 0.0))
        else
            nextmove = utils.VectorTowards(bot:GetLocation(), nextmove, value-15)
        end
        bot:Action_UseAbilityOnLocation(retreatAbility[1], nextmove)
        return
    end

    --utils.myPrint("MyLanePos: ", tostring(bot:GetLocation()), ", RetreatPos: ", tostring(nextmove))
    
    if item_usage.UseMovementItems(nextmove) then return end
    
    bot:Action_MoveToLocation(nextmove)
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
    local reason = getHeroVar("RetreatReason")
    
    if reason == constants.RETREAT_FOUNTAIN then
        setHeroVar("IsRetreating", true)
        
        -- if we healed up enough, change our reason for retreating
        if bot:DistanceFromFountain() >= 5000 and (bot:GetHealth()/bot:GetMaxHealth()) > 0.6 and (bot:GetMana()/bot:GetMaxMana()) > 0.6 then
            utils.myPrint("DoRetreat - Upgrading from RETREAT_FOUNTAIN to RETREAT_DANGER")
            setHeroVar("RetreatReason", constants.RETREAT_DANGER)
            return
        end

        if bot:DistanceFromFountain() > 0 or (bot:GetHealth()/bot:GetMaxHealth()) < 1.0 or (bot:GetMana()/bot:GetMaxMana()) < 1.0 then
            DoFartherRetreat(bot, utils.Fountain(GetTeam()))
            return
        end
        --utils.myPrint("DoRetreat - RETREAT FOUNTAIN End".." - DfF: ".. bot:DistanceFromFountain()..", H: "..bot:GetHealth())
    elseif reason == constants.RETREAT_DANGER then
        setHeroVar("IsRetreating", true)
        
        local enemyTooClose = false
        local nearbyEnemyHeroes = gHeroVar.GetNearbyEnemies(bot, 650)
        for _, enemy in pairs(nearbyEnemyHeroes) do
            if GetUnitToUnitDistance(bot, enemy) < Max(650, enemy:GetAttackRange()) then
                enemyTooClose = true
                break
            end
        end
        
        if bot:TimeSinceDamagedByAnyHero() < 3.0 or enemyTooClose then
            if bot:DistanceFromFountain() < 5000 and (bot:GetHealth()/bot:GetMaxHealth()) < 1.0 then
                DoFartherRetreat(bot)
                return
            elseif bot:DistanceFromFountain() >= 5000 and (bot:GetHealth()/bot:GetMaxHealth()) < 0.6 then
                DoFartherRetreat(bot)
                return
            end
        elseif (bot:GetHealth()/bot:GetMaxHealth()) < 0.8 then
            DoFartherRetreat(bot)
            return
        end
        --utils.myPrint("DoRetreat - RETREAT DANGER End".." - DfF: "..bot:DistanceFromFountain()..", H: "..bot:GetHealth())
    elseif reason == constants.RETREAT_TOWER then
        --utils.myPrint("STARTING TO RETREAT b/c of tower damage")

        local mypos = bot:GetLocation()
        if utils.IsTowerAttackingMe() then
            local rLoc = mypos
            
            --set the target to go back
            local bInLane, cLane = utils.IsInLane()
            if bInLane then
                local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), cLane, false) - 0.05
                rLoc = GetLocationAlongLane(cLane, enemyFrontier)
            else
                rLoc = utils.VectorTowards(mypos, utils.Fountain(GetTeam()), 300)
            end

            gHeroVar.HeroMoveToLocation(bot, rLoc)
            --utils.myPrint("TowerRetreat: ", d)
            return 
        end
        --utils.myPrint("DoRetreat - RETREAT TOWER End")
    elseif reason == constants.RETREAT_CREEP then
        --utils.myPrint("STARTING TO RETREAT b/c of creep damage")

        local mypos = bot:GetLocation()
        if utils.IsCreepAttackingMe(1.0) then
            local rLoc = mypos
            
            --set the target to go back
            local bInLane, cLane = utils.IsInLane()
            if bInLane then
                --utils.myPrint("Creep Retreat - InLane: ", cLane)
                local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), cLane, false) - 0.05
                rLoc = GetLocationAlongLane(cLane, enemyFrontier)
            else
                --utils.myPrint("Creep Retreat - Not InLane")
                rLoc = utils.VectorTowards(mypos, utils.Fountain(GetTeam()), 300)
            end

            gHeroVar.HeroMoveToLocation(bot, rLoc)
            
            return
        end
        --utils.myPrint("DoRetreat - RETREAT CREEP End")
    end

    -- If we got here, we are done retreating
    --utils.myPrint("done retreating from reason: "..reason)
    return
end

function X:Desire(bot)

    local MaxStun = 2   
    for _, enemy in pairs(getHeroVar("NearbyEnemies")) do
        if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.25 then
            if getHeroVar("HasEscape") then
                MaxStun = MaxStun + enemy:GetStunDuration(true)
            else
                MaxStun = MaxStun + enemy:GetStunDuration(true) + 0.5*enemy:GetSlowDuration(true)
            end
        end
    end
    
    local allyTime = 0
    for _, ally in pairs(getHeroVar("NearbyAllies")) do
        if GetUnitToUnitDistance(bot, ally) < 1000 then
            allyTime = allyTime + ally:GetStunDuration(true) + 0.5*ally:GetSlowDuration(true)
        end
    end

    local enemyDamage = 0
    for _, enemy in pairs(getHeroVar("NearbyEnemies")) do
        if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.25 then
            local pDamage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun - allyTime, DAMAGE_TYPE_PHYSICAL)
            local mDamage = enemy:GetEstimatedDamageToTarget(true, bot, MaxStun - allyTime, DAMAGE_TYPE_MAGICAL)
            enemyDamage = enemyDamage + pDamage + mDamage + enemy:GetEstimatedDamageToTarget(true, bot, MaxStun - allyTime, DAMAGE_TYPE_PURE)
            --utils.myPrint("["..utils.GetHeroName(enemy).."]: Damage: ", enemyDamage)
        end
    end
    
    --utils.myPrint("ConsiderRetreat() :: MaxStun: ", MaxStun, ", Dmg: ", enemyDamage)

    if enemyDamage > 0 and enemyDamage > bot:GetHealth() then
        --utils.myPrint(" - Retreating - could die in perfect stun/slow overlap")
        if bot:GetHealth()/bot:GetMaxHealth() < 0.75 then
            setHeroVar("RetreatReason", constants.RETREAT_DANGER)
            return BOT_MODE_DESIRE_HIGH
        end
    end
    
    if bot:GetHealth()/bot:GetMaxHealth() > 0.9 and bot:GetMana()/bot:GetMaxMana() > 0.5 then
        if utils.IsTowerAttackingMe() then
            setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH 
        end
        return BOT_MODE_DESIRE_NONE
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.65 and bot:GetMana()/bot:GetMaxMana() > 0.6 and 
        GetUnitToLocationDistance(bot, GetLocationAlongLane(getHeroVar("CurLane"), 0)) > 6000 then
        if utils.IsTowerAttackingMe() then
            setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH 
        elseif utils.IsCreepAttackingMe() then
            local pushing = getHeroVar("ShouldPush")
            if not pushing then
                setHeroVar("RetreatReason", constants.RETREAT_CREEP)
                return BOT_MODE_DESIRE_LOW 
            end
        end
        return BOT_MODE_DESIRE_NONE
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.8 and bot:GetMana()/bot:GetMaxMana() > 0.36 and 
        GetUnitToLocationDistance(bot, GetLocationAlongLane(getHeroVar("CurLane"), 0)) > 6000 then
        if utils.IsTowerAttackingMe() then
            setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH
        elseif utils.IsCreepAttackingMe() then
            local pushing = getHeroVar("ShouldPush")
            if not pushing then
                setHeroVar("RetreatReason", constants.RETREAT_CREEP)
                return BOT_MODE_DESIRE_LOW 
            end
        end
        return BOT_MODE_DESIRE_NONE
    end

    if ((bot:GetHealth()/bot:GetMaxHealth()) < 0.33) or (bot:GetMana()/bot:GetMaxMana() < 0.07 and 
        getHeroVar("Self"):getPrevMode():GetName() == "laning" and not utils.IsCore()) then
        setHeroVar("RetreatReason", constants.RETREAT_FOUNTAIN)
        return BOT_MODE_DESIRE_HIGH 
    end

    if utils.IsTowerAttackingMe() then
        if #getHeroVar("NearbyEnemyTowers") >= 1 then
            local eTower = getHeroVar("NearbyEnemyTowers")[1]
            if eTower:GetHealth()/eTower:GetMaxHealth() < 0.1 and not eTower:HasModifier("modifier_fountain_glyph") then
                return BOT_MODE_DESIRE_NONE
            end
        end
        setHeroVar("RetreatReason", constants.RETREAT_TOWER)
        return BOT_MODE_DESIRE_LOW  
    elseif utils.IsCreepAttackingMe() then
        local pushing = getHeroVar("ShouldPush")
        if not pushing then
            setHeroVar("RetreatReason", constants.RETREAT_CREEP)
            return BOT_MODE_DESIRE_LOW  
        end
    end

    if getHeroVar("IsRetreating") then
        if bot:GetHealth()/bot:GetMaxHealth() < 0.8 then
            return BOT_MODE_DESIRE_MODERATE
        elseif bot:GetHealth()/bot:GetMaxHealth() > 0.85 and 
            bot:DistanceFromFountain() > 600 then
            utils.myPrint("Life Sucks when they can kill you from almost full life")
            setHeroVar("IsRetreating", false)
        else
            if bot:DistanceFromFountain() < 600 then
                if bot:GetHealth() < bot:GetMaxHealth() or 
                    bot:GetMana() < bot:GetMaxmana() then
                    return BOT_MODE_DESIRE_MODERATE
                end
            end
            setHeroVar("IsRetreating", false)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

return X