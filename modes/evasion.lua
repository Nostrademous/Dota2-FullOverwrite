-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
local utils     = require( GetScriptDirectory().."/utility" )
local mods      = require( GetScriptDirectory().."/modifiers" )
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
    if mods.IsRuptured(bot) then
        local tp = utils.IsItemAvailable("item_tpscroll")
        if tp then
            bot:Action_UseAbilityOnLocation( tp, utils.Fountain( GetTeam() ) )
        end
    end
end

function X:Desire(bot)
    -- NOTE: a projectile will be a table with { "location", "ability", "velocity", "radius", "playerid" }
    local projectiles = gHeroVar.GetGlobalVar("BadProjectiles")
    if #projectiles > 0 then
        for _, projectile in pairs(projectiles) do
            --utils.myPrint("Ability: ", projectile.ability:GetName())
            --utils.myPrint("Velocity: ", projectile.velocity)
        end
    end
    
    -- NOTE: the tracking projectile will be a table with { "location", "ability", "is_dodgeable", "is_attack" }.
    --local listTrackingProjectiles = bot:GetIncomingTrackingProjectiles()
    --for _, projectile in pairs(listTrackingProjectiles) do
    --    utils.myPrint("Tracking Ability: ", projectile.ability:GetName(), ", Dodgeable: ", projectile.is_dodgeable)
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