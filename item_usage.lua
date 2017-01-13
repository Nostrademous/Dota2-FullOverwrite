-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

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
		if (Enemies==nil or #Enemies==0) and not npcBot:HasModifier("modifier_fountain_aura") then
			if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 400 and not npcBot:HasModifier("modifier_flask_healing") then
				npcBot:Action_UseAbilityOnEntity(flask, npcBot);
				return nil
			end
		end
	end
	
	local clarity = utils.IsItemAvailable("item_clarity");
    if clarity ~= nil then
		if (Enemies==nil or #Enemies==0) and not npcBot:HasModifier("modifier_fountain_aura") then
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
	
	local faerie = utils.IsItemAvailable("item_faerie_fire");
    if faerie ~= nil then
		if (npcBot:GetHealth()/npcBot:GetMaxHealth()) < 0.15 and (utils.IsTowerAttackingMe(2.0) or utils.IsAnyHeroAttackingMe(1.0)) then
			npcBot:Action_UseAbility(faerie);
			return nil;
		end
	end
	
	local arcane = utils.IsItemAvailable("item_arcane_boots");
    if arcane ~= nil then
		if (npcBot:GetMaxMana() - npcBot:GetMana()) > 160 then
			npcBot:Action_UseAbility(arcane);
			return nil;
		end
	end
	
	local tp = utils.IsItemAvailable("item_tpscroll");
	if tp ~= nil then
		-- dest (below) should find farthest away tower to TP to in our assigned lane, even if tower is dead it will
		-- just default to closest location we can TP to in that direction
		local dest = GetLocationAlongLane(npcBot.CurLane, 0.5); -- 0.5 is basically 1/2 way down our lane
		if GetUnitToLocationDistance(npcBot, utils.Fountain(GetTeam())) < 2000 then
			npcBot:Action_UseAbilityOnLocation(tp, dest);
		-- FIXME: Sell if we have BoTs and are near a shop
		--	npcBot:Action_SellItem(tp);
		end
	end
	
	local tango_shared = utils.IsItemAvailable("item_tango_single");
    if tango_shared ~= nil then
		if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 200 and not npcBot:HasModifier("modifier_tango_heal") then
			local trees = npcBot:GetNearbyTrees( 165 );
			if #trees > 0 then
				npcBot:Action_UseAbilityOnTree(tango, trees[1])
			end
		end
	end
	
	local tango = utils.IsItemAvailable("item_tango");
    if tango ~= nil then
		if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 200 and not npcBot:HasModifier("modifier_tango_heal") then
			local trees = npcBot:GetNearbyTrees( 165 );
			if #trees > 0 then
				npcBot:Action_UseAbilityOnTree(tango, trees[1])
			end
		end
	end
	
	return nil
end

for k,v in pairs( item_usage ) do	_G._savedEnv[k] = v end