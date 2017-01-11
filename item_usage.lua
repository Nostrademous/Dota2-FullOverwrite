_G._savedEnv = getfenv()
module( "item_usage", package.seeall )

local utils = require( GetScriptDirectory().."/utility" )

function UseItems()
	local npcBot = GetBot();
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
		return nil
	end
	
	local courier = utils.IsItemAvailable("item_courier");
	if courier ~= nil then
		npcBot:Action_UseAbility(courier);
		return nil
	end
	
	local flyingCourier = utils.IsItemAvailable("item_flying_courier");
	if flyingCourier ~= nil then
		npcBot:Action_UseAbility(flyingCourier);
		return nil
	end
	
	local Enemies = npcBot:GetNearbyHeroes(850,true,BOT_MODE_NONE);
	
	local flask = utils.IsItemAvailable("item_flask");
    if flask ~= nil then
		if Enemies==nil or #Enemies==0 then
			if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 400 and not npcBot:HasModifier("modifier_flask_healing") then
				npcBot:Action_UseAbilityOnEntity(flask, npcBot);
				return nil
			end
		end
	end
	
	local clarity = utils.IsItemAvailable("item_clarity");
    if clarity ~= nil then
		if Enemies==nil or #Enemies==0 then
			if (npcBot:GetMaxMana()-npcBot:GetMana()) > 200 and not npcBot:HasModifier("modifier_clarity_potion") then
				npcBot:Action_UseAbilityOnEntity(clarity, npcBot);
				return nil
			end
		end
	end
	
	local bottle = utils.IsItemAvailable("item_bottle");
    if bottle ~= nil and bottle:GetCurrentCharges() > 0 and not npcBot:HasModifier("modifier_bottle_regeneration") 
		and not npcBot:HasModifier("modifier_clarity_potion") and not npcBot:HasModifier("modifier_flask_healing") then
		
		if Enemies==nil or #Enemies==0 then
			if (npcBot:GetMaxHealth()-npcBot:GetHealth()) >= 100 and (npcBot:GetMaxMana()-npcBot:GetMana()) >= 60 then
				npcBot:Action_UseAbilityOnEntity(bottle, npcBot);
				return nil
			end
		end
	end
	
	--[[ FIXME: Check which tower is farthest away in our lane and make sure we are "LANING"
	local tp = utils.IsItemAvailable("item_tpscroll");
	if tp ~= nil then
		local dest = GetLocationAlongLane(npcBot.CurLane, 0.5);
		if GetUnitToLocationDistance(npcBot, utils.Fountain(GetTeam())) < 2000 then
			npcBot:Action_UseAbilityOnLocation(tp, dest);
		elseif not (npcBot:IsUsingAbility() or npcBot:IsChanneling()) then
			-- FIXME: Sell if we have BoTs
			npcBot:Action_SellItem(tp);
		end
	end
	--]]
	
	return nil
end

for k,v in pairs( item_usage ) do	_G._savedEnv[k] = v end