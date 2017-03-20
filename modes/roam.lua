-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
require( GetScriptDirectory().."/item_usage" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

local HealthFactor = 1
local UnitPosFactor = 1
local DistanceFactor = 0.2
local HeroCountFactor = 0.3
local MinRating = 1.0

function FindTarget(bot)
    --if not bot.SelfRef:IsReadyToGank(bot) then
    --    return false
    --end

    local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES) -- check all enemies
    local allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
    local ratings = {}
    
    local botMS = bot:GetCurrentMovementSpeed()
    if utils.GetHeroName(bot) == "spirit_breaker" then
        botMS = bot:GetAbilityByName("spirit_breaker_charge_of_darkness"):GetSpecialValueInt("movement_speed")
    end
    
    for i, e in pairs(enemies) do
        local r = 0
        r = r + HealthFactor * (1 - e:GetHealth()/e:GetMaxHealth())
        -- time to get there in 10s units
        r = r - DistanceFactor * GetUnitToUnitDistance(bot, e) / botMS / 10
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
        setHeroVar("RoamTarget", target)
        --utils.myPrint(" stalking "..utils.GetHeroName(target))
        return true
    end
    return false
end

function X:GetName()
    return "roam"
end

function X:OnStart(myBot)
end

function X:OnEnd()
    setHeroVar("RoamTarget", nil)
end

function X:Think(bot)    
    if utils.IsBusy(bot) then return end
    
    local target = getHeroVar("RoamTarget")
    
    if utils.ValidTarget(target) and target:IsAlive() then
        local dist = GetUnitToUnitDistance(bot, target)
        
        if utils.IsItemAvailable("item_blink") then
            if dist < 1200 then
                item_usage.UseBlink(target:GetLocation())
                setHeroVar("Target", target)
                setHeroVar("RoamTarget", nil)
                return
            end
        end
        
        if dist < 300 then
            gHeroVar.HeroAttackUnit(bot, target, true)
            setHeroVar("Target", target)
            setHeroVar("RoamTarget", nil)
            return
        end
        
        gHeroVar.HeroMoveToLocation(bot, target:GetLocation())
    else
        setHeroVar("RoamTarget", nil)
    end
end

function X:Desire(bot)
    if getHeroVar("Role") == ROLE_ROAMER or bot.SelfRef:IsReadyToGank(bot) then
        
        local roamTarget = getHeroVar("RoamTarget")
        if utils.ValidTarget(roamTarget) then
            local dist = GetUnitToUnitDistance(bot, roamTarget)
        
            local timeToIntercept = dist/bot:GetCurrentMovementSpeed()
            local timeUntilEscaped = utils.TimeForEnemyToGetIntoTheirBase(roamTarget)
                
            if timeUntilEscaped <= timeToIntercept then
                return BOT_MODE_DESIRE_HIGH
            end
        end
        
        if FindTarget(bot) then
            return BOT_MODE_DESIRE_HIGH
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X