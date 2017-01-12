-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "retreat_generic", package.seeall )

local utils = require( GetScriptDirectory().."/utility")

function OnStart(npcBot)
	utils.IsInLane()
end

local function Updates(npcBot)
	npcBot.RetreatPos = utils.PositionAlongLane(npcBot, npcBot.RetreatLane);
end

local function UseForce(nextmove)
	local npcBot = GetBot();

	local force = utils.IsItemAvailable("item_force_staff");
	
	if force~=nil and utils.IsFacingLocation(npcBot, nextmove, 25)  then
		npcBot:Action_UseAbilityOnEntity(force, npcBot);
		return false;
	end
	return true;
end

function Think(npcBot, retreatAbility)
	Updates(npcBot)
	
	local nextmove = GetLocationAlongLane(npcBot.RetreatLane, 0.0)
	if npcBot.IsInLane then
		nextmove = GetLocationAlongLane(npcBot.RetreatLane, Max(npcBot.RetreatPos-0.03, 0.0))
	else
		nextmove = utils.Fountain(GetTeam())
	end
	
	if retreatAbility ~= nil then
		-- same name for bot AM and QoP, "tooltip_range" for "riki_blink_strike"
		local value = 0.03
		if (utils.GetHeroName(npcBot) == "antimage" or utils.GetHeroName(npcBot) == "queen_of_pain") then
			value = retreatAbility:GetSpecialValueInt("blink_range")
			-- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
			local scale = utils.GetDistance(GetLocationAlongLane(npcBot.CurLane, 0.5), GetLocationAlongLane(npcBot.CurLane, 0.49))
			value = (value / scale)*0.01 - 0.001
			nextmove = GetLocationAlongLane(npcBot.RetreatLane, Max(npcBot.RetreatPos-value, 0.0))
			npcBot:Action_UseAbilityOnLocation(retreatAbility, nextmove)
		elseif utils.GetHeroName(npcBot) == "riki" then
			value = retreatAbility:GetSpecialValueInt("tooltip_range")
			-- below I test how far in units is a single 0.01 move in terms of GetLocationAlongLane()
			local scale = utils.GetDistance(GetLocationAlongLane(npcBot.CurLane, 0.5), GetLocationAlongLane(npcBot.CurLane, 0.49))
			value = (value / scale)*0.01 - 0.001
			nextmove = GetLocationAlongLane(npcBot.RetreatLane, Max(npcBot.RetreatPos-value, 0.0))
			--FIXME: UseAbilityOnEntity() not Location() npcBot:Action_UseAbilityOnLocation(retreatAbility, nextmove)
		end
		
	end
	
	UseForce(nextmove)
	npcBot:Action_MoveToLocation(nextmove)
end

--------
for k,v in pairs( retreat_generic ) do	_G._savedEnv[k] = v end