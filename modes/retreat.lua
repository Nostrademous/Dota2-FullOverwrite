-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/item_usage")

----------
local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

----------
X.me            = nil

function X:GetName()
    return "retreat"
end

function X:OnStart(myBot)
    X.me = myBot
    utils.IsInLane()
end

function X:OnEnd()
    X.me:setHeroVar("RetreatLane", nil)
    X.me:setHeroVar("RetreatPos", nil)
    X.me:setHeroVar("IsRetreating", false)
end

local function Updates(bot)
    if X.me:getHeroVar("IsInLane") then
        X.me:setHeroVar("RetreatPos", utils.PositionAlongLane(bot, X.me:getHeroVar("RetreatLane")))
    end
end

local function DoFartherRetreat(bot, loc)
    Updates(bot)
    
    local rLane = X.me:getHeroVar("RetreatLane")
    local rPos = X.me:getHeroVar("RetreatPos")

    local nextmove = loc or nil
    
    if nextmove == nil then
        if X.me:getHeroVar("IsInLane") then
            nextmove = GetLocationAlongLane(rLane, Max(rPos-0.03, 0.0))
        else
            nextmove = utils.Fountain(GetTeam())
        end
    end

    local retreatAbility = X.me:getHeroVar("HasMovementAbility")
    if retreatAbility ~= nil and retreatAbility[1]:IsFullyCastable() then
        -- same name for bot AM and QoP, "tooltip_range" for "riki_blink_strike"
        local value = retreatAbility[2]
        -- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
        local scale = utils.GetDistance(GetLocationAlongLane(rLane, 0.5), GetLocationAlongLane(rLane, 0.49))
        value = ((value - 15) / scale)*0.01 -- we subtract 15 to give ourselves a little rounding wiggle room
        if X.me:getHeroVar("IsInLane") then
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

function X:Think(bot)
    local reason = X.me:getHeroVar("RetreatReason")
    
    if reason == constants.RETREAT_FOUNTAIN then
        X.me:setHeroVar("IsRetreating", true)
        
        -- if we healed up enough, change our reason for retreating
        if bot:DistanceFromFountain() >= 5000 and (bot:GetHealth()/bot:GetMaxHealth()) > 0.6 and (bot:GetMana()/bot:GetMaxMana()) > 0.6 then
            utils.myPrint("DoRetreat - Upgrading from RETREAT_FOUNTAIN to RETREAT_DANGER")
            X.me:setHeroVar("RetreatReason", constants.RETREAT_DANGER)
            return true
        end

        if bot:DistanceFromFountain() > 0 or (bot:GetHealth()/bot:GetMaxHealth()) < 1.0 or (bot:GetMana()/bot:GetMaxMana()) < 1.0 then
            DoFartherRetreat(bot, utils.Fountain(GetTeam()))
            return true
        end
        --utils.myPrint("DoRetreat - RETREAT FOUNTAIN End".." - DfF: ".. bot:DistanceFromFountain()..", H: "..bot:GetHealth())
    elseif reason == constants.RETREAT_DANGER then
        X.me:setHeroVar("IsRetreating", true)
        
        local enemyTooClose = false
        local nearbyEnemyHeroes = bot:GetNearbyHeroes(650, true, BOT_MODE_NONE)
        for _, enemy in pairs(nearbyEnemyHeroes) do
            if GetUnitToUnitDistance(bot, enemy) < Max(650, enemy:GetAttackRange()) then
                enemyTooClose = true
                break
            end
        end
        
        if bot:TimeSinceDamagedByAnyHero() < 3.0 or enemyTooClose then
            if bot:DistanceFromFountain() < 5000 and (bot:GetHealth()/bot:GetMaxHealth()) < 1.0 then
                DoFartherRetreat(bot)
                return true
            elseif bot:DistanceFromFountain() >= 5000 and (bot:GetHealth()/bot:GetMaxHealth()) < 0.6 then
                DoFartherRetreat(bot)
                return true
            end
        elseif (bot:GetHealth()/bot:GetMaxHealth()) < 0.8 then
            DoFartherRetreat(bot)
            return true
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
            return true
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
            
            return true
        end
        --utils.myPrint("DoRetreat - RETREAT CREEP End")
    end

    -- If we got here, we are done retreating
    --utils.myPrint("done retreating from reason: "..reason)
    return true
end

function X:Desire(bot, nearbyEnemies, nearbyETowers, nearbyAllies)
    X.me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")
    local MaxStun = 2   
    for _, enemy in pairs(nearbyEnemies) do
        if utils.NotNilOrDead(enemy) and enemy:GetHealth()/enemy:GetMaxHealth() > 0.25 then
            if X.me:getHeroVar("HasEscape") then
                MaxStun = MaxStun + enemy:GetStunDuration(true)
            else
                MaxStun = MaxStun + enemy:GetStunDuration(true) + 0.5*enemy:GetSlowDuration(true)
            end
        end
    end
    
    local allyTime = 0
    for _, ally in pairs(nearbyAllies) do
        if GetUnitToUnitDistance(bot, ally) < 1000 then
            allyTime = allyTime + ally:GetStunDuration(true) + 0.5*ally:GetSlowDuration(true)
        end
    end

    local enemyDamage = 0
    for _, enemy in pairs(nearbyEnemies) do
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
            X.me:setHeroVar("RetreatReason", constants.RETREAT_DANGER)
            return BOT_MODE_DESIRE_HIGH
        end
    end
    
    for _, enemy in pairs(nearbyEnemies) do
        if bot:WasRecentlyDamagedByHero( enemy, 1.5 ) then
            if (bot:GetHealth() + bot:GetAttackDamage()) < (enemy:GetHealth() + enemy:GetAttackDamage()) then
                X.me:setHeroVar("RetreatReason", constants.RETREAT_DANGER)
                return BOT_MODE_DESIRE_MODERATE
            end
        end
    end
    
    if bot:GetHealth()/bot:GetMaxHealth() > 0.9 and bot:GetMana()/bot:GetMaxMana() > 0.5 then
        if utils.IsTowerAttackingMe() then
            X.me:setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH 
        end
        return BOT_MODE_DESIRE_NONE
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.65 and bot:GetMana()/bot:GetMaxMana() > 0.6 and 
        GetUnitToLocationDistance(bot, GetLocationAlongLane(X.me:getHeroVar("CurLane"), 0)) > 6000 then
        if utils.IsTowerAttackingMe() then
            X.me:setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH 
        elseif utils.IsCreepAttackingMe() then
            local pushing = X.me:getHeroVar("ShouldPush")
            if not pushing then
                X.me:setHeroVar("RetreatReason", constants.RETREAT_CREEP)
                return BOT_MODE_DESIRE_LOW 
            end
        end
        return BOT_MODE_DESIRE_NONE
    end

    if bot:GetHealth()/bot:GetMaxHealth() > 0.8 and bot:GetMana()/bot:GetMaxMana() > 0.36 and 
        GetUnitToLocationDistance(bot, GetLocationAlongLane(X.me:getHeroVar("CurLane"), 0)) > 6000 then
        if utils.IsTowerAttackingMe() then
            X.me:setHeroVar("RetreatReason", constants.RETREAT_TOWER)
            return BOT_MODE_DESIRE_HIGH
        elseif utils.IsCreepAttackingMe() then
            local pushing = X.me:getHeroVar("ShouldPush")
            if not pushing then
                setHeroVar("RetreatReason", constants.RETREAT_CREEP)
                return BOT_MODE_DESIRE_LOW 
            end
        end
        return BOT_MODE_DESIRE_NONE
    end

    if ((bot:GetHealth()/bot:GetMaxHealth()) < 0.33) or (bot:GetMana()/bot:GetMaxMana() < 0.07 and 
        X.me:getPrevMode():GetName() == "laning" and not utils.IsCore()) then
        X.me:setHeroVar("RetreatReason", constants.RETREAT_FOUNTAIN)
        return BOT_MODE_DESIRE_HIGH 
    end

    if utils.IsTowerAttackingMe() then
        if #nearbyETowers >= 1 then
            local eTower = nearbyETowers[1]
            if eTower:GetHealth()/eTower:GetMaxHealth() < 0.1 and not eTower:HasModifier("modifier_fountain_glyph") then
                return BOT_MODE_DESIRE_NONE
            end
        end
        X.me:setHeroVar("RetreatReason", constants.RETREAT_TOWER)
        return BOT_MODE_DESIRE_LOW  
    elseif utils.IsCreepAttackingMe() then
        local pushing = X.me:getHeroVar("ShouldPush")
        if not pushing then
            X.me:setHeroVar("RetreatReason", constants.RETREAT_CREEP)
            return BOT_MODE_DESIRE_LOW  
        end
    end

    if X.me:getHeroVar("IsRetreating") then
        if bot:GetHealth()/bot:GetMaxHealth() < 0.8 then
            return BOT_MODE_DESIRE_MODERATE
        elseif bot:GetHealth()/bot:GetMaxHealth() > 0.85 and 
            bot:DistanceFromFountain() > 600 then
            utils.myPrint("Life Sucks when they can kill you from almost full life")
            X.me:setHeroVar("IsRetreating", false)
        else
            if bot:DistanceFromFountain() < 600 then
                if bot:GetHealth() < bot:GetMaxHealth() or 
                    bot:GetMana() < bot:GetMaxmana() then
                    return BOT_MODE_DESIRE_MODERATE
                end
            end
            X.me:setHeroVar("IsRetreating", false)
        end
    end
    return BOT_MODE_DESIRE_NONE
end

return X