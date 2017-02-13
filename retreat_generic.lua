-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "retreat_generic", package.seeall )

require( GetScriptDirectory().."/item_usage" )
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

function OnStart(bot)
    utils.IsInLane()
end

local function Updates(bot)
    if getHeroVar("IsInLane") then
        setHeroVar("RetreatPos", utils.PositionAlongLane(bot, getHeroVar("RetreatLane")))
    end
end

function Think(bot, loc)
    Updates(bot)

    local nextmove = nil
    if loc ~= nil then
        nextmove = loc
    else
        if getHeroVar("IsInLane") then
            nextmove = GetLocationAlongLane(getHeroVar("RetreatLane"), Max(getHeroVar("RetreatPos")-0.03, 0.0))
        else
            nextmove = utils.Fountain(GetTeam())
        end
    end

    local retreatAbility = getHeroVar("HasMovementAbility")
    if retreatAbility ~= nil and retreatAbility:IsFullyCastable() then
        -- same name for bot AM and QoP, "tooltip_range" for "riki_blink_strike"
        local value = 0.03
        if (utils.GetHeroName(bot) == "antimage" or utils.GetHeroName(bot) == "queen_of_pain") then
            value = retreatAbility:GetSpecialValueInt("blink_range")
            -- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
            local scale = utils.GetDistance(GetLocationAlongLane(getHeroVar("RetreatLane"), 0.5), GetLocationAlongLane(getHeroVar("RetreatLane"), 0.49))
            value = ((value - 15) / scale)*0.01 -- we subtract 15 to give ourselves a little rounding wiggle room
            nextmove = GetLocationAlongLane(getHeroVar("RetreatLane"), Max(getHeroVar("RetreatPos")-value, 0.0))
            bot:Action_UseAbilityOnLocation(retreatAbility, nextmove)
        elseif utils.GetHeroName(bot) == "riki" then
            value = retreatAbility:GetSpecialValueInt("tooltip_range")
            -- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
            local scale = utils.GetDistance(GetLocationAlongLane(getHeroVar("RetreatLane"), 0.5), GetLocationAlongLane(getHeroVar("RetreatLane"), 0.49))
            value = ((value - 15) / scale)*0.01 -- we subtract 15 to give ourselves a little rounding wiggle room
            nextmove = GetLocationAlongLane(getHeroVar("RetreatLane"), Max(getHeroVar("RetreatPos")-value, 0.0))
            --FIXME: UseAbilityOnEntity() not Location() bot:Action_UseAbilityOnLocation(retreatAbility, nextmove)
        end
    end

    if item_usage.UseMovementItems(nextmove) then return end
    
    if getHeroVar("IsInLane") then
        --utils.myPrint("generic retreat - in Lane - loc <", nextmove[1], ", ", nextmove[2], ">")
        gHeroVar.HeroMoveToLocation(bot, nextmove)
    else
        --utils.myPrint("generic retreat - not in Lane - loc <", nextmove[1], ", ", nextmove[2], ">")
        utils.MoveSafelyToLocation(bot, nextmove)
    end
end

--------
for k,v in pairs( retreat_generic ) do _G._savedEnv[k] = v end