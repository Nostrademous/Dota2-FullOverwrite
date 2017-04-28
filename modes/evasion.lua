-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
require( GetScriptDirectory().."/modifiers" )
require( GetScriptDirectory().."/item_usage" )

local utils     = require( GetScriptDirectory().."/utility" )
local gHeroVar  = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "evasion"
end

function X:OnStart(myBot)
end

function X:OnEnd()
end

function X:Think(bot)
    if modifiers.IsRuptured(bot) then
        local tp = utils.IsItemAvailable("item_tpscroll")
        if tp then
            gHeroVar.HeroUseAbilityOnLocation(bot,  tp, utils.Fountain( GetTeam() ) )
            return
        else
            utils.myPrint("FIXME: we are ruptured and don't have TP... need to implement")
            
            -- consider using abilities
            local bAbilityQueued = getHeroVar("AbilityUsageClass"):AbilityUsageThink(bot)
            if bAbilityQueued then return end

            -- consider using items
            if item_usage.UseItems() then return end
        end
    end
    
    local aoes = gHeroVar.GetGlobalVar("AOEZones")
    if #aoes > 0 then
        for _, aoe in pairs(aoes) do
            local distFromCenter = GetUnitToLocationDistance(bot, aoe.location)
            if distFromCenter < aoe.radius then
                local escapeDist = aoe.radius - distFromCenter
                local escapeLoc = utils.VectorAway(bot:GetLocation(), aoe.location, escapeDist + 100)
                gHeroVar.HeroMoveToLocation(bot, escapeLoc)
                return
            end
        end
    end
    
    local linProjs = gHeroVar.GetGlobalVar("BadProjectiles")
    if # linProjs > 0 then
        local projName = nil
        local projRadius = 0
        local projVelocity = nil
        local projLocation = nil
        local projMinDist = 100000
    
        for _, linProj in pairs(linProjs) do
            local distFromMe = GetUnitToLocationDistance(bot, linProj.location)
            if distFromMe < 2500 and distFromMe < projMinDist then
                projMinDist   = distFromMe
                projName      = linProj.ability
                projRadius    = linProj.radius
                projVelocity  = linProj.velocity
                projLocation  = linProj.location
            end
        end
        
        if projMinDist < 2500 then
            local a = projVelocity.y/projVelocity.x
            local b = projLocation.y - a * projLocation.x
            local c = bot:GetLocation().x
            local d = bot:GetLocation().y
            local h = math.sqrt(c * c + (b - d) * (b - d) - (a * (b - d) - c) * (a * (b - d) -c )/(a * a + 1))
            local projSpeed = math.sqrt(projVelocity.x * projVelocity.x + projVelocity.y * projVelocity.y)
            
            if h <= (projRadius + 150) then
                local angle = bot:GetFacing()
                local speed = bot:GetCurrentMovementSpeed()
                local radians = angle * math.pi / 180
                for i = 1, 30, 1 do -- do 30 3-degree steps (max 90 degrees) in both directions to find escape
                    radians = (angle + i * 3 ) * math.pi / 180
                    c = bot:GetLocation().x + math.cos(radians) * speed * projMinDist/projSpeed
                    d = bot:GetLocation().y + math.sin(radians) * speed * projMinDist/projSpeed
                    h = math.sqrt(c*c + (b - d) * (b - d) - (a*(b-d) -c)*(a*(b-d) -c)/(a*a +1))
                    if h > (projRadius + 150) then
                        gHeroVar.HeroMoveToLocation(bot, Vector(c, d))
                        return
                    end
                    
                    radians = (angle - i * 3) * math.pi / 180;
                    c = bot:GetLocation().x + math.cos(radians) * speed * projMinDist/projSpeed
                    d = bot:GetLocation().y + math.sin(radians) * speed * projMinDist/projSpeed
                    h = math.sqrt(c*c + (b - d) * (b - d) - (a*(b-d) -c)*(a*(b-d) -c)/(a*a +1))
                    if h > (projRadius + 150) then
                        gHeroVar.HeroMoveToLocation(bot, Vector(c, d))
                        return
                    end
                end
            end
        end
    end
end

function X:Desire(bot)
    if modifiers.IsRuptured(bot) then
        bot.DontMove = true
        return BOT_MODE_DESIRE_ABSOLUTE
    else
        bot.DontMove = false
    end
    
    -- NOTE: a projectile will be a table with { "location", "ability", "velocity", "radius", "playerid" }
    local projectiles = gHeroVar.GetGlobalVar("BadProjectiles")
    if #projectiles > 0 then
        for _, projectile in pairs(projectiles) do
            --utils.myPrint("Ability: ", projectile.ability:GetName())
            --utils.myPrint("Velocity: ", projectile.velocity)
            local distFromMe = GetUnitToLocationDistance(bot, projectile.location)
            if distFromMe < 1500 then
                return BOT_MODE_DESIRE_ABSOLUTE
            elseif distFromMe < 2500 then
                return BOT_MODE_DESIRE_VERYHIGH
            end
        end
    end
    
    -- NOTE: the tracking projectile will be a table with { "location", "ability", "is_dodgeable", "is_attack" }.
    --local listTrackingProjectiles = bot:GetIncomingTrackingProjectiles()
    --if #listTrackingProjectiles > 0 then
    --    for _, projectile in pairs(listTrackingProjectiles) do
    --    utils.myPrint("Tracking Ability: ", projectile.ability:GetName(), ", Dodgeable: ", projectile.is_dodgeable)
    --    end
    --end
    
    -- NOTE: an aoe will be table with { "location", "ability", "caster", "radius", "playerid" }.    
    local aoes = gHeroVar.GetGlobalVar("AOEZones")
    if #aoes > 0 then
        for _, aoe in pairs(aoes) do
            if GetUnitToLocationDistance(bot, aoe.location) < (aoe.radius+bot:GetBoundingRadius()) then
                return BOT_MODE_DESIRE_ABSOLUTE
            end
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X