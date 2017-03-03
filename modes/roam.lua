-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

----------
X.me = nil

local HealthFactor = 1
local UnitPosFactor = 1
local DistanceFactor = 0.2
local HeroCountFactor = 0.3
local MinRating = 1.0

function FindTarget(bot)
    X.me = gHeroVar.GetVar(bot:GetPlayerID(), "Self")
    if not X.me:IsReadyToGank(bot) then
        return false
    end

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
            if enemy:GetPlayerID() ~= e:GetPlayerID() then
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
        ratings[#ratings+1] = {r, e}
    end
    if #ratings == 0 then return false end
    
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
        X.me:setHeroVar("RoamTarget", target)
        utils.myPrint(" stalking "..utils.GetHeroName(target))
        return true
    end
    return false
end

function X:GetName()
    return "roam"
end

function X:OnStart(myBot)
    X.me = myBot
end

function X:OnEnd()
    X.me:setHeroVar("RoamTarget", nil)
end

function X:Think(bot)
    if utils.IsBusy(bot) then return end
    
    local target = X.me:getHeroVar("RoamTarget")
    
    if target and not target:IsNull() then
        local dist = GetUnitToUnitDistance(bot, target)
        if dist < 500 then
            bot:Action_AttackUnit(target, true)
            X.me:setHeroVar("Target", target)
            X.me:setHeroVar("RoamTarget", nil)
            return
        end
        
        bot:Action_MoveToUnit(target)
    elseif target then
        local timeSinceSeen = GetHeroLastSeenInfo(target:GetPlayerID()).time
        if timeSinceSeen < 2 then
            bot:Action_MoveToLocation( GetHeroLastSeenInfo(target:GetPlayerID()).location )
        else
            X.me:setHeroVar("RoamTarget", nil)
        end
    end
end

return X