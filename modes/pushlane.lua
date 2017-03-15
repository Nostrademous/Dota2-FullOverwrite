-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "pushlane"
end

function X:OnStart(myBot)
    setHeroVar("ShouldPush", true)
end

function X:OnEnd()
    setHeroVar("ShouldPush", false)
end

function X:Think(bot)

    if utils.IsBusy(bot) then return end
    
    local Towers = gHeroVar.GetNearbyEnemyTowers(bot, 750)
    local Shrines = bot:GetNearbyShrines(750, true)
    local Barracks = bot:GetNearbyBarracks(750, true)
    local Ancient = GetAncient(utils.GetOtherTeam())
    
    if #Towers == 0 and #Shrines == 0 and #Barracks == 0 then
        if GetUnitToLocationDistance(bot, Ancient:GetLocation()) < 500 then
            if utils.NotNilOrDead(Ancient) and not Ancient:HasModifier("modifier_fountain_glyph") then
                gHeroVar.HeroAttackUnit(bot, Ancient, true)
                return
            end
        end
    end
    
    -- we are pushing lane but no structures nearby, so push forward in lane
    local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), getHeroVar("CurLane"), false)
    local frontier = Min(1.0, enemyFrontier)
    local dest = GetLocationAlongLane(getHeroVar("CurLane"), Min(1.0, frontier))

    local nearbyAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, 900)

    if utils.IsTowerAttackingMe() and #nearbyAlliedCreep > 0 then
        if utils.DropTowerAggro(bot, nearbyAlliedCreep) then return end
    end
    
    if #Towers > 0 and Towers[1]:GetHealth()/Towers[1]:GetMaxHealth() < 0.1 and
        not Towers[1]:HasModifier("modifier_fountain_glyph") then
        gHeroVar.HeroAttackUnit(bot, Towers[1], false)
    end

    -- TODO: should be reworked with proper tower aggro thinking
    local nearbyEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)
    if #nearbyEnemyCreep > 0 then
        if #nearbyAlliedCreep > 0 then
            if #Towers > 0 and #nearbyAlliedCreep < 2 then
                local dist = GetUnitToUnitDistance(bot, Towers[1])
                if dist < 750 then
                    gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), Towers[1]:GetLocation(), 750-dist))
                    return
                end
            else
                creep, _ = utils.GetWeakestCreep(nearbyEnemyCreep)
                if creep then
                    gHeroVar.HeroAttackUnit(bot, creep, true)
                    return
                end
            end
        else
            getHeroVar("Self"):ClearMode()
            return
        end
    end

    if #Towers > 0 and (#nearbyAlliedCreep > 1 or 
        (#nearbyAlliedCreep == 1 and nearbyAlliedCreep[1]:GetHealth() > 162) or
        Towers[1]:GetHealth()/Towers[1]:GetMaxHealth() < 0.1) then
        for _, tower in ipairs(Towers) do
            if utils.NotNilOrDead(tower) and (not tower:HasModifier("modifier_fountain_glyph")) then
                gHeroVar.HeroAttackUnit(bot, tower, true)
                return
            else
                local dist = GetUnitToUnitDistance(bot, Towers[1])
                if dist < 710 then
                    gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), Towers[1]:GetLocation(), 710-dist))
                    return
                end
            end
        end
    end

    if #Barracks > 0 then
        for _, barrack in ipairs(Barracks) do
            if utils.NotNilOrDead(barrack) and (not barrack:HasModifier("modifier_fountain_glyph")) then
                gHeroVar.HeroAttackUnit(bot, barrack, true)
                return
            end
        end
    end

    if #Shrines > 0 then
        for _, shrine in ipairs(Shrines) do
            if utils.NotNilOrDead(shrine) and (not shrine:HasModifier("modifier_fountain_glyph")) then
                gHeroVar.HeroAttackUnit(bot, shrine, true)
                return
            end
        end
    end
    
    bot:Action_MoveToLocation(dest)
end

function X:Desire(bot)
    -- don't push for at least first 3 minutes
    if DotaTime() < 3*60 then return BOT_MODE_DESIRE_NONE end

    if #gHeroVar.GetNearbyEnemies(bot, 900) > 0 then -- TODO: what about allies?
        return BOT_MODE_DESIRE_NONE
    end

    if getHeroVar("Role") == constants.ROLE_JUNGLER then
        return BOT_MODE_DESIRE_NONE
    end
    
    -- this is hero-specific push-lane determination
    local nearbyETowers = gHeroVar.GetNearbyEnemyTowers(bot, Max(750, bot:GetAttackRange()))
    if #nearbyETowers > 0 then
        if ( nearbyETowers[1]:GetHealth() / nearbyETowers[1]:GetMaxHealth() ) < 0.1 and
            not nearbyETowers[1]:HasModifier("modifier_fountain_glyph") then
            return BOT_MODE_DESIRE_HIGH
        end
        
        if utils.IsTowerAttackingMe() and #gHeroVar.GetNearbyAlliedCreep(bot, 1000) == 0 then
            return BOT_MODE_DESIRE_NONE
        end
    end

    if #gHeroVar.GetNearbyAlliedCreep(bot, 1000) > 1 and #gHeroVar.GetNearbyEnemyCreep(bot, 1200) == 0 then
        return BOT_MODE_DESIRE_MODERATE
    end
    
    local me = getHeroVar("Self")
    if me:getCurrentMode():GetName() == "pushlane" then
        return me:getCurrentModeValue()
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X