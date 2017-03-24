-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/modifiers" )
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
end

function X:OnEnd()
end

function X:Think(bot)

    if utils.IsBusy(bot) then return end

    if utils.IsCrowdControlled(bot) then return end

    local Towers = gHeroVar.GetNearbyEnemyTowers(bot, 750)
    local Shrines = bot:GetNearbyShrines(1600, true)
    local Barracks = bot:GetNearbyBarracks(1600, true)
    local Ancient = GetAncient(utils.GetOtherTeam())

    -- if there are no structures near by
    if #Towers == 0 and #Shrines == 0 and #Barracks == 0 then
        -- are we near the enemy Ancient
        if GetUnitToLocationDistance(bot, Ancient:GetLocation()) < 500 then
            if utils.ValidTarget(Ancient) and not modifiers.IsBuildingGlyphed(Ancient) then
                gHeroVar.HeroAttackUnit(bot, Ancient, true)
                return
            end
        -- no structures, no ancient, push lane
        else
            local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), getHeroVar("CurLane"), false)
            local myFrontier = GetLaneFrontAmount(GetTeam(), getHeroVar("CurLane"), true)
            local frontier = Min(Min(1.0, enemyFrontier), myFrontier)
            local dest = GetLocationAlongLane(getHeroVar("CurLane"), frontier)

            local nearbyAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, 900)
            local nearbyEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)

            if #nearbyEnemyCreep > 0 then
                -- TODO: below should make exception for tanky high health regen heroes
                -- like Timber, DK, Axe, Bristle, etc... probably using a flag like bot.CanTank
                if #nearbyAlliedCreep > 0 or frontier < 0.25 then -- or bot.CanTank then
                    local creep, _ = utils.GetWeakestCreep(nearbyEnemyCreep)
                    if creep then
                        gHeroVar.HeroAttackUnit(bot, creep, true)
                        return
                    end
                end
            end

            -- no creeps, move forward in lane
            gHeroVar.HeroMoveToLocation(bot, dest)
            return
        end
    end

    if #Towers > 0 then
        -- if more than one tower, sort by lowest health
        local hTower = Towers[1]

        if utils.IsTowerAttackingMe() then
            local nearbyAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, 900)
            local nearbyEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)

            if #nearbyAlliedCreep > 0 then
                if utils.DropTowerAggro(bot, nearbyAlliedCreep) then
                    return
                else
                    -- otherwise, walk away, don't be that bot that takes tower damage over and over
                    local dist = GetUnitToUnitDistance(bot, hTower)
                    if dist < 900 then
                        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), hTower:GetLocation(), 900-dist))
                        return
                    end
                end
            else
                -- if we can't drop aggro, but tower is almost dead
                if hTower:GetHealth()/hTower:GetMaxHealth() < 0.1 and not modifiers.IsBuildingGlyphed(hTower) then
                    gHeroVar.HeroAttackUnit(bot, hTower, true)
                    return
                end

                -- otherwise, walk away, don't be that bot that takes tower damage over and over
                local dist = GetUnitToUnitDistance(bot, hTower)
                if dist < 900 then
                    gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), hTower:GetLocation(), 900-dist))
                    return
                end
            end
        -- else, tower is not attacking me
        else
            -- see if the tower has a target, we know it's not us, but is it any other unit?
            local bTowerHasTarget = false
            for i = 1, 5, 1 do
                local hTowerTarget = U.GetLaneTowerAttackTarget(U.GetOtherTeam(), getHeroVar("CurLane"), i)
                if utils.ValidTarget(hTowerTarget) and GetUnitToUnitDistance(bot, hTowerTarget) < 1200 then
                    -- make sure it is not another hero, unless illusion
                    if hTowerTarget:IsIllusion() or not hTowerTarget:IsHero() then
                        bTowerHasTarget = true
                        break
                    end
                end
            end
            
            -- tower has a target that's not us, attack it if we can
            if bTowerHasTarget and not modifiers.IsBuildingGlyphed(hTower) then
                gHeroVar.HeroAttackUnit(bot, hTower, true)
                return
            -- at this point, I have to be outside of tower range (otherwise it would be attacking me), and
            -- there is no friendly creep nearby or it would be being attacked
            else
                local nearbyAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, 900)
                local nearbyEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)

                if #nearbyEnemyCreep > 0 then
                    -- TODO: below should make exception for tanky high health regen heroes
                    -- like Timber, DK, Axe, Bristle, etc... probably using a flag like bot.CanTank
                    if #nearbyAlliedCreep > 0 then -- or bot.CanTank then
                        local creep, _ = utils.GetWeakestCreep(nearbyEnemyCreep)
                        if creep then
                            gHeroVar.HeroAttackUnit(bot, creep, true)
                            return
                        end
                    end
                end
            end
        end
    end

    if #Barracks > 0 then
        local hBarrackTarget = nil
        for _, barrack in pairs(Barracks) do
            if not modifiers.IsBuildingGlyphed(barrack) then
                hBarrackTarget = barrack

                local isMelee = string.find(barrack:GetUnitName(), "melee") 
                if isMelee then
                    break
                end
            end
        end

        if utils.ValidTarget(hBarrackTarget) then
            gHeroVar.HeroAttackUnit(bot, hBarrackTarget, true)
            return
        end
    end

    if #Shrines > 0 then
        -- if more than one, sort by lowest health
        hShrine = Shrines[1]

        if utils.ValidTarget(hShrine) and not modifiers.IsBuildingGlyphed(hShrine) then
            gHeroVar.HeroAttackUnit(bot, hShrine, true)
            return
        end
    end

    -- the only way to get here means we are near a tower which does not have a target
    -- and is not close to dying and we have no friendly creep near us
    bot.SelfRef:ClearMode()
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
    
    -- push enemies out of our base
    local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), getHeroVar("CurLane"), false)
    if enemyFrontier < 0.25 then
        return BOT_MODE_DESIRE_MODERATE
    end

    -- this is hero-specific push-lane determination
    local nearbyETowers = gHeroVar.GetNearbyEnemyTowers(bot, Max(750, bot:GetAttackRange()))
    if #nearbyETowers > 0 then
        if ( nearbyETowers[1]:GetHealth() / nearbyETowers[1]:GetMaxHealth() ) < 0.1 and
            not modifiers.IsBuildingGlyphed(nearbyETowers[1]) then
            return BOT_MODE_DESIRE_HIGH
        end

        if utils.IsTowerAttackingMe() and #gHeroVar.GetNearbyAlliedCreep(bot, 1000) == 0 then
            return BOT_MODE_DESIRE_NONE
        end
    end

    if #gHeroVar.GetNearbyAlliedCreep(bot, 1000) >= 1 and #gHeroVar.GetNearbyEnemies(bot, 1200) == 0 then
        return BOT_MODE_DESIRE_LOW
    end

    if bot.SelfRef:getCurrentMode():GetName() == "pushlane" then
        return bot.SelfRef:getCurrentModeValue()
    end

    return BOT_MODE_DESIRE_NONE
end

return X
