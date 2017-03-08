-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "ward"
end

function X:OnStart(myBot)
end

function X:OnEnd()
    setHeroVar("WardType", nil)
    setHeroVar("WardLocation", nil)
    setHeroVar("WardCheckTimer", GameTime())
end

function X:Think(bot)
    if utils.IsBusy(bot) then return end
    
    local wardType = getHeroVar("WardType") or "item_ward_observer"
    local dest = getHeroVar("WardLocation")
    if dest ~= nil then
        local dist = GetUnitToLocationDistance(bot, dest)
        if dist <= constants.WARD_CAST_DISTANCE then
            local ward = item_usage.HaveWard(wardType)
            if ward then
                gHeroVar.HeroPushUseAbilityOnLocation(bot, ward, dest, constants.WARD_CAST_DISTANCE)
                getHeroVar("Self"):ClearMode()
            end
        else
            bot:Action_MoveToLocation(dest)
        end
    end
end

function X:Desire(bot)
    if bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
    
    -- we need to lane first before we know where to ward properly
    if getHeroVar("CurLane") == nil or getHeroVar("CurLane") == 0 then
        return BOT_MODE_DESIRE_NONE
    end
    
    local nearbyEnemies = gHeroVar.GetNearbyEnemies(bot, bot:GetCurrentVisionRange())
    if #nearbyEnemies > 0 then
        return BOT_MODE_DESIRE_NONE
    end
    
    local WardCheckTimer = getHeroVar("WardCheckTimer")
    local bCheck = true
    local newTime = GameTime()
    
    if WardCheckTimer then
        bCheck, newTime = utils.TimePassed(WardCheckTimer, 1.0)
    end
    
    if bCheck then
        setHeroVar("WardCheckTimer", newTime)
        local ward = item_usage.HaveWard("item_ward_observer")
        if ward then
            local alliedMapWards = GetUnitList(UNIT_LIST_ALLIED_WARDS)
            if #alliedMapWards < 2 then --FIXME: don't hardcode.. you get more wards then you can use this way
                local wardLocs = utils.GetWardingSpot(getHeroVar("CurLane"))

                if wardLocs == nil or #wardLocs == 0 then return BOT_MODE_DESIRE_NONE end

                -- FIXME: Consider ward expiration time
                local wardLoc = nil
                for _, wl in ipairs(wardLocs) do
                    local bGoodLoc = true
                    for _, value in ipairs(alliedMapWards) do
                        if utils.GetDistance(value:GetLocation(), wl) < 1600 then
                            bGoodLoc = false
                        end
                    end
                    if bGoodLoc then
                        wardLoc = wl
                        break
                    end
                end

                if wardLoc ~= nil and utils.EnemiesNearLocation(bot, wardLoc, 2000) < 2 then
                    setHeroVar("WardType", ward:GetName())
                    setHeroVar("WardLocation", wardLoc)
                    return BOT_MODE_DESIRE_LOW 
                end
            end
        end
        
        return BOT_MODE_DESIRE_NONE
    end
    
    local me = getHeroVar("Self")
    if me:getCurrentMode():GetName() == "ward" then
        return me:getCurrentModeValue()
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X
