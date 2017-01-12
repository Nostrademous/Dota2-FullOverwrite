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
		nextmove = GetLocationAlongLane(npcBot.RetreatLane,Max(npcBot.RetreatPos-0.03,0.0))
	end
	
	if retreatAbility ~= nil then
		nextmove = GetLocationAlongLane(npcBot.RetreatLane,Max(npcBot.RetreatPos-0.10,0.0))
		npcBot:Action_UseAbilityOnLocation(retreatAbility, nextmove)
	end
	
	if UseForce(nextmove) then	
		npcBot:Action_MoveToLocation(nextmove)
	end
end

--------
for k,v in pairs( retreat_generic ) do	_G._savedEnv[k] = v end