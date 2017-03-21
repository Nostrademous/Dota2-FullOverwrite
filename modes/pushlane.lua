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
end

function X:OnEnd()
end

function GetPushLaneFrontByTower(lane)
    local listBuildings = global_game_state.GetLatestVulnerableEnemyBuildings()
    
    if lane == LANE_MID then
        if utils.InTable(listBuildings, 4) then -- tier 1 mid
            return 0.597
        elseif utils.InTable(listBuildings, 5) then
            return -1
        elseif utils.InTable(listBuildings, 6) then
            return -1
        end
    elseif lane == LANE_TOP then
        if GetTeam() == TEAM_RADIANT then
            if utils.InTable(listBuildings, 1) then -- tier 1 top
                return 0.537
            elseif utils.InTable(listBuildings, 2) then
                return -1
            elseif utils.InTable(listBuildings, 3) then
                return -1
            end
        else
            if utils.InTable(listBuildings, 1) then -- tier 1 top
                return 0.687
            elseif utils.InTable(listBuildings, 2) then
                return -1
            elseif utils.InTable(listBuildings, 3) then
                return -1
            end
        end
    elseif lane == LANE_BOT then
        if GetTeam() == TEAM_RADIANT then
            if utils.InTable(listBuildings, 7) then -- tier 1 bot
                return 0.687
            elseif utils.InTable(listBuildings, 8) then
                return -1
            elseif utils.InTable(listBuildings, 9) then
                return -1
            end
        else
            if utils.InTable(listBuildings, 7) then
                return 0.537
            elseif utils.InTable(listBuildings, 8) then
                return -1
            elseif utils.InTable(listBuildings, 9) then
                return -1
            end
        end
    end
end

function X:Think(bot)

    if utils.IsBusy(bot) then return end

    if utils.IsCrowdControlled(bot) then return end

    local Towers = gHeroVar.GetNearbyEnemyTowers(bot, 900)
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
    local myFrontier = GetLaneFrontAmount(GetTeam(), getHeroVar("CurLane"), true)
    local frontier = Min(Min(1.0, enemyFrontier), myFrontier)
    local dest = GetLocationAlongLane(getHeroVar("CurLane"), frontier)
    
    local nearbyAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, 900)
    local nearbyEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)

    if utils.IsTowerAttackingMe() and #nearbyAlliedCreep > 0 then
        if utils.DropTowerAggro(bot, nearbyAlliedCreep) then
            return
        else
            local dist = GetUnitToUnitDistance(bot, Towers[1])
            if dist < 900 then
                gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), Towers[1]:GetLocation(), 900-dist))
                return
            end
        end
    end

    if #Towers > 0 and Towers[1]:GetHealth()/Towers[1]:GetMaxHealth() < 0.1 and
        not Towers[1]:HasModifier("modifier_fountain_glyph") then
        gHeroVar.HeroAttackUnit(bot, Towers[1], false)
        return
    end

    -- TODO: should be reworked with proper tower aggro thinking
    if #nearbyEnemyCreep > 0 then
        if #nearbyAlliedCreep > 0 or frontier < 0.25 then
            if #Towers > 0 then
                local dist = GetUnitToUnitDistance(bot, Towers[1])
                if dist < 900 then
                    -- local towerSafeDist = GetPushLaneFrontByTower(getHeroVar("CurLane"))
                    -- if towerSafeDist == -1 then
                        -- local eFront = GetLaneFrontAmount(utils.GetOtherTeam(), getHeroVar("CurLane"), false)
                        -- utils.pause(eFront, ", Dist: ", utils.GetDistance(GetLocationAlongLane(getHeroVar("CurLane"), eFront), GetLocationAlongLane(getHeroVar("CurLane"), eFront-0.01)))
                    -- end
                    -- gHeroVar.HeroMoveToLocation(bot, GetLocationAlongLane(getHeroVar("CurLane"), Max(towerSafeDist, enemyFrontier)))
                    
                    gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), Towers[1]:GetLocation(), 900-dist))
                    return
                end
            else
                local creep, _ = utils.GetWeakestCreep(nearbyEnemyCreep)
                if creep then
                    gHeroVar.HeroAttackUnit(bot, creep, true)
                    return
                end
            end
        else
            bot.SelfRef:ClearMode()
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
                if dist < 750 then
                    gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), Towers[1]:GetLocation(), 750-dist))
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

    gHeroVar.HeroMoveToLocation(bot, dest)
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
        return BOT_MODE_DESIRE_HIGH
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

    if #gHeroVar.GetNearbyAlliedCreep(bot, 1000) >= 1 and #gHeroVar.GetNearbyEnemies(bot, 1200) == 0 then
        return BOT_MODE_DESIRE_MODERATE
    end

    if bot.SelfRef:getCurrentMode():GetName() == "pushlane" then
        return bot.SelfRef:getCurrentModeValue()
    end

    return BOT_MODE_DESIRE_NONE
end

return X