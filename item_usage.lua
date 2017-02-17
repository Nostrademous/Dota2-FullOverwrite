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
    local bot = GetBot()

    if bot:IsChanneling() or bot:IsUsingAbility() then
        return false
    end
    
    -- if we are full health and full mana, exit early
    if bot:GetHealth() == bot:GetMaxHealth() and bot:GetMana() == bot:GetMaxMana() then return false end
    
    -- if we are under effect of a shrine, exit early
    if bot:HasModifier("modifier_filler_heal") then return false end
    
    local Enemies = bot:GetNearbyHeroes(850, true, BOT_MODE_NONE)

    local bottle = utils.HaveItem(bot, "item_bottle")
    if bottle ~= nil and bottle:GetCurrentCharges() > 0 and not bot:HasModifier("modifier_bottle_regeneration")
        and not bot:HasModifier("modifier_clarity_potion") and not bot:HasModifier("modifier_flask_healing") then

        if (not (bot:GetHealth() == bot:GetMaxHealth() and bot:GetMaxMana() == bot:GetMana())) and bot:HasModifier("modifier_fountain_aura_buff") then
            bot:Action_UseAbilityOnEntity(bottle, bot)
            return true
        end

        if Enemies == nil or #Enemies == 0 then
            if ((bot:GetMaxHealth()-bot:GetHealth()) >= 100 and (bot:GetMaxMana()-bot:GetMana()) >= 60) or
                (bot:GetHealth() < 300 or bot:GetMana() < 200) then
                bot:Action_UseAbilityOnEntity(bottle, bot)
                return true
            end
        end
    end

    if not bot:HasModifier("modifier_fountain_aura_buff") then

        local mekansm = utils.HaveItem(bot, "item_mekansm")
        local Allies = bot:GetNearbyHeroes(900, false, BOT_MODE_NONE)
        if mekansm ~= nil and mekansm:IsFullyCastable() then
            if (bot:GetHealth()/bot:GetMaxHealth()) < 0.15 then
                gHeroVar.HeroUseAbility(bot, mekansm)
                return true
            end
            if #Allies > 1 then
                for _, ally in pairs(Allies) do
                    if (ally:GetHealth()/ally:GetMaxHealth()) < 0.15 then
                        gHeroVar.HeroUseAbility(bot, mekansm)
                        return true
                    end
                end
            end
        end

        local clarity = utils.HaveItem(bot, "item_clarity")
        if clarity ~= nil then
            if #Enemies == 0 then
                if (bot:GetMaxMana()-bot:GetMana()) > 200 and not bot:HasModifier("modifier_clarity_potion") and not modifiers.HasActiveDOTDebuff(bot)  then
                    bot:Action_UseAbilityOnEntity(clarity, bot)
                    return true
                end
            end
        end

        local flask = utils.HaveItem(bot, "item_flask");
        if flask ~= nil then
            if #Enemies == 0 then
                if (bot:GetMaxHealth()-bot:GetHealth()) > 400 and not bot:HasModifier("modifier_flask_healing") and not modifiers.HasActiveDOTDebuff(bot)  then
                    bot:Action_UseAbilityOnEntity(flask, bot)
                    return true
                end
            end
        end
		
		local urn = utils.HaveItem(bot, "item_urn_of_shadows")
        if urn ~= nil and urn:GetCurrentCharges() > 0 then
		    if #Enemies == 0 then
                if (bot:GetMaxHealth()-bot:GetHealth()) > 400 and not bot:HasModifier("modifier_item_urn_heal") and not modifiers.HasActiveDOTDebuff(bot)  then
                    bot:Action_UseAbilityOnEntity(urn, bot)
                    return true
                end
            end
        end

        local faerie = utils.HaveItem(bot, "item_faerie_fire");
        if faerie ~= nil then
            if (bot:GetHealth()/bot:GetMaxHealth()) < 0.15 and (utils.IsTowerAttackingMe(2.0) or utils.IsAnyHeroAttackingMe(1.0) or modifiers.HasActiveDOTDebuff(bot)) then
                gHeroVar.HeroUseAbility(bot, faerie)
                return true
            end
        end

        local tango_shared = utils.HaveItem(bot, "item_tango_single");
        if tango_shared ~= nil  and tango_shared:IsFullyCastable() and (not getHeroVar("IsRetreating")) then
            if (bot:GetMaxHealth()-bot:GetHealth()) > 200 and not bot:HasModifier("modifier_tango_heal") then
                local tree = utils.GetNearestTree(bot)
                if tree ~= nil then
                    bot:Action_UseAbilityOnTree(tango_shared, tree)
                    return true
                end
            end
        end

        local tango = utils.HaveItem(bot, "item_tango");
        if tango ~= nil and tango:IsFullyCastable() and (not getHeroVar("IsRetreating")) then
            if (bot:GetMaxHealth()-bot:GetHealth()) > 200 and not bot:HasModifier("modifier_tango_heal") then
                local tree = utils.GetNearestTree(bot)
                if tree ~= nil then
                    bot:Action_UseAbilityOnTree(tango, tree)
                    return true
                end
            end
        end
    end

    return false
end

function UseRegenItemsOnAlly()
    local bot = GetBot()

    if bot:IsChanneling() or bot:IsUsingAbility() then
        return false
    end
    
    -- if we are under effect of a shrine, exit early
    if bot:HasModifier("modifier_filler_heal") then return false end
    
    local Enemies = bot:GetNearbyHeroes(850, true, BOT_MODE_NONE)
	local Allies = bot:GetNearbyHeroes(850, false,  BOT_MODE_NONE)
	
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

    local bottle = utils.HaveItem(bot, "item_bottle")
    if bottle ~= nil and bottle:GetCurrentCharges() > 0 and not bottleTargetAlly:HasModifier("modifier_bottle_regeneration") 
        and not bottleTargetAlly:HasModifier("modifier_clarity_potion") and not bottleTargetAlly:HasModifier("modifier_flask_healing")
        and (not utils.HaveItem(bottleTargetAlly, "item_bottle"))   then

        if (not (bottleTargetAlly:GetHealth() == bottleTargetAlly:GetMaxHealth() and bottleTargetAlly:GetMaxMana() == bottleTargetAlly:GetMana())) and bottleTargetAlly:HasModifier("modifier_fountain_aura_buff") then
            bot:Action_UseAbilityOnEntity(bottle, bottleTargetAlly)
            return true
        end

        if Enemies == nil or #Enemies == 0 then
            if ((bottleTargetAlly:GetMaxHealth()-bottleTargetAlly:GetHealth()) >= 100 and (bottleTargetAlly:GetMaxMana()-bottleTargetAlly:GetMana()) >= 60) or
                (bottleTargetAlly:GetHealth() < 300 or bottleTargetAlly:GetMana() < 200) then
                bot:Action_UseAbilityOnEntity(bottle, bottleTargetAlly)
                return true
            end
        end
    end

    if (lowestManaAlly and (not lowestManaAlly:HasModifier("modifier_fountain_aura_buff")))  then

        local clarity = utils.HaveItem(bot, "item_clarity")
        if clarity ~= nil and (not utils.HaveItem(lowestManaAlly, "item_clarity")) then
            if (Enemies == nil or #Enemies == 0) then
                if (lowestManaAlly:GetMaxMana()-lowestManaAlly:GetMana()) > 200 and not lowestManaAlly:HasModifier("modifier_clarity_potion") and not modifiers.HasActiveDOTDebuff(lowestManaAlly)  then
                    bot:Action_UseAbilityOnEntity(clarity, lowestManaAlly)
                    return true
                end
            end
        end
    end

    if (lowestHealthAlly and (not lowestHealthAlly:HasModifier("modifier_fountain_aura_buff")))  then
        local flask = utils.HaveItem(bot, "item_flask");
        if flask ~= nil and (not utils.HaveItem(lowestHealthAlly, "item_flask")) then
            if (Enemies == nil or #Enemies == 0) then
                if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 400 and not lowestHealthAlly:HasModifier("modifier_flask_healing") and not modifiers.HasActiveDOTDebuff(lowestHealthAlly)  then
                    bot:Action_UseAbilityOnEntity(flask, lowestHealthAlly)
                    return true
                end
            end
        end
		
		local tango = utils.HaveItem(bot, "item_tango");
        if tango ~= nil and tango:IsFullyCastable() and (not getHeroVar("IsRetreating")) and (not (utils.HaveItem(lowestHealthAlly, "item_tango") or utils.HaveItem(lowestHealthAlly, "item_tango_single")) )then
            if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 200 and not lowestHealthAlly:HasModifier("modifier_tango_heal") then
                local tree = utils.GetNearestTree(bot)
                if tree ~= nil then
                    bot:Action_UseAbilityOnEntity(tango, lowestHealthAlly)
                    return true
                end
            end
        end
		
        local urn = utils.HaveItem(bot, "item_urn_of_shadows")
        if urn ~= nil and urn:GetCurrentCharges() > 0 then
		    if (Enemies == nil or #Enemies == 0) then
                if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 400 and not lowestHealthAlly:HasModifier("modifier_item_urn_heal") and not modifiers.HasActiveDOTDebuff(lowestHealthAlly)  then
                    bot:Action_UseAbilityOnEntity(urn, lowestHealthAlly)
                    return true
                end
            end
        end
    end

    return false
end

function UseTeamItems()
    local bot = GetBot()

    if bot:IsChanneling() or bot:IsUsingAbility() then
        return false
    end

    if not bot:HasModifier("modifier_fountain_aura_buff") then
        local mekansm = utils.HaveItem(bot, "item_mekansm")
        local Allies = bot:GetNearbyHeroes(900, false, BOT_MODE_NONE)
        if mekansm ~= nil and mekansm:IsFullyCastable() then
            if (bot:GetHealth()/bot:GetMaxHealth()) < 0.15 then
                gHeroVar.HeroUseAbility(bot, mekansm)
                return true
            end
            if #Allies > 1 then
                for _, ally in pairs(Allies) do
                    if (ally:GetHealth()/ally:GetMaxHealth()) < 0.15 then
                        gHeroVar.HeroUseAbility(bot, mekansm)
                        return true
                    end
                end
            end
        end

        local arcane = utils.HaveItem(bot, "item_arcane_boots")
        if arcane ~= nil and arcane:IsFullyCastable() then
            if (bot:GetMaxMana() - bot:GetMana()) > 160 then
                gHeroVar.HeroUseAbility(bot, arcane)
                return true
            end
        end
    end
    
    return false
end

function UseMovementItems(location)
    local bot = GetBot()
    local location = location or bot:GetLocation()

    if bot:IsChanneling() then
        return false
    end

    local pb = utils.HaveItem(bot, "item_phase_boots")
    if pb ~= nil and pb:IsFullyCastable() then
        gHeroVar.HeroUseAbility(bot, pb)
        return true
    end

    local force = utils.HaveItem(bot, "item_force_staff")
    if force ~= nil and utils.IsFacingLocation(bot, location, 25) then
        bot:Action_UseAbilityOnEntity(force, bot)
        return true
    end

    local hp = utils.HaveItem(bot, "item_hurricane_pike")
    if hp ~= nil and utils.IsFacingLocation(bot, location, 25) then
        bot:Action_UseAbilityOnEntity(hp, bot)
        return true
    end

    if UseSilverEdge() or UseShadowBlade() then return true end

    return false
end

function UseDefensiveItems(enemy, triggerDistance)
    local bot = GetBot()
    local location = location or bot:GetLocation()

    if bot:IsChanneling() or bot:IsUsingAbility() then return false end

    local hp = utils.HaveItem(bot, "item_hurricane_pike")
    if hp ~= nil and GetUnitToUnitDistance(bot, enemy) < triggerDistance then
        bot:Action_UseAbilityOnEntity(hp, enemy)
        return true
    end
end

function UseBuffItems()
    local bot = GetBot()

    if bot:IsChanneling() or bot:IsUsingAbility() then return false end
    
    UseTomeOfKnowledge()
    
    if UseMidas() then return true end
    
    return false
end

function UseTP(hero, loc, lane)
    local loc = loc or nil
    local lane = lane or getHeroVar("CurLane")
    local tpSwap = false
    local backPackSlot = 0
    
    if DotaTime() < 10 then return false end

    if hero:IsChanneling() or hero:IsUsingAbility() then return false end
    
    -- if we are in fountain, don't TP out until we have full health & mana
    if hero:DistanceFromFountain() < 200 and 
        not (hero:GetHealth() == hero:GetMaxHealth() and hero:GetMana() == hero:GetMaxMana()) then
        return false
    end

    local tp = utils.HaveItem(hero, "item_tpscroll")
    if tp ~= nil and (utils.HaveItem(hero, "item_travel_boots_1") or utils.HaveItem(hero, "item_travel_boots_2")) 
        and (hero:DistanceFromFountain() < 200 or hero:DistanceFromSideShop() < 200 or hero:DistanceFromSecretShop() < 200) then
        hero:SellItem(tp)
        tp = nil
    end

    if tp == nil and utils.HaveTeleportation(hero) then
        tp = utils.HaveItem(hero, "item_travel_boots_1")
        if tp == nil then
            tp = utils.HaveItem(hero, "item_travel_boots_2")
        end
    end

    local dest = loc
    if dest == nil then
        dest = GetLocationAlongLane(lane, GetLaneFrontAmount(GetTeam(), lane, false))
    end
    
    if tp == nil and GetUnitToLocationDistance(hero, dest) > 3000
        and hero:DistanceFromFountain() < 200
        and hero:GetGold() > 50 then
        local savedValue = hero:GetNextItemPurchaseValue()
        backPackSlot = utils.GetFreeSlotInBackPack(hero)
        if utils.NumberOfItems(hero) == 6 and backPackSlot > 0 then 
            hero:ActionImmediate_SwapItems(0, backPackSlot)
            tpSwap = true
        end
        hero:ActionImmediate_PurchaseItem( "item_tpscroll" )
        tp = utils.HaveItem(hero, "item_tpscroll")
        hero:SetNextItemPurchaseValue(savedValue)
    end

    if tp ~= nil and tp:IsFullyCastable() then
        -- dest (below) should find farthest away tower to TP to in our assigned lane, even if tower is dead it will
        -- just default to closest location we can TP to in that direction
        if GetUnitToLocationDistance(hero, dest) > 3000 and hero:DistanceFromFountain() < 200 then
            hero:Action_UseAbilityOnLocation(tp, dest)
            if tpSwap then 
                hero:ActionImmediate_SwapItems(0, backPackSlot)
            end
            return true
        end
    end
    
    return false
end

function UseItems()
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()

    if bot:IsChanneling() or bot:IsUsingAbility() then return false end

    if UseBuffItems() then return true end
    
    if UseRegenItems() then return true end

    if UseRegenItemsOnAlly() then return true end
    
    if UseTeamItems() then return true end
    
    if UseTP(bot) then return true end
    
    local courier = utils.IsItemAvailable("item_courier")
    if courier ~= nil then
        gHeroVar.HeroUseAbility(bot, courier)
        return true
    end

    local flyingCourier = utils.IsItemAvailable("item_flying_courier")
    if flyingCourier ~= nil then
        gHeroVar.HeroUseAbility(bot, flyingCourier)
        return true
    end

    considerDropItems()

    return false
end

-------------------------------------------------------------------------------
-- INDIVIDUAL ITEM USE FUNCTIONS
-------------------------------------------------------------------------------

function UseShadowBlade()
    local bot = GetBot()
    local sb = utils.HaveItem(bot, "item_invis_sword")
    if sb ~= nil and sb:IsFullyCastable() then
        gHeroVar.HeroUseAbility(bot, sb)
        return true
    end
    return false
end

function UseSilverEdge()
    local bot = GetBot()
    local se = utils.HaveItem(bot, "item_silver_edge")
    if se ~= nil and se:IsFullyCastable() then
        gHeroVar.HeroUseAbility(bot, se)
        return true
    end
    return false
end

function UseTomeOfKnowledge()
    local bot = GetBot()
    local tok = utils.HaveItem(bot, "item_tome_of_knowledge")
    if tok ~= nil then
        gHeroVar.HeroUseAbility(bot, tok)
        return true
    end
    return false
end

function UseMidas()
    local bot = GetBot()
    local midas = utils.HaveItem(bot, "item_hand_of_midas")
    if midas ~= nil and midas:IsFullyCastable() then
        local creeps = bot:GetNearbyCreeps(600, true)
        if #creeps > 1 then
            table.sort(creeps, function(n1, n2) return n1:GetHealth() > n2:GetHealth() end)
            bot:Action_UseAbilityOnEntity(midas, creeps[1])
            return true
        elseif #creeps == 1 then
            bot:Action_UseAbilityOnEntity(midas, creeps[1])
            return true
        end
    end
    return false
end

function UseGlimmerCape(target)
    local bot = GetBot()
    local target = target or bot
    local gc = utils.HaveItem(bot, "item_glimmer_cape")
    if gc ~= nil and target ~= nil then
        bot:Action_UseAbilityOnEntity(gc, target)
        return true
    end
    return false
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

    local bot = GetBot()

    for i = 6, 8, 1 do
        local bItem = bot:GetItemInSlot(i)
        if bItem ~= nil then
            for j = 1, 5, 1 do
                local item = bot:GetItemInSlot(j)
                if item ~= nil and item:GetName() == "item_branches" and bItem:GetName() ~= "item_branches" then
                    bot:ActionImmediate_SwapItems(i, j)
                end
            end
        end
    end
end

function swapBackpackIntoInventory()
    local bot = GetBot()
    if utils.NumberOfItems(bot) < 6 and utils.NumberOfItemsInBackpack(bot) > 0 then
        for i = 6, 8, 1 do
            if bot:GetItemInSlot(i) ~= nil then
                for j = 1, 5, 1 do
                    local item = bot:GetItemInSlot(j)
                    if item == nil then
                        bot:ActionImmediate_SwapItems(i, j)
                    end
                end
            end
        end
    end
end

for k,v in pairs( item_usage ) do _G._savedEnv[k] = v end