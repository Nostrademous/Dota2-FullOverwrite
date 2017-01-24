-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "item_usage", package.seeall )

local utils = require( GetScriptDirectory().."/utility" )
local modifiers = require( GetScriptDirectory().."/modifiers" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
	local bot = GetBot()
	gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
	local bot = GetBot()
	return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

-- health and mana regen items
function UseRegenItems()
	local npcBot = GetBot()
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
		return nil
	end
	
	local Enemies = npcBot:GetNearbyHeroes(850, true, BOT_MODE_NONE)
	
	local bottle = utils.HaveItem(npcBot, "item_bottle")
    if bottle ~= nil and bottle:GetCurrentCharges() > 0 and not npcBot:HasModifier("modifier_bottle_regeneration") 
		and not npcBot:HasModifier("modifier_clarity_potion") and not npcBot:HasModifier("modifier_flask_healing") then
		
		if (not (npcBot:GetHealth() == npcBot:GetMaxHealth() and npcBot:GetMaxMana() == npcBot:GetMana())) and npcBot:HasModifier("modifier_fountain_aura_buff") then
			npcBot:Action_UseAbilityOnEntity(bottle, npcBot)
			return nil
		end
		
		if Enemies == nil or #Enemies == 0 then
			if ((npcBot:GetMaxHealth()-npcBot:GetHealth()) >= 100 and (npcBot:GetMaxMana()-npcBot:GetMana()) >= 60) or
				(npcBot:GetHealth() < 300 or npcBot:GetMana() < 200) then
				npcBot:Action_UseAbilityOnEntity(bottle, npcBot)
				return nil
			end
		end
	end
	
	if not npcBot:HasModifier("modifier_fountain_aura_buff") then

		local mekansm = utils.HaveItem(npcBot, "item_mekansm")
		local Allies = npcBot:GetNearbyHeroes(900, false, BOT_MODE_NONE)
		if mekansm ~= nil and mekansm:IsFullyCastable() then
			if (npcBot:GetHealth()/npcBot:GetMaxHealth()) < 0.15 then
				npcBot:Action_UseAbility(mekansm)
				return nil
			end
			if #Allies > 1 then
				for _, ally in pairs(Allies) do
					if (ally:GetHealth()/ally:GetMaxHealth()) < 0.15 then
						npcBot:Action_UseAbility(mekansm)
						return nil
					end
				end
			end
		end

		local clarity = utils.HaveItem(npcBot, "item_clarity")
		if clarity ~= nil then
			if (Enemies == nil or #Enemies == 0) then
				if (npcBot:GetMaxMana()-npcBot:GetMana()) > 200 and not npcBot:HasModifier("modifier_clarity_potion") and not modifiers.HasActiveDOTDebuff(npcBot)  then
					npcBot:Action_UseAbilityOnEntity(clarity, npcBot)
					return nil
				end
			end
		end
		
		local flask = utils.HaveItem(npcBot, "item_flask");
		if flask ~= nil then
			if (Enemies == nil or #Enemies == 0) then
				if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 400 and not npcBot:HasModifier("modifier_flask_healing") and not modifiers.HasActiveDOTDebuff(npcBot)  then
					npcBot:Action_UseAbilityOnEntity(flask, npcBot)
					return nil
				end
			end
		end
		
		local faerie = utils.HaveItem(npcBot, "item_faerie_fire");
		if faerie ~= nil then
			if (npcBot:GetHealth()/npcBot:GetMaxHealth()) < 0.15 and (utils.IsTowerAttackingMe(2.0) or utils.IsAnyHeroAttackingMe(1.0)) then
				npcBot:Action_UseAbility(faerie)
				return nil;
			end
		end
		
		local tango_shared = utils.HaveItem(npcBot, "item_tango_single");
		if tango_shared ~= nil  and tango_shared:IsFullyCastable() then
			if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 200 and not npcBot:HasModifier("modifier_tango_heal") then
				local trees = npcBot:GetNearbyTrees( 165 )
				if #trees > 0 then
					npcBot:Action_UseAbilityOnTree(tango_shared, trees[1])
				end
			end
		end
		
		local tango = utils.HaveItem(npcBot, "item_tango");
		if tango ~= nil and tango:IsFullyCastable() then
			if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 200 and not npcBot:HasModifier("modifier_tango_heal") then
				local trees = npcBot:GetNearbyTrees( 165 )
				if #trees > 0 then
					npcBot:Action_UseAbilityOnTree(tango, trees[1])
				end
			end
		end
	end
	
	return nil
end

function UseTeamItems()
	local npcBot = GetBot()
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
		return nil
	end

	if not npcBot:HasModifier("modifier_fountain_aura_buff") then
		local mekansm = utils.HaveItem(npcBot, "item_mekansm")
		local Allies = npcBot:GetNearbyHeroes(900, false, BOT_MODE_NONE)
		if mekansm ~= nil and mekansm:IsFullyCastable() then
			if (npcBot:GetHealth()/npcBot:GetMaxHealth()) < 0.15 then
				npcBot:Action_UseAbility(mekansm)
				return nil
			end
			if #Allies > 1 then
				for _, ally in pairs(Allies) do
					if (ally:GetHealth()/ally:GetMaxHealth()) < 0.15 then
						npcBot:Action_UseAbility(mekansm)
						return nil
					end
				end
			end
		end

		local arcane = utils.HaveItem(npcBot, "item_arcane_boots")
		if arcane ~= nil and arcane:IsFullyCastable() then
			if (npcBot:GetMaxMana() - npcBot:GetMana()) > 160 then
				npcBot:Action_UseAbility(arcane)
				return nil
			end
		end
	end
end

function UseMovementItems(location) 
	local npcBot = GetBot()
	local location = location or npcBot:GetLocation()
	
	if npcBot:IsChanneling() then
		return nil
	end
	
	local pb = utils.HaveItem(npcBot, "item_phase_boots")
	if pb ~= nil and pb:IsFullyCastable() then
		npcBot:Action_UseAbility(pb)
		return nil
	end

	local force = utils.HaveItem(npcBot, "item_force_staff")
	if force ~= nil and utils.IsFacingLocation(npcBot, location, 25) then
		npcBot:Action_UseAbilityOnEntity(force, npcBot)
		return nil
	end
	
	local hp = utils.HaveItem(npcBot, "item_hurricane_pike")
	if hp ~= nil and utils.IsFacingLocation(npcBot, location, 25) then
		npcBot:Action_UseAbilityOnEntity(hp, npcBot)
		return nil
	end
	
	local sb = utils.HaveItem(npcBot, "item_invis_sword")
	if sb ~= nil and sb:IsFullyCastable() then
		npcBot:Action_UseAbility(sb)
		return nil
	end
	
	local se = utils.HaveItem(npcBot, "item_silver_edge")
	if se ~= nil and se:IsFullyCastable() then
		npcBot:Action_UseAbility(se)
		return nil
	end
end

function UseDefensiveItems(enemy, triggerDistance) 
	local npcBot = GetBot()
	local location = location or npcBot:GetLocation()
	
	if npcBot:IsChanneling() then
		return nil
	end
	
	local hp = utils.HaveItem(npcBot, "item_hurricane_pike")
	
	if hp ~= nil and GetUnitToUnitDistance(npcBot, enemy) < triggerDistance then
		npcBot:Action_UseAbilityOnEntity(hp, enemy)
		return nil
	end
end

function UseTP()
	local npcBot = GetBot()
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
		return nil
	end
	
	local tp = utils.HaveItem(npcBot, "item_tpscroll")
	if tp ~= nil and (utils.HaveItem(npcBot, "item_travel_boots_1") or utils.HaveItem(npcBot, "item_travel_boots_2")) and
		GetUnitToLocationDistance(npcBot, utils.Fountain(GetTeam())) < 200 then
		npcBot:SellItem(tp)
		tp = nil
	end
	
	if tp == nil and utils.HaveTeleportation(npcBot) then
		tp = utils.HaveItem(npcBot, "item_travel_boots_1")
		if tp == nil then
			tp = utils.HaveItem(npcBot, "item_travel_boots_2")
		end
	end
	
	local dest = GetLocationAlongLane(getHeroVar("CurLane"), 0.5) -- 0.5 is basically 1/2 way down our lane
	if tp == nil and GetUnitToLocationDistance(npcBot, dest) > 3000 and 
		GetUnitToLocationDistance(npcBot, utils.Fountain(GetTeam())) < 200 and utils.NumberOfItems(npcBot) < 6 and
		npcBot:GetGold() > 50 then
		local savedValue = npcBot:GetNextItemPurchaseValue()
		npcBot:Action_PurchaseItem( "item_tpscroll" )
		tp = utils.HaveItem(npcBot, "item_tpscroll")
		npcBot:SetNextItemPurchaseValue(savedValue)
	end
		
	if tp ~= nil and tp:IsFullyCastable() then
		-- dest (below) should find farthest away tower to TP to in our assigned lane, even if tower is dead it will
		-- just default to closest location we can TP to in that direction	
		if GetUnitToLocationDistance(npcBot, dest) > 3000 and GetUnitToLocationDistance(npcBot, utils.Fountain(GetTeam())) < 200 then
			npcBot:Action_UseAbilityOnLocation(tp, dest);
		end
	end
end

function UseItems()
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return nil end

	local npcBot = GetBot()
	
	if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
		return nil
	end
	
	UseRegenItems()
	UseTeamItems()
	UseTP()
	
	local courier = utils.IsItemAvailable("item_courier")
	if courier ~= nil then
		npcBot:Action_UseAbility(courier)
		return nil
	end
	
	local flyingCourier = utils.IsItemAvailable("item_flying_courier")
	if flyingCourier ~= nil then
		npcBot:Action_UseAbility(flyingCourier)
		return nil
	end
	
	considerDropItems()
	
	return nil
end

function considerDropItems()
	swapBackpackIntoInventory()
	
	local npcBot = GetBot()
	
	for i = 6, 8, 1 do
		local bItem = npcBot:GetItemInSlot(i)
		if bItem ~= nil then
			for j = 1, 5, 1 do
				local item = npcBot:GetItemInSlot(j)
				if item ~= nil and item:GetName() == "item_branches" and bItem:GetName() ~= "item_branches" then
					npcBot:Action_SwapItems(i, j)
				end
			end
		end
	end
end

function swapBackpackIntoInventory()
	local npcBot = GetBot()
	if utils.NumberOfItems(npcBot) < 6 and utils.NumberOfItemsInBackpack(npcBot) > 0 then
		for i = 6, 8, 1 do
			if npcBot:GetItemInSlot(i) ~= nil then
				for j = 1, 5, 1 do
					local item = npcBot:GetItemInSlot(j)
					if item == nil then
						npcBot:Action_SwapItems(i, j)
					end
				end
			end
		end
	end
end

for k,v in pairs( item_usage ) do	_G._savedEnv[k] = v end