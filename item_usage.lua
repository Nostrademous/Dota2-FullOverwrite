-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "item_usage", package.seeall )

require( GetScriptDirectory().."/modifiers" )

local utils = require( GetScriptDirectory().."/utility" )
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
    
    -- if we are full health and full mana, exit early
    if npcBot:GetHealth() == npcBot:GetMaxHealth() and npcBot:GetMana() == npcBot:GetMaxMana() then return nil end
    
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
		
		local urn = utils.HaveItem(npcBot, "item_urn_of_shadows")
        if urn ~= nil and urn:GetCurrentCharges() > 0 then
		    if (Enemies == nil or #Enemies == 0) then
                if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 400 and not npcBot:HasModifier("modifier_item_urn_heal") and not modifiers.HasActiveDOTDebuff(npcBot)  then
                    npcBot:Action_UseAbilityOnEntity(urn, npcBot)
                    return nil
                end
            end
        end

        local faerie = utils.HaveItem(npcBot, "item_faerie_fire");
        if faerie ~= nil then
            if (npcBot:GetHealth()/npcBot:GetMaxHealth()) < 0.15 and (utils.IsTowerAttackingMe(2.0) or utils.IsAnyHeroAttackingMe(1.0)) then
                npcBot:Action_UseAbility(faerie)
                return nil
            end
        end

        local tango_shared = utils.HaveItem(npcBot, "item_tango_single");
        if tango_shared ~= nil  and tango_shared:IsFullyCastable() and (not getHeroVar("IsRetreating")) then
            if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 200 and not npcBot:HasModifier("modifier_tango_heal") then
                local tree = utils.GetNearestTree(npcBot)
                if tree ~= nil then
                    npcBot:Action_UseAbilityOnTree(tango_shared, tree)
                    return true
                end
            end
        end

        local tango = utils.HaveItem(npcBot, "item_tango");
        if tango ~= nil and tango:IsFullyCastable() and (not getHeroVar("IsRetreating")) then
            if (npcBot:GetMaxHealth()-npcBot:GetHealth()) > 200 and not npcBot:HasModifier("modifier_tango_heal") then
                local tree = utils.GetNearestTree(npcBot)
                if tree ~= nil then
                    npcBot:Action_UseAbilityOnTree(tango, tree)
                    return true
                end
            end
        end
    end

    return nil
end

function UseRegenItemsOnAlly()
    local npcBot = GetBot()

    if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
        return nil
    end
    
    local Enemies = npcBot:GetNearbyHeroes(850, true, BOT_MODE_NONE)
	local Allies = npcBot:GetNearbyHeroes(850, false,  BOT_MODE_NONE)
	
	local lowestHealthAlly = nil
	local lowestManaAlly = nil
	local bottleTargetAlly = nil
    for _,ally in pairs(Allies) do
        if lowestHealthAlly == nil then lowestHealthAlly = ally end
        if lowestManaAlly == nil then lowestManaAlly = ally end
        if bottleTargetAlly == nil then bottleTargetAlly = ally end
		
        local allyHealthPct = ally:GetHealth()/ally:GetMaxHealth()
        local allyManaPct = ally:GetMana()/ally:GetMaxMana()
		
        local targetHealthPct = lowestHealthAlly:GetHealth()/lowestHealthAlly:GetMaxHealth()
        local targetManaPct = lowestManaAlly:GetMana()/lowestManaAlly:GetMaxMana()
		
        if allyHealthPct < targetHealthPct then lowestHealthAlly = ally end -- get lowest health ally
        if allyManaPct < targetManaPct then lowestManaAlly = ally end -- get lowest mana ally
        if allyManaPct < targetManaPct and allyHealthPct < targetHealthPct then bottleTargetAlly = ally end -- get lowest mana and lowest health ally
    end

    local bottle = utils.HaveItem(npcBot, "item_bottle")
    if bottle ~= nil and bottle:GetCurrentCharges() > 0 and not bottleTargetAlly:HasModifier("modifier_bottle_regeneration") 
        and not bottleTargetAlly:HasModifier("modifier_clarity_potion") and not bottleTargetAlly:HasModifier("modifier_flask_healing")
        and (not utils.HaveItem(bottleTargetAlly, "item_bottle"))   then

        if (not (bottleTargetAlly:GetHealth() == bottleTargetAlly:GetMaxHealth() and bottleTargetAlly:GetMaxMana() == bottleTargetAlly:GetMana())) and bottleTargetAlly:HasModifier("modifier_fountain_aura_buff") then
            npcBot:Action_UseAbilityOnEntity(bottle, bottleTargetAlly)
            return nil
        end

        if Enemies == nil or #Enemies == 0 then
            if ((bottleTargetAlly:GetMaxHealth()-bottleTargetAlly:GetHealth()) >= 100 and (bottleTargetAlly:GetMaxMana()-bottleTargetAlly:GetMana()) >= 60) or
                (bottleTargetAlly:GetHealth() < 300 or bottleTargetAlly:GetMana() < 200) then
                npcBot:Action_UseAbilityOnEntity(bottle, bottleTargetAlly)
                return nil
            end
        end
    end

    if (lowestManaAlly and (not lowestManaAlly:HasModifier("modifier_fountain_aura_buff")))  then

        local clarity = utils.HaveItem(npcBot, "item_clarity")
        if clarity ~= nil and (not utils.HaveItem(lowestManaAlly, "item_clarity")) then
            if (Enemies == nil or #Enemies == 0) then
                if (lowestManaAlly:GetMaxMana()-lowestManaAlly:GetMana()) > 200 and not lowestManaAlly:HasModifier("modifier_clarity_potion") and not modifiers.HasActiveDOTDebuff(lowestManaAlly)  then
                    npcBot:Action_UseAbilityOnEntity(clarity, lowestManaAlly)
                    return nil
                end
            end
        end
    end

    if (lowestHealthAlly and (not lowestHealthAlly:HasModifier("modifier_fountain_aura_buff")))  then
        local flask = utils.HaveItem(npcBot, "item_flask");
        if flask ~= nil and (not utils.HaveItem(lowestHealthAlly, "item_flask")) then
            if (Enemies == nil or #Enemies == 0) then
                if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 400 and not lowestHealthAlly:HasModifier("modifier_flask_healing") and not modifiers.HasActiveDOTDebuff(lowestHealthAlly)  then
                    npcBot:Action_UseAbilityOnEntity(flask, lowestHealthAlly)
                    return nil
                end
            end
        end
		
		local tango = utils.HaveItem(npcBot, "item_tango");
        if tango ~= nil and tango:IsFullyCastable() and (not getHeroVar("IsRetreating")) and (not (utils.HaveItem(lowestHealthAlly, "item_tango") or utils.HaveItem(lowestHealthAlly, "item_tango_single")) )then
            if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 200 and not lowestHealthAlly:HasModifier("modifier_tango_heal") then
                local tree = utils.GetNearestTree(npcBot)
                if tree ~= nil then
                    npcBot:Action_UseAbilityOnEntity(tango, lowestHealthAlly)
                    return true
                end
            end
        end
		
        local urn = utils.HaveItem(npcBot, "item_urn_of_shadows")
        if urn ~= nil and urn:GetCurrentCharges() > 0 then
		    if (Enemies == nil or #Enemies == 0) then
                if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 400 and not lowestHealthAlly:HasModifier("modifier_item_urn_heal") and not modifiers.HasActiveDOTDebuff(lowestHealthAlly)  then
                    npcBot:Action_UseAbilityOnEntity(urn, lowestHealthAlly)
                    return nil
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

    UseSilverEdge()
    
    UseShadowBlade()

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

function UseBuffItems()
    local npcBot = GetBot()

    if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
        return nil
    end
    
    UseTomeOfKnowledge()
end

function UseTP(lane)
    local lane = lane or getHeroVar("CurLane")
    local npcBot = GetBot()
    local tpSwap = false
    local backPackSlot = 0
    
    if DotaTime() < 10 then return nil end

    if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
        return nil
    end

    local tp = utils.HaveItem(npcBot, "item_tpscroll")
    if tp ~= nil and (utils.HaveItem(npcBot, "item_travel_boots_1") or utils.HaveItem(npcBot, "item_travel_boots_2")) 
        and npcBot:DistanceFromFountain() < 200 then
        npcBot:SellItem(tp)
        tp = nil
    end

    if tp == nil and utils.HaveTeleportation(npcBot) then
        tp = utils.HaveItem(npcBot, "item_travel_boots_1")
        if tp == nil then
            tp = utils.HaveItem(npcBot, "item_travel_boots_2")
        end
    end

    local dest = GetLocationAlongLane(lane, 0.5) -- 0.5 is basically 1/2 way down our lane
    if tp == nil and GetUnitToLocationDistance(npcBot, dest) > 3000
        and npcBot:DistanceFromFountain() < 200
        and npcBot:GetGold() > 50 then
        local savedValue = npcBot:GetNextItemPurchaseValue()
        backPackSlot = utils.GetFreeSlotInBackPack(npcBot)
        if utils.NumberOfItems(npcBot) == 6 and backPackSlot > 0 then 
            npcBot:ActionImmediate_SwapItems(0, backPackSlot)
            tpSwap = true
        end
        npcBot:ActionImmediate_PurchaseItem( "item_tpscroll" )
        tp = utils.HaveItem(npcBot, "item_tpscroll")
        npcBot:SetNextItemPurchaseValue(savedValue)
    end

    if tp ~= nil and tp:IsFullyCastable() then
        -- dest (below) should find farthest away tower to TP to in our assigned lane, even if tower is dead it will
        -- just default to closest location we can TP to in that direction
        if GetUnitToLocationDistance(npcBot, dest) > 3000 and npcBot:DistanceFromFountain() < 200 then
            npcBot:Action_UseAbilityOnLocation(tp, dest);
            if tpSwap then 
                npcBot:ActionImmediate_SwapItems(0, backPackSlot)
            end
        end
    end
end

function UseItems()
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return nil end

    local npcBot = GetBot()

    if npcBot:IsChanneling() or npcBot:IsUsingAbility() then
        return nil
    end

    UseBuffItems()
    
    local bRet = UseRegenItems()
    if bRet then return true end
	
    local bRetOnAlly = UseRegenItemsOnAlly()
	if bRetOnAlly then return true end
    
    UseTeamItems()
    
    UseTP()
    

    local courier = utils.IsItemAvailable("item_courier")
    if courier ~= nil then
        npcBot:ActionPush_UseAbility(courier)
        return nil
    end

    local flyingCourier = utils.IsItemAvailable("item_flying_courier")
    if flyingCourier ~= nil then
        npcBot:ActionPush_UseAbility(flyingCourier)
        return nil
    end

    considerDropItems()

    return nil
end

-------------------------------------------------------------------------------
-- INDIVIDUAL ITEM USE FUNCTIONS
-------------------------------------------------------------------------------

function UseShadowBlade()
    local bot = GetBot()
    local sb = utils.HaveItem(bot, "item_invis_sword")
    if sb ~= nil and sb:IsFullyCastable() then
        bot:Action_UseAbility(sb)
        return nil
    end
end

function UseSilverEdge()
    local bot = GetBot()
    local se = utils.HaveItem(bot, "item_silver_edge")
    if se ~= nil and se:IsFullyCastable() then
        bot:Action_UseAbility(se)
        return nil
    end
end

function UseTomeOfKnowledge()
    local bot = GetBot()
    local tok = utils.HaveItem(bot, "item_tome_of_knowledge")
    if tok ~= nil then
        bot:Action_UseAbility(tok)
        return nil
    end
end

function UseGlimmerCape(target)
    local bot = GetBot()
    local target = target or bot
    local gc = utils.HaveItem(bot, "item_glimmer_cape")
    if gc ~= nil and target ~= nil then
        bot:Action_UseAbilityOnEntity(gc, target)
    end
end

-- will return a handle to the ward or nil if we don't have it, checks both
-- individual ward types and the combined ward dispenser item and switches
-- it's state to the selection we want prior to returning
function HaveWard(wardType)
    local bot = GetBot()
    local ward = utils.HaveItem(bot, wardType)

    if ward == nil then
        ward = utils.HaveItem(bot, "item_ward_dispenser")
        if ward == nil then return false end
        -- we have combined wards, check which is currently selected
        local bObserver = ward:GetToggleState() -- (true = observer, false = sentry)
        if wardType == "item_ward_observer" and (not bObserver) then
            -- flip selection by using on yourself
            bot:Action_UseAbilityOnEntity(ward, bot)
        elseif wardType == "item_ward_sentry" and bObserver then
            -- flip selection by using on yourself
            bot:Action_UseAbilityOnEntity(ward, bot)
        end
    end
    -- at this point we have the correct item selected, or we don't have it
    return ward
end

-------------------------------------------------------------------------------
-- ITEM MANAGEMENT FUNCTIONS
-------------------------------------------------------------------------------
function considerDropItems()
    swapBackpackIntoInventory()

    local npcBot = GetBot()

    for i = 6, 8, 1 do
        local bItem = npcBot:GetItemInSlot(i)
        if bItem ~= nil then
            for j = 1, 5, 1 do
                local item = npcBot:GetItemInSlot(j)
                if item ~= nil and item:GetName() == "item_branches" and bItem:GetName() ~= "item_branches" then
                    npcBot:ActionImmediate_SwapItems(i, j)
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
                        npcBot:ActionImmediate_SwapItems(i, j)
                    end
                end
            end
        end
    end
end

for k,v in pairs( item_usage ) do _G._savedEnv[k] = v end