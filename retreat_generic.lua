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

function OnStart(npcBot)
	utils.IsInLane()
end

local function Updates(npcBot)
	setHeroVar("RetreatPos", utils.PositionAlongLane(npcBot, getHeroVar("RetreatLane")))
end

function Think(npcBot, loc)
	Updates(npcBot)
	
	local nextmove = GetLocationAlongLane(getHeroVar("CurLane"), 0.0)
	if loc ~= nil then
		nextmove = loc
	else
		if getHeroVar("IsInLane") then
			nextmove = GetLocationAlongLane(getHeroVar("CurLane"), Max(getHeroVar("RetreatPos")-0.03, 0.0))
		else
			nextmove = utils.Fountain(GetTeam())
		end
	end
	
	local retreatAbility = getHeroVar("HasMovementAbility")
	if retreatAbility ~= nil and retreatAbility:IsFullyCastable() then
		-- same name for bot AM and QoP, "tooltip_range" for "riki_blink_strike"
		local value = 0.03
		if (utils.GetHeroName(npcBot) == "antimage" or utils.GetHeroName(npcBot) == "queen_of_pain") then
			value = retreatAbility:GetSpecialValueInt("blink_range")
			-- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
			local scale = utils.GetDistance(GetLocationAlongLane(getHeroVar("CurLane"), 0.5), GetLocationAlongLane(getHeroVar("CurLane"), 0.49))
			value = ((value - 15) / scale)*0.01 -- we subtract 15 to give ourselves a little rounding wiggle room
			nextmove = GetLocationAlongLane(getHeroVar("CurLane"), Max(getHeroVar("RetreatPos")-value, 0.0))
			npcBot:Action_UseAbilityOnLocation(retreatAbility, nextmove)
		elseif utils.GetHeroName(npcBot) == "riki" then
			value = retreatAbility:GetSpecialValueInt("tooltip_range")
			-- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
			local scale = utils.GetDistance(GetLocationAlongLane(getHeroVar("CurLane"), 0.5), GetLocationAlongLane(getHeroVar("CurLane"), 0.49))
			value = ((value - 15) / scale)*0.01 -- we subtract 15 to give ourselves a little rounding wiggle room
			nextmove = GetLocationAlongLane(getHeroVar("CurLane"), Max(getHeroVar("RetreatPos")-value, 0.0))
			--FIXME: UseAbilityOnEntity() not Location() npcBot:Action_UseAbilityOnLocation(retreatAbility, nextmove)
		end
		
	end

	item_usage.UseMovementItems(nextmove)
    if getHeroVar("IsInLane") then
        npcBot:Action_MoveToLocation(nextmove)
    else
        utils.MoveSafelyToLocation(npcBot, nextmove)
    end
end

--------
for k,v in pairs( retreat_generic ) do	_G._savedEnv[k] = v end