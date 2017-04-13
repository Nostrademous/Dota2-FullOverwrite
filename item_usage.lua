-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "item_usage", package.seeall )

require( GetScriptDirectory().."/constants" )
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

    if utils.IsBusy(bot) then return true end
    if bot:IsMuted() then return false end

    -- if we are full health and full mana, exit early
    if bot:GetHealth() == bot:GetMaxHealth() and bot:GetMana() == bot:GetMaxMana() then return false end

    -- if we are under effect of a shrine, exit early
    if bot:HasModifier("modifier_filler_heal") then return false end

    local Enemies = gHeroVar.GetNearbyEnemies(bot, 850)

    local bottle = utils.IsItemAvailable("item_bottle")
    if bottle and bottle:GetCurrentCharges() > 0 and not bot:HasModifier("modifier_bottle_regeneration")
        and not bot:HasModifier("modifier_clarity_potion") and not bot:HasModifier("modifier_flask_healing") then

        if (not (bot:GetHealth() == bot:GetMaxHealth() and bot:GetMaxMana() == bot:GetMana())) and bot:HasModifier("modifier_fountain_aura_buff") then
            gHeroVar.HeroUseAbilityOnEntity(bot, bottle, bot)
            return true
        end

        if Enemies == nil or #Enemies == 0 then
            if ((bot:GetMaxHealth()-bot:GetHealth()) >= 100 and (bot:GetMaxMana()-bot:GetMana()) >= 60) or
                (bot:GetHealth() < 300 or bot:GetMana() < 200) then
                gHeroVar.HeroUseAbilityOnEntity(bot, bottle, bot)
                return true
            end
        end
    end

    if not bot:HasModifier("modifier_fountain_aura_buff") then

        local wand = utils.IsItemAvailable("item_magic_wand")
        if not wand then wand = utils.IsItemAvailable("item_magic_stick") end
        
        if wand then
            if wand:GetCurrentCharges() > 0 then
                local restoreAmount = 15*wand:GetCurrentCharges()
                if bot.SelfRef:getCurrentMode():GetName() == "retreat" then
                    gHeroVar.HeroUseAbility(bot, wand)
                    return true
                end
            end
        end
    
        local mekansm = utils.IsItemAvailable("item_mekansm")
        local Allies = gHeroVar.GetNearbyAllies(bot, 900)
        if mekansm then
            if (bot:GetHealth()/bot:GetMaxHealth()) < 0.5 then
                gHeroVar.HeroUseAbility(bot, mekansm)
                return true
            end
            if #Allies > 1 then
                for _, ally in pairs(Allies) do
                    if (ally:GetHealth()/ally:GetMaxHealth()) < 0.5 then
                        gHeroVar.HeroUseAbility(bot, mekansm)
                        return true
                    end
                end
            end
        end

        local clarity = utils.IsItemAvailable("item_clarity")
        if clarity then
            if #Enemies == 0 then
                if (bot:GetMaxMana()-bot:GetMana()) > 200 and not bot:HasModifier("modifier_clarity_potion") and not modifiers.HasActiveDOTDebuff(bot)  then
                    gHeroVar.HeroUseAbilityOnEntity(bot, clarity, bot)
                    return true
                end
            end
        end

        local flask = utils.IsItemAvailable("item_flask");
        if flask then
            if #Enemies == 0 then
                if (bot:GetMaxHealth()-bot:GetHealth()) > 400 and not bot:HasModifier("modifier_flask_healing") and not modifiers.HasActiveDOTDebuff(bot)  then
                    gHeroVar.HeroUseAbilityOnEntity(bot, flask, bot)
                    return true
                end
            end
        end

        local urn = utils.IsItemAvailable("item_urn_of_shadows")
        if urn and urn:GetCurrentCharges() > 0 then
            if #Enemies == 0 then
                if (bot:GetMaxHealth()-bot:GetHealth()) > 400 and not bot:HasModifier("modifier_item_urn_heal") and not modifiers.HasActiveDOTDebuff(bot)  then
                    gHeroVar.HeroUseAbilityOnEntity(bot, urn, bot)
                    return true
                end
            end
        end

        local faerie = utils.IsItemAvailable("item_faerie_fire")
        if faerie then
            if (bot:GetHealth()/bot:GetMaxHealth()) < 0.15 and (utils.IsTowerAttackingMe(2.0) or utils.IsAnyHeroAttackingMe(1.0) or modifiers.HasActiveDOTDebuff(bot)) then
                gHeroVar.HeroUseAbility(bot, faerie)
                return true
            end
        end

        local tango_shared = utils.IsItemAvailable("item_tango_single")
        if tango_shared then
            if (bot:GetMaxHealth()-bot:GetHealth()) > 200 and not bot:HasModifier("modifier_tango_heal") then
                local tree = utils.GetNearestTree(bot)
                if tree ~= nil then
                    gHeroVar.HeroUseAbilityOnTree(bot, tango_shared, tree)
                    return true
                end
            end
        end

        local tango = utils.IsItemAvailable("item_tango")
        if tango then
            if (bot:GetMaxHealth()-bot:GetHealth()) > 200 and not bot:HasModifier("modifier_tango_heal") then
                local tree = utils.GetNearestTree(bot)
                if tree ~= nil then
                    gHeroVar.HeroUseAbilityOnTree(bot, tango, tree)
                    return true
                end
            end
        end
    end

    return false
end

function UseRegenItemsOnAlly()
    local bot = GetBot()

    if utils.IsBusy(bot) then return true end
    if bot:IsMuted() then return false end

    -- if we are under effect of a shrine, exit early
    if bot:HasModifier("modifier_filler_heal") then return false end

    local Enemies = gHeroVar.GetNearbyEnemies(bot, 850)
    local Allies = gHeroVar.GetNearbyAllies(bot, 850)

    local lowestHealthAlly = nil
    local lowestManaAlly = nil
    local bottleTargetAlly = nil
    for _, ally in pairs(Allies) do
        if not ally:IsIllusion() then
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
    end

    local bottle = utils.IsItemAvailable("item_bottle")
    if bottle and bottle:GetCurrentCharges() > 0 and not bottleTargetAlly:HasModifier("modifier_bottle_regeneration")
        and not bottleTargetAlly:HasModifier("modifier_clarity_potion") and not bottleTargetAlly:HasModifier("modifier_flask_healing") then
        
        -- check if they have their own
        local allyBottle, _ = utils.HaveItem(bottleTargetAlly, "item_bottle")
        if allyBottle and allyBottle:GetCurrentCharges() > 0 then return false end

        if (not (bottleTargetAlly:GetHealth() == bottleTargetAlly:GetMaxHealth() and 
            bottleTargetAlly:GetMaxMana() == bottleTargetAlly:GetMana())) and
            bottleTargetAlly:HasModifier("modifier_fountain_aura_buff") then
            gHeroVar.HeroUseAbilityOnEntity(bot, bottle, bottleTargetAlly)
            return true
        end

        if Enemies == nil or #Enemies == 0 then
            if ((bottleTargetAlly:GetMaxHealth()-bottleTargetAlly:GetHealth()) >= 100 and (bottleTargetAlly:GetMaxMana()-bottleTargetAlly:GetMana()) >= 60) or
                (bottleTargetAlly:GetHealth() < 300 or bottleTargetAlly:GetMana() < 200) then
                gHeroVar.HeroUseAbilityOnEntity(bot, bottle, bottleTargetAlly)
                return true
            end
        end
    end

    if (lowestManaAlly and (not lowestManaAlly:HasModifier("modifier_fountain_aura_buff"))) then
        local clarity = utils.IsItemAvailable("item_clarity")
        if clarity then
            -- check if they have their own
            local allyClarity, _ = utils.HaveItem(lowestManaAlly, "item_clarity")
            if allyClarity then return false end
            
            if (Enemies == nil or #Enemies == 0) then
                if (lowestManaAlly:GetMaxMana()-lowestManaAlly:GetMana()) > 200 and not lowestManaAlly:HasModifier("modifier_clarity_potion") and not modifiers.HasActiveDOTDebuff(lowestManaAlly)  then
                    gHeroVar.HeroUseAbilityOnEntity(bot, clarity, lowestManaAlly)
                    return true
                end
            end
        end
    end

    if (lowestHealthAlly and (not lowestHealthAlly:HasModifier("modifier_fountain_aura_buff"))) then
        local flask = utils.IsItemAvailable("item_flask");
        if flask then
            -- check if they have their own
            local allyFlask, _ = utils.HaveItem(lowestHealthAlly, "item_flask")
            if allyFlask then return false end
            
            if (Enemies == nil or #Enemies == 0) then
                if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 400 and not lowestHealthAlly:HasModifier("modifier_flask_healing") and not modifiers.HasActiveDOTDebuff(lowestHealthAlly)  then
                    gHeroVar.HeroUseAbilityOnEntity(bot, flask, lowestHealthAlly)
                    return true
                end
            end
        end

        local tango = utils.IsItemAvailable("item_tango");
        if tango then 
            local allyTango, _ = utils.HaveItem(lowestHealthAlly, "item_tango")
            if allyTango == nil then allyTango, _ = utils.HaveItem(lowestHealthAlly, "item_tango_single") end
            
            -- check if they have their own
            if allyTango then return false end
            
            -- TODO: check if they have space
            
            if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 200 and not lowestHealthAlly:HasModifier("modifier_tango_heal") then
                gHeroVar.HeroUseAbilityOnEntity(bot, tango, lowestHealthAlly)
                return true
            end
        end

        local urn = utils.IsItemAvailable("item_urn_of_shadows")
        if urn and urn:GetCurrentCharges() > 0 then
            if (Enemies == nil or #Enemies == 0) then
                if (lowestHealthAlly:GetMaxHealth()-lowestHealthAlly:GetHealth()) > 400 and not lowestHealthAlly:HasModifier("modifier_item_urn_heal") and not modifiers.HasActiveDOTDebuff(lowestHealthAlly)  then
                    gHeroVar.HeroUseAbilityOnEntity(bot, urn, lowestHealthAlly)
                    return true
                end
            end
        end
    end

    return false
end

function UseTeamItems()
    local bot = GetBot()

    if utils.IsBusy(bot) then return true end

    if not bot:HasModifier("modifier_fountain_aura_buff") then
        local mekansm = utils.IsItemAvailable("item_mekansm")
        local Allies = gHeroVar.GetNearbyEnemies(bot, 900)
        if mekansm then
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

        local arcane = utils.IsItemAvailable("item_arcane_boots")
        if arcane then
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

    if utils.IsBusy(bot) then return true end
    if bot:IsMuted() then return false end

    if UsePhaseBoots() then return true end

    if UseForceStaff(bot, location) then return true end

    if UseHurricanePike(bot, location) then return true end

    if UseSilverEdge() or UseShadowBlade() then return true end

    return false
end

function UseDefensiveItems(enemy, triggerDistance)
    local bot = GetBot()

    if utils.IsBusy(bot) then return true end
    if bot:IsMuted() then return false end

    local hp = utils.IsItemAvailable("item_hurricane_pike")
    if hp and GetUnitToUnitDistance(bot, enemy) < triggerDistance then
        gHeroVar.HeroUseAbilityOnEntity(bot, hp, enemy)
        return true
    end
end

function UseBuffItems()
    local bot = GetBot()

    if utils.IsBusy(bot) then return true end
    if bot:IsMuted() then return false end

    if UseTomeOfKnowledge() then return true end

    if UseMidas() then return true end

    return false
end

function UseTP(hero, arg1, arg2)
    if hero:IsIllusion() then return false end
    
    local loc = nil
    if arg1 then loc = arg1 end
    
    local lane = getHeroVar("CurLane")
    if arg2 then lane = arg2 end
    
    local tpSwap = false
    local backPackSlot = 0

    if DotaTime() < 10 then return false end

    if utils.IsBusy(hero) then return true end
    if hero:IsMuted() then return false end

    -- if we are in fountain, don't TP out until we have full health & mana
    if hero:DistanceFromFountain() < 200 and
        not (hero:GetHealth() == hero:GetMaxHealth() and hero:GetMana() == hero:GetMaxMana()) then
        return false
    end

    local tp, bMainInv = utils.HaveItem(hero, "item_tpscroll")
    if tp ~= nil and (utils.HaveItem(hero, "item_travel_boots_1") or utils.HaveItem(hero, "item_travel_boots_2"))
        and (hero:DistanceFromFountain() < 200 or hero:DistanceFromSideShop() < 200 or hero:DistanceFromSecretShop() < 200) then
        utils.myPrint("Selling TP, don't need it")
        hero:ActionImmediate_SellItem(tp)
        tp = nil
    end

    if tp == nil and utils.HaveTeleportation(hero) then
        if utils.GetHeroName(hero) == "furion" then
            tp = hero:GetAbilityInSlot(1)
            bMainInv = true
        end
        
        tp, bMainInv = utils.HaveItem(hero, "item_travel_boots_1")
        if tp == nil then
            tp, bMainInv = utils.HaveItem(hero, "item_travel_boots_2")
        end
    end

    local dest = loc
    if dest == nil then
        dest = GetLocationAlongLane(lane, GetLaneFrontAmount(GetTeam(), lane, false))
    end

    if tp == nil and GetUnitToLocationDistance(hero, dest) > 3000
        and hero:DistanceFromFountain() < 200
        and hero:GetGold() > 50 then

        -- if our inventory and backpack is full, don't bother buying TPs
        if utils.NumberOfItemsInBackpack(hero) == 3 and utils.NumberOfItems(hero) == 6 then
            return false
        end

        local savedValue = hero:GetNextItemPurchaseValue()
        backPackSlot = utils.GetFreeSlotInBackPack(hero)
        if utils.NumberOfItems(hero) == 6 and backPackSlot > 0 then
            hero:ActionImmediate_SwapItems(0, backPackSlot)
            tpSwap = true
        end
        hero:ActionImmediate_PurchaseItem( "item_tpscroll" )
        tp, bMainInv = utils.HaveItem(hero, "item_tpscroll")
        hero:SetNextItemPurchaseValue(savedValue)
    end

    if tp ~= nil and bMainInv and tp:IsFullyCastable() then
        -- dest (below) should find farthest away tower to TP to in our assigned lane, even if tower is dead it will
        -- just default to closest location we can TP to in that direction
        if GetUnitToLocationDistance(hero, dest) > 3000 and hero:DistanceFromFountain() < 200 then
            --utils.myPrint("Using TP")
            gHeroVar.HeroUseAbilityOnLocation(hero, tp, dest)
            if tpSwap then
                utils.myPrint("Swapping back item for TP slot")
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

    if utils.IsBusy(bot) then return true end
    if bot:IsMuted() then return false end
    
    if UseEuls() then return true end
    
    if UseGlimmerCape() then return true end

    if UseBuffItems() then return true end

    if UseRegenItems() then return true end

    if UseRegenItemsOnAlly() then return true end

    if UseTeamItems() then return true end

    if UseIronTalon() then return true end
    
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

function ItemFuncName( name )
    local _, pos = string.find(name, "item_")
    local sItemName = string.sub(name, pos+1)
    
    local fName = ""
    local part = string.find(sItemName, "_")
    if part == nil then
       fName = sItemName:sub(1,1):upper()..sItemName:sub(2) 
    else
        while string.find(sItemName, "_") do
            local place = string.find(sItemName, "_")
            local sStr = string.sub(sItemName, 1, place-1)
            fName = fName .. sStr:sub(1,1):upper() .. sStr:sub(2)
            sItemName = string.sub(sItemName, place+1)
        end
        fName = fName .. sItemName:sub(1,1):upper()..sItemName:sub(2)
    end    
    return "Use"..fName
end

function UseMyItems()
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local hBot = GetBot()

    if utils.IsBusy(hBot) then return true end
    if hBot:IsMuted() then return false end

    for indx, itemFunc in pairs(hBot.itemFuncList) do
        if itemFunc ~= nil then
            local bRet = itemFunc()
            if bRet then return true end
        end
    end

    return false
end

-------------------------------------------------------------------------------
-- INDIVIDUAL ITEM USE FUNCTIONS
-------------------------------------------------------------------------------

function UseShadowBlade()
    local bot = GetBot()
    local sb = utils.IsItemAvailable("item_invis_sword")
    if sb then
        gHeroVar.HeroUseAbility(bot, sb)
        return true
    end
    return false
end

function UseSilverEdge()
    local bot = GetBot()
    local se = utils.IsItemAvailable("item_silver_edge")
    if se then
        gHeroVar.HeroUseAbility(bot, se)
        return true
    end
    return false
end

function UseTomeOfKnowledge()
    local bot = GetBot()
    local tok = utils.IsItemAvailable("item_tome_of_knowledge")
    if tok then
        gHeroVar.HeroUseAbility(bot, tok)
        return true
    end
    return false
end

function UseAbyssalBlade(target)
    local bot = GetBot()
    local ab = utils.IsItemAvailable("item_abyssal_blade")
    if ab then
        gHeroVar.HeroUseAbilityOnEntity(bot, ab, target)
        return true
    end
    return false
end

function UseBattlefury( hTree )
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_bfury")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, hTree)
        return true
    end
    return false
end

function UseBlink(location)
    local bot = GetBot()
    local blink = utils.IsItemAvailable("item_blink")
    if blink then
        gHeroVar.HeroUseAbilityOnLocation(bot, blink, location)
        return true
    end
    return false
end

function UseBladeMail(actionType)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_blade_mail")
    if item then
        if actionType and actionType == constants.PUSH then
            gHeroVar.HeroPushUseAbility(bot, item)
        elseif actionType and actionType == constants.QUEUE then
            gHeroVar.HeroQueueUseAbility(bot, item)
        else
            gHeroVar.HeroUseAbility(bot, item)
        end
        return true
    end
    return false
end

function UseBlackKingBar()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_black_king_bar")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseBloodstone()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_bloodstone")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseBloodthorn(target)
    local bot = GetBot()
    local bt = utils.IsItemAvailable("item_bloodthorn")
    if bt then
        gHeroVar.HeroUseAbilityOnEntity(bot, bt, target)
        return true
    end
    return false
end

function UseButterfly()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_butterfly")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseCheese()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_cheese")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseCrimsonGuard()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_crimson_guard")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseDagon(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_dagon_1")
    if not item then item = utils.IsItemAvailable("item_dagon_2") end
    if not item then item = utils.IsItemAvailable("item_dagon_3") end
    if not item then item = utils.IsItemAvailable("item_dagon_4") end
    if not item then item = utils.IsItemAvailable("item_dagon_5") end
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseDiffusal(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_diffusal_blade_1")
    if not item then item = utils.IsItemAvailable("item_diffusal_blade_2") end
    if item and item:GetCurrentCharges() > 0 then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseDrums()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_ancient_janggo")
    if item and item:GetCurrentCharges() > 0 then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false
end

function UseDust()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_dust")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseMango()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_enchanted_mango")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseEtheralBlade(target)
    local bot = GetBot()
    local eb = utils.IsItemAvailable("item_ethereal_blade")
    if eb then
        gHeroVar.HeroUseAbilityOnEntity(bot, eb, target)
        return true
    end
    return false
end

function UseEuls()
    local bot = GetBot()
    local euls = utils.IsItemAvailable("item_cyclone")
    if euls then
        local modeName = bot.SelfRef:getCurrentMode():GetName()
        local CastRange = 575
        
        -- Check for a channeling enemy
        local enemies = gHeroVar.GetNearbyEnemies(bot, CastRange + 300)
        for _, npcEnemy in pairs( enemies ) do
            if npcEnemy:IsChanneling() and not utils.IsTargetMagicImmune(npcEnemy) then
                gHeroVar.HeroUseAbilityOnEntity(bot, euls, npcEnemy)
                return true
            end
        end
        
        -- protect myself by dispelling bad modifiers or making myself invulnerable when necessary
        if modifiers.HasEulModifier(bot) then
            gHeroVar.HeroUseAbilityOnEntity(bot, euls, bot)
            return true
        end
        
        -- stop chasing enemy while on retreat
        if modeName == "retreat" then
           local tableNearbyEnemyHeroes = gHeroVar.GetNearbyEnemies( bot, CastRange )
            for _, npcEnemy in pairs( tableNearbyEnemyHeroes ) do
                if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
                    if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) then
                        gHeroVar.HeroUseAbilityOnEntity(bot, euls, npcEnemy)
                        return true
                    end
                end
            end
        end
        
        -- If we're going after someone and they are outside our attack range
        if modeName == "roam" or modeName == "defendally" or modeName == "fight" then
            local npcEnemy = getHeroVar("RoamTarget")
            if npcEnemy == nil then npcEnemy = getHeroVar("Target") end

            if utils.ValidTarget(npcEnemy) then
                if not utils.IsTargetMagicImmune(npcEnemy) and not utils.IsCrowdControlled(npcEnemy) then 
                    local dist = GetUnitToUnitDistance(bot, npcEnemy)
                    if dist > bot:GetAttackRange() and dist <= CastRange then
                        gHeroVar.HeroUseAbilityOnEntity(bot, euls, npcEnemy)
                        return true
                    end
                end
            end
        end
        
        -- Disable strongest enemy in team-fight
        local tableNearbyAttackingAlliedHeroes = utils.InTeamFight(bot, 1000)
        if #tableNearbyAttackingAlliedHeroes >= 2 then
            local npcMostDangerousEnemy = utils.GetScariestEnemy(bot, CastRange)

            if utils.ValidTarget(npcMostDangerousEnemy)	then
                gHeroVar.HeroUseAbilityOnEntity(bot, euls, npcMostDangerousEnemy)
                return true
            end
        end
        --[[ TEST CODE
    else
        if utils.HaveItem(bot, "item_cyclone") then
            local enemies = gHeroVar.GetNearbyEnemies(bot, 900)
            for _, enemy in pairs(enemies) do
                modifiers.printAllMods(enemy)
            end
        end
        --]]
    end
    
    return false
end

function UseForceStaff(target, location)
    local bot = GetBot()
    local fs = utils.IsItemAvailable("item_force_staff")
    if fs and utils.IsFacingLocation(bot, location, 25) then
        gHeroVar.HeroUseAbilityOnEntity(bot, fs, target)
        return true
    end
    return false
end

function UseGhostScepter()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_ghost")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseGlimmerCape()
    local gc = utils.IsItemAvailable("item_glimmer_cape")
    if gc then
        local bot = GetBot()
        local modeName = bot.SelfRef:getCurrentMode():GetName()
        
        if modeName == "retreat" or modeName == "shrine" then
            gHeroVar.HeroUseAbilityOnEntity(GetBot(), gc, bot)
            return true
        end        
    end
    return false
end

function UseMidas()
    local bot = GetBot()
    local midas = utils.IsItemAvailable("item_hand_of_midas")
    if midas then
        local creeps = gHeroVar.GetNearbyEnemyCreep(bot, 600)
        if #creeps > 1 then
            table.sort(creeps, function(n1, n2) return n1:GetHealth()/bot:GetAttackCombatProficiency(n1) > n2:GetHealth()/bot:GetAttackCombatProficiency(n2) end)
            if not creeps[1]:IsAncientCreep() then
                gHeroVar.HeroUseAbilityOnEntity(bot, midas, creeps[1])
                return true
            end
        elseif #creeps == 1 then
            if not creeps[1]:IsAncientCreep() then
                gHeroVar.HeroUseAbilityOnEntity(bot, midas, creeps[1])
                return true
            end
        end
    end
    return false
end

function UseHeavensHalberd(target)
    local bot = GetBot()
    local hh = utils.IsItemAvailable("item_heavens_halberd")
    if hh then
        gHeroVar.HeroUseAbilityOnEntity(bot, hh, target)
        return true
    end
    return false
end

function UseHelmOfTheDominator(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_helm_of_the_dominator")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseHood()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_hood_of_defiance")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false
end

function UseHurricanePike(target, location)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_hurricane_pike")
    if item and utils.IsFacingLocation(bot, location, 25) then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseIronTalon()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_iron_talon")
    if item then
        -- use Talon to 1-shot enemy wards
        local eWards = GetUnitList(UNIT_LIST_ENEMY_WARDS)
        if #eWards > 0 then
            local target = eWards[1]
            if GetUnitToUnitDistance(bot, target) < 3000 then
                gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
                return true
            end
        end
    
        -- use Talon on highest-health & defense enemy unit, if not ancient, and we won't kill in 2 shots
        local creeps = gHeroVar.GetNearbyEnemyCreep(bot, 350)
        if #creeps > 0 then
            if #creeps > 1 then
                table.sort(creeps, function(n1,n2) return n1:GetHealth()/bot:GetAttackCombatProficiency(n1) > n2:GetHealth()/bot:GetAttackCombatProficiency(n2) end)
            end
            local target = creeps[1]
            if utils.ValidTarget(target) and not target:IsAncientCreep() and target:GetHealth() > bot:GetAttackDamage()*2.0 then
                gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
                return true
            end
        end
    end
    return false
end

function UseLinkens(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_sphere")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseLotusOrb(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_lotus_orb")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseManta()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_manta")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseMoM()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_mask_of_madness")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseMedallion(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_medallion_of_courage")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false 
end

function UseMjollnir()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_mjollnir")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseMoonshard(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_moon_shard")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false 
end

function UseNecronomicon()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_necronomicon_1")
    if not item then item = utils.IsItemAvailable("item_necronomicon_2") end
    if not item then item = utils.IsItemAvailable("item_necronomicon_3") end
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseOrchid(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_orchid")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UsePhaseBoots()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_phase_boots")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false
end

function UsePipe()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_pipe")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseQuellingBlade( hTree )
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_quelling_blade")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, hTree)
        return true
    end
    return false
end

function UseRefresher()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_refresher")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseRodOfAtos(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_rod_of_atos")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseSatanic()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_satanic")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseScytheOfVyse(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_sheepstick")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseShadowAmulet()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_shadow_amulet")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseShivas()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_shivas_guard")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false 
end

function UseSmoke( hUnit )
    local item, bMainInv = utils.HaveItem(hUnit, "item_smoke_of_deceit")
    if item and bMainInv and item:IsFullyCastable() then
        gHeroVar.HeroUseAbility(hUnit, item)
        return true
    end
    return false 
end

function UseSolarCrest(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_solar_crest")
    if item then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseSoulRing()
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_soul_ring")
    if item then
        gHeroVar.HeroUseAbility(bot, item)
        return true
    end
    return false
end

function UseUrn(target)
    local bot = GetBot()
    local item = utils.IsItemAvailable("item_urn_of_shadows")
    if item and item:GetCurrentCharges() > 0 then
        gHeroVar.HeroUseAbilityOnEntity(bot, item, target)
        return true
    end
    return false
end

function UseVeil(loc)
    local bot = GetBot()
    local veil = utils.IsItemAvailable("item_veil_of_discord")
    if veil then
        gHeroVar.HeroUseAbilityOnEntity(bot, veil, loc)
        return true
    end
    return false
end

-- will return a handle to the ward or nil if we don't have it, checks both
-- individual ward types and the combined ward dispenser item and switches
-- it's state to the selection we want prior to returning
function HaveWard(wardType)
    local bot = GetBot()
    local ward, _ = utils.HaveItem(bot, wardType)

    if ward == nil then
        ward, _ = utils.HaveItem(bot, "item_ward_dispenser")
        if ward == nil then return nil end
        -- we have combined wards, check which is currently selected
        local bObserver = ward:GetToggleState() -- (true = observer, false = sentry)
        if wardType == "item_ward_observer" and (not bObserver) then
            -- flip selection by using on yourself
            gHeroVar.HeroUseAbilityOnEntity(bot, ward, bot)
            return true
        elseif wardType == "item_ward_sentry" and bObserver then
            -- flip selection by using on yourself
            gHeroVar.HeroUseAbilityOnEntity(bot, ward, bot)
            return true
        end
    end
    -- at this point we have the correct item selected, or we don't have it
    return ward
end

-------------------------------------------------------------------------------
-- ITEM MANAGEMENT FUNCTIONS
-------------------------------------------------------------------------------
function considerDropItems()
    if swapBackpackIntoInventory() then return end

    local bot = GetBot()

    for i = 6, 8, 1 do
        local bItem = bot:GetItemInSlot(i)
        if bItem ~= nil then
            for j = 1, 5, 1 do
                local item = bot:GetItemInSlot(j)
                if item ~= nil and item:GetName() == "item_branches" and bItem:GetName() ~= "item_branches" then
                    bot:ActionImmediate_SwapItems(i, j)
                    return
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
                        return true
                    end
                end
            end
        end
    end
    return false
end

for k,v in pairs( item_usage ) do _G._savedEnv[k] = v end
