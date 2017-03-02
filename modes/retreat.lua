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
X.RetreatLane   = nil
X.RetreatPos    = {}

function X:GetName()
    return "Retreat Mode"
end

function X:OnStart(myBot)
    X.me = myBot
    X.RetreatLane = X.me:getHeroVar("CurLane")
    utils.IsInLane()
end

function X:OnEnd()
    X.RetreatLane = nil
    X.RetreatPos = {}
    X.me:setHeroVar("IsRetreating", false)
end

local function Updates(bot)
    if X.me:getHeroVar("IsInLane") then
        X.RetreatPos = utils.PositionAlongLane(bot, X.RetreatLane)
        --utils.myPrint("RetreatLane: ", X.RetreatLane, " -- RetreatPos: <"..X.RetreatPos..">")
    end
end

local function DoFartherRetreat(bot, loc)
    Updates(bot)

    local nextmove = loc or nil
    
    if nextmove == nil then
        if X.me:getHeroVar("IsInLane") then
            nextmove = GetLocationAlongLane(X.RetreatLane, Max(X.RetreatPos-0.03, 0.0))
        else
            nextmove = utils.Fountain(GetTeam())
        end
    end

    local retreatAbility = X.me:getHeroVar("HasMovementAbility")
    if retreatAbility ~= nil and retreatAbility[1]:IsFullyCastable() then
        -- same name for bot AM and QoP, "tooltip_range" for "riki_blink_strike"
        local value = retreatAbility[2]
        -- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
        local scale = utils.GetDistance(GetLocationAlongLane(X.RetreatLane, 0.5), GetLocationAlongLane(X.RetreatLane, 0.49))
        value = ((value - 15) / scale)*0.01 -- we subtract 15 to give ourselves a little rounding wiggle room
        if X.me:getHeroVar("IsInLane") then
            nextmove = GetLocationAlongLane(X.RetreatLane, Max(X.RetreatPos-value, 0.0))
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

return X