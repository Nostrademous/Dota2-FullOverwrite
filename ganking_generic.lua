-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

-------
_G._savedEnv = getfenv()
module( "ganking_generic", package.seeall )
----------
require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().. "/item_usage" )
require( GetScriptDirectory().. "/global_game_state" )

local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end
----------

local HealthFactor = 1
local UnitPosFactor = 1
local DistanceFactor = 0.2
local HeroCountFactor = 0.3
local MinRating = 1.0

----------------------------------

function FindTarget(bot)
    -- TODO: don't do this every frame and for every ganking hero. Should be part of team level logic.
    local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES) -- check all enemies
    local allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    local ratings = {}
    for i, e in pairs(enemies) do
        local r = 0
        r = r + HealthFactor * (1 - e:GetHealth()/e:GetMaxHealth())
        -- time to get there in 10s units
        r = r - DistanceFactor * GetUnitToUnitDistance(bot, e) / bot:GetCurrentMovementSpeed() / 10
        r = r + UnitPosFactor * (1 - global_game_state.GetPositionBetweenBuildings(e, GetTeam()))
        local hero_count = 0
        for _, enemy in pairs(enemies) do
            if enemy:CanBeSeen() and utils.GetHeroName(enemy) ~= utils.GetHeroName(e) then
                if GetUnitToUnitDistance(enemy, e) < 1500 then
                    hero_count = hero_count - 1
                end
            end
        end
        for _, ally in pairs(allies) do
            if ally:GetPlayerID() ~= bot:GetPlayerID() then
                if GetUnitToUnitDistance(ally, e) < 1500 then
                    hero_count = hero_count + 1
                end
            end
        end
        r = r + HeroCountFactor * hero_count
        if false then
              print(utils.GetHeroName(e), 1 - e:GetHealth()/e:GetMaxHealth())
              print(utils.GetHeroName(e), HealthFactor * (1 - e:GetHealth()/e:GetMaxHealth()))
              print(utils.GetHeroName(e), GetUnitToUnitDistance(bot, e) / 300 / 10)
              print(utils.GetHeroName(e), DistanceFactor * GetUnitToUnitDistance(bot, e) / 300 / 10)
              print(utils.GetHeroName(e), 1 - global_game_state.GetPositionBetweenBuildings(e, GetTeam()))
              print(utils.GetHeroName(e), UnitPosFactor * (1 - global_game_state.GetPositionBetweenBuildings(e, GetTeam())))
              print(utils.GetHeroName(e), hero_count)
              print(utils.GetHeroName(e), HeroCountFactor * hero_count)
              print(utils.GetHeroName(e), r)
        end
        ratings[#ratings+1] = {r, e}
    end
      if #ratings == 0 then
          return false
      end
    table.sort(ratings, function(a, b) return a[1] > b[1] end) -- sort by rating, descending
        local rating = ratings[1][1]
        if rating < MinRating then -- not worth
            return false
        end
    local target = ratings[1][2]

    -- Determine if we can kill the target
    local heroAmpFactor = 0
    for _, ally in pairs(allies) do
        if ally:GetPlayerID() ~= bot:GetPlayerID() then
            if GetUnitToUnitDistance(ally, target) < 1500 then
                heroAmpFactor = heroAmpFactor + 1
            end
        end
    end
    if (bot:GetEstimatedDamageToTarget( true, target, 5.0, DAMAGE_TYPE_ALL ) * (1 + 0.5*heroAmpFactor)) > target:GetHealth() then
        setHeroVar("GankTarget", {Obj=target, Id=target:GetPlayerID()})
        setHeroVar("move_ticks", 0)
        utils.myPrint(" stalking "..utils.GetHeroName(target))
        return true
    end
    return false
end

function ApproachTarget(bot)
    local me = getHeroVar("Self")
    local move_ticks = getHeroVar("move_ticks")

    if move_ticks > 250 then -- time to check for targets again
        utils.myPrint("move_ticks > 250 :: abandoning gank")
        me:RemoveAction(constants.ACTION_GANKING)
        return false
    else
        setHeroVar("move_ticks", move_ticks + 1)
    end

    local target = getHeroVar("GankTarget")

    if me:IsReadyToGank(bot) == false then
        me:RemoveAction(constants.ACTION_GANKING)
        return false
    end

    if target.Id > 0 and IsHeroAlive(target.Id) then
        if not target.Obj:IsNull() then
            if GetUnitToUnitDistance(bot, target.Obj) < 1000 then
                return true
            else
                if GetUnitToUnitDistance(bot, target.Obj) < 1400 then
                    if bot:GetMana() > 300 then
                        item_usage.UseSilverEdge()
                        item_usage.UseShadowBlade()
                    end
                end
                bot:Action_MoveToUnit(target.Obj) -- Let's go there
                return false
            end
        else
            if GetHeroLastSeenInfo(target.Id).time > 5.0 then
                me:RemoveAction(constants.ACTION_GANKING)
                return false
            else
                local lastLoc = GetHeroLastSeenInfo(target.Id).location
                if utils.GetOtherTeam() == TEAM_DIRE then
                    local prob1 = GetUnitPotentialValue(target.Obj, Vector(lastLoc[1] + 500, lastLoc[2]), 1000)
                    local prob2 = GetUnitPotentialValue(target.Obj, Vector(lastLoc[1], lastLoc[2] + 500), 1000)
                    if prob1 > 180 and prob1 > prob2 then
                        item_usage.UseMovementItems()
                        bot:Action_MoveToLocation(Vector(lastLoc[1] + 500, lastLoc[2]))
                        return false
                    elseif prob2 > 180 then
                        item_usage.UseMovementItems()
                        bot:Action_MoveToLocation(Vector(lastLoc[1], lastLoc[2] + 500))
                        return false
                    end
                else
                    local prob1 = GetUnitPotentialValue(target.Obj, Vector(lastLoc[1] - 500, lastLoc[2]), 1000)
                    local prob2 = GetUnitPotentialValue(target.Obj, Vector(lastLoc[1], lastLoc[2] - 500), 1000)
                    if prob1 > 180 and prob1 > prob2 then
                        item_usage.UseMovementItems()
                        bot:Action_MoveToLocation(Vector(lastLoc[1] - 500, lastLoc[2]))
                        return false
                    elseif prob2 > 180 then
                        item_usage.UseMovementItems()
                        bot:Action_MoveToLocation(Vector(lastLoc[1], lastLoc[2] - 500))
                        return false
                    end
                end
            end
        end
    else
        utils.myPrint("GankTarget is dead!!!")
        me:RemoveAction(constants.ACTION_GANKING)
        return false
    end
    return false
end

function KillTarget(bot, target)
    if target.Obj ~= nil then
        if target.Obj:IsAlive() then
            if target.Obj:CanBeSeen() then
                setHeroVar("Target", target)
                utils.myPrint("killing target :: ", utils.GetHeroName(target.Obj))
                bot:Action_AttackUnit(target.Obj, false)
                return true
            end
        end
    end
    return false
end

--------
for k,v in pairs( ganking_generic ) do _G._savedEnv[k] = v end
