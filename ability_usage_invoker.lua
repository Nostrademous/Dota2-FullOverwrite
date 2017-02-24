-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code is heavily based off of work done by arz_on4dt
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_invoker", package.seeall )

require( GetScriptDirectory().."/fight_simul" )
require( GetScriptDirectory().."/constants" )

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

local abilityQ = ""
local abilityW = ""
local abilityE = ""
local abilityR = ""

local abilityTO = ""
local abilityCS = ""
local abilityAC = ""
local abilityGW = ""
local abilityEMP = ""
local abilityCM = ""
local abilityDB = ""
local abilityIW = ""
local abilitySS = ""
local abilityFS = ""

local castTODesire = 0
local castCSDesire = 0
local castACDesire = 0
local castGWDesire = 0
local castEMPDesire = 0
local castCMDesire = 0
local castDBDesire = 0
local castIWDesire = 0
local castSSDesire = 0
local castFSDesire = 0

function nukeDamage( bot, enemy )
    if enemy == nil or enemy:IsNull() then return 0, {}, 0, 0, 0 end
    
    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 10000
    
    local magicImmune = utils.IsTargetMagicImmune(enemy)
    
    -- Check Chaos Meteor
    if abilityCM:IsFullyCastable() then
        local burnDuration = 3.0
        local burnDamage = burnDuration * abilityCM:GetSpecialValueFloat("burn_dps")
        local mainDamage = abilityCM:GetSpecialValueFloat("main_damage")
        
        local manaCostCM = abilityCM:GetManaCost()
        if abilityCM:IsHidden() then manaCostCM = manaCostCM + abilityR:GetManaCost() end
        if manaCostCM <= manaAvailable then
            if not magicImmune then
                manaAvailable = manaAvailable - manaCostCM
                dmgTotal = dmgTotal + enemy:GetActualIncomingDamage(mainDamage + burnDamage, DAMAGE_TYPE_MAGICAL)
                castTime = castTime + abilityCM:GetCastPoint()
                table.insert(comboQueue, 1, abilityCM)
            end
        end
    end
    
    -- Check Sun Strike
    if abilitySS:IsFullyCastable() then
        local ssDmg = abilitySS:GetSpecialValueFloat("damage")
        
        local manaCostSS = abilitySS:GetManaCost()
        if abilitySS:IsHidden() then manaCostSS = manaCostSS + abilityR:GetManaCost() end
        if manaCostSS <= manaAvailable then
            manaAvailable = manaAvailable - manaCostSS
            dmgTotal = dmgTotal + ssDmg
            castTime = castTime + abilitySS:GetCastPoint()
            table.insert(comboQueue, 1, abilitySS)
        end
    end
    
    -- TODO: Implement rest of spells and update order as necessary
    
    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function queueNuke(bot, enemy, castQueue, engageDist)
    local nTravelDist = abilityCM:GetSpecialValueInt( "travel_distance" )
    local nCastRange = abilityCM:GetCastRange()
    local dist = GetUnitToUnitDistance(bot, enemy)

    bot:Action_ClearActions(false)
    --setHeroVar("Queued", true)
    -- if out of range, attack move for one hit to get in range
    if dist > (nCastRange + nTravelDist/2) then
        bot:ActionPush_AttackUnit( enemy, true )
    end
    
    utils.AllChat("Killing "..utils.GetHeroName(enemy).." softly with my song")
    utils.myPrint("Queue Nuke Damage: ", utils.GetHeroName(enemy))
    for i = #castQueue, 1, -1 do
        local skill = castQueue[i]
        
        if skill:GetName() == "invoker_chaos_meteor" then
            if skill:IsHidden() then
                invokeChaosMeteor(bot)
            end
            
            if utils.IsCrowdControlled(enemy) then
                gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
            else
                gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetExtrapolatedLocation(1.35))
            end
        elseif skill:GetName() == "invoker_sun_strike" then
            if skill:IsHidden() then
                invokeSunStrike(bot)
            end
            
            if utils.IsCrowdControlled(enemy) then
                gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetLocation())
            else
                gHeroVar.HeroPushUseAbilityOnLocation(bot, skill, enemy:GetExtrapolatedLocation(1.75))
            end
        end
    end
end

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()

    if not bot:IsAlive() then return false end
    
    -- Check if we're already using an ability
    if bot:IsCastingAbility() or bot:IsChanneling() then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( "invoker_quas" ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( "invoker_wex" ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( "invoker_exort" ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( "invoker_invoke" ) end
    if abilityTO == "" then abilityTO = bot:GetAbilityByName( "invoker_tornado" ) end
    if abilityCS == "" then abilityCS = bot:GetAbilityByName( "invoker_cold_snap" ) end
    if abilityAC == "" then abilityAC = bot:GetAbilityByName( "invoker_alacrity" ) end
    if abilityGW == "" then abilityGW = bot:GetAbilityByName( "invoker_ghost_walk" ) end
    if abilityEMP == "" then abilityEMP = bot:GetAbilityByName( "invoker_emp" ) end
    if abilityCM == "" then abilityCM = bot:GetAbilityByName( "invoker_chaos_meteor" ) end
    if abilityDB == "" then abilityDB = bot:GetAbilityByName( "invoker_deafening_blast" ) end
    if abilityIW == "" then abilityIW = bot:GetAbilityByName( "invoker_ice_wall" ) end
    if abilitySS == "" then abilitySS = bot:GetAbilityByName( "invoker_sun_strike" ) end
    if abilityFS == "" then abilityFS = bot:GetAbilityByName( "invoker_forge_spirit" ) end

    -- Check if we were asked to use our globalEnemies
    local useGlobal = getHeroVar("UseGlobal")
    if useGlobal then
        local ability = useGlobal[1]
        local targetLoc = useGlobal[2]
        if ability:IsFullyCastable() then
            if ability:IsHidden() then
                if exortTrained() and abilityR:IsFullyCastable() then
                    bot:Action_ClearActions(true)
                    invokeSunStrike(bot)
                    bot:ActionQueue_UseAbilityOnLocation( ability, targetLoc )
                    return true
                end
            else
                bot:ActionPush_UseAbilityOnLocation( ability, targetLoc )
                return true
            end
        end
        setHeroVar("UseGlobal", nil)
    end
    
    castTODesire, castTOLocation = ConsiderTornado(bot, nearbyEnemyHeroes)
    castEMPDesire, castEMPLocation = ConsiderEMP(bot)
    castCMDesire, castCMLocation = ConsiderChaosMeteor(bot, nearbyEnemyHeroes)
    castDBDesire, castDBLocation = ConsiderDeafeningBlast(bot)
    castSSDesire, castSSLocation = ConsiderSunStrike(bot)
    castCSDesire, castCSTarget = ConsiderColdSnap(bot)
    castACDesire = ConsiderAlacrity(bot, nearbyEnemyHeroes, nearbyEnemyCreep, nearbyEnemyTowers)
    castGWDesire = ConsiderGhostWalk(bot, nearbyEnemyHeroes)
    castIWDesire = ConsiderIceWall(bot, nearbyEnemyHeroes)
    castFSDesire = ConsiderForgedSpirit(bot, nearbyEnemyHeroes, nearbyEnemyCreep, nearbyEnemyTowers)

    --[[
    print("TO "..castTODesire)
    print("EMP "..castEMPDesire)
    print("CM "..castCMDesire)
    print("DB "..castDBDesire)
    print("SS "..castSSDesire)
    print("CS "..castCSDesire)
    print("AC "..castACDesire)
    print("GW "..castGWDesire)
    print("IW "..castIWDesire)
    print("FS "..castFSDesire)
    --]]
    --if castSSDesire > 0 then utils.myPrint("\nSS "..castSSDesire.."\n") end

    if not inGhostWalk(bot) then
        -- NOTE: the castXXDesire accounts for skill being fully castable        
        if castTODesire > 0 then
            utils.myPrint("I want to Tornado")
            if not abilityTO:IsHidden() then
                bot:ActionPush_UseAbilityOnLocation( abilityTO, castTOLocation )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeTornado(bot)
                bot:ActionQueue_UseAbilityOnLocation( abilityTO, castTOLocation )
                return true
            end
        end
        
        if castCMDesire > 0 then
            utils.myPrint("I want to Chaos Meteor")
            if not abilityCM:IsHidden() then
                bot:ActionPush_UseAbilityOnLocation( abilityCM, castCMLocation )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeChaosMeteor(bot)
                bot:ActionQueue_UseAbilityOnLocation( abilityCM, castCMLocation )
                return true
            end
        end

        if castEMPDesire > 0 then
            utils.myPrint("I want to EMP")
            if not abilityEMP:IsHidden() then
                bot:ActionPush_UseAbilityOnLocation( abilityEMP, castEMPLocation )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeEMP(bot)
                bot:ActionQueue_UseAbilityOnLocation( abilityEMP, castEMPLocation )
                return true
            end
        end

        if castDBDesire > 0 then
            utils.myPrint("I want to Deafening Blast")
            if not abilityDB:IsHidden() then
                bot:ActionPush_UseAbilityOnLocation( abilityDB, castDBLocation )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeDeafeningBlast(bot)
                bot:ActionQueue_UseAbilityOnLocation( abilityDB, castDBLocation )
                return true
            end
        end

        if castCSDesire > 0 then
            utils.myPrint("I want to Cold Snap")
            if not abilityCS:IsHidden() then
                bot:ActionPush_UseAbilityOnEntity( abilityCS, castCSTarget )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeColdSnap(bot)
                bot:ActionQueue_UseAbilityOnEntity( abilityCS, castCSTarget )
                return true
            end
        end

        if castSSDesire > 0 then
            utils.myPrint("I want to Sunstrike")
            if not abilitySS:IsHidden() then
                bot:ActionPush_UseAbilityOnLocation( abilitySS, castSSLocation )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeSunStrike(bot)
                bot:ActionQueue_UseAbilityOnLocation( abilitySS, castSSLocation )
                return true
            end
        end
        
        if castACDesire > 0 then
            utils.myPrint("I want to Alacrity")
            if not abilityAC:IsHidden() then
                bot:ActionPush_UseAbilityOnEntity( abilityAC, bot )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeAlacrity(bot)
                bot:ActionQueue_UseAbilityOnEntity( abilityAC, bot )
                return true
            end
        end

        if castFSDesire > 0 then
            utils.myPrint("I want to Forge Spirit")
            if not abilityFS:IsHidden() then
                bot:ActionPush_UseAbility( abilityFS )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeForgedSpirit(bot)
                bot:ActionQueue_UseAbility( abilityFS )
                return true
            end
        end
        
        if castGWDesire > 0 then
            utils.myPrint("I want to Ghost Walk")
            if not abilityGW:IsHidden() then
                bot:ActionPush_UseAbility( abilityGW )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeGhostWalk(bot)
                bot:ActionQueue_UseAbility( abilityGW )
                return true
            end
        end

        if castIWDesire > 0 then
            utils.myPrint("I want to Ice Wall")
            if not abilityIW:IsHidden() then
                bot:ActionPush_UseAbility( abilityIW )
                return true
            elseif abilityR:IsFullyCastable() then
                bot:Action_ClearActions(true)
                invokeIceWall(bot)
                bot:ActionQueue_UseAbility( abilityIW )
                return true
            end
        end
        
        -- Determine what orbs we want
        if ConsiderOrbs(bot) then return true end
        
        if ConsiderShowUp(bot, nearbyEnemyHeroes) then return true end
    end
    
    -- Initial invokes at low levels
    if bot:GetLevel() == 1 and abilitySS:IsHidden() then
        invokeSunStrike(bot)
        return true
    elseif bot:GetLevel() == 2 and abilityCM:IsHidden() then
        tripleExortBuff(bot) -- this is first since we are pushing, not queueing
        invokeChaosMeteor(bot)
        return true
    end
    
    return false
end

function inGhostWalk(bot)
    return bot:HasModifier("modifier_invoker_ghost_walk")
end

function ConsiderShowUp(bot, nearbyEnemyHeroes)
    if inGhostWalk(bot) then
        if #nearbyEnemyHeroes <= 1 or bot:HasModifier("modifier_item_dust") then
            gHeroVar.HeroUseAbility(bot,  abilityW )
            gHeroVar.HeroUseAbility(bot,  abilityW )
            gHeroVar.HeroUseAbility(bot,  abilityW )
            return true
        end
    end
    
    return false
end

function quasTrained()
    return abilityQ:IsTrained()
end

function wexTrained()
    return abilityW:IsTrained()
end

function exortTrained()
    return abilityE:IsTrained()
end

function invokeTornado(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end
    
    utils.myPrint("invoking Tornado")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityW )
    bot:ActionPush_UseAbility( abilityQ )
    bot:ActionPush_UseAbility( abilityW )

    return true
end

function invokeChaosMeteor(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end
    
    utils.myPrint("invoking Chaos Meteor")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityE )
    bot:ActionPush_UseAbility( abilityW )
    bot:ActionPush_UseAbility( abilityE )

    return true
end

function invokeDeafeningBlast(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end
    
    utils.myPrint("invoking Deafening Blast")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityQ )
    bot:ActionPush_UseAbility( abilityW )
    bot:ActionPush_UseAbility( abilityE )
    
    return true
end

function invokeForgedSpirit(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end
    
    utils.myPrint("invoking Forged Spirit")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityE )
    bot:ActionPush_UseAbility( abilityQ )
    bot:ActionPush_UseAbility( abilityE )

    return true
end

function invokeIceWall(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end

    utils.myPrint("invoking Ice Wall")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityQ )
    bot:ActionPush_UseAbility( abilityQ )
    bot:ActionPush_UseAbility( abilityE )
    return true
end

function invokeEMP(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end
    
    utils.myPrint("invoking EMP")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityW )
    bot:ActionPush_UseAbility( abilityW )
    bot:ActionPush_UseAbility( abilityW )

    return true
end

function invokeColdSnap(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end

    utils.myPrint("invoking Cold Snap")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityQ )
    bot:ActionPush_UseAbility( abilityQ )
    bot:ActionPush_UseAbility( abilityQ )

    return true
end

function invokeSunStrike(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end

    utils.myPrint("invoking Sun Strike")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityE )
    bot:ActionPush_UseAbility( abilityE )
    bot:ActionPush_UseAbility( abilityE )

    return true
end

function invokeAlacrity(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end

    utils.myPrint("invoking Alacrity")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityW )
    bot:ActionPush_UseAbility( abilityE )
    bot:ActionPush_UseAbility( abilityW )

    return true
end

function invokeGhostWalk(bot)
    -- Make sure invoke is castable
    if not abilityR:IsFullyCastable() then
        return false
    end
    
    utils.myPrint("invoking Ghost Walk")

    bot:ActionPush_UseAbility( abilityR )
    bot:ActionPush_UseAbility( abilityQ )
    bot:ActionPush_UseAbility( abilityW )
    bot:ActionPush_UseAbility( abilityQ )

    return true
end

function tripleExortBuff(bot)
    if exortTrained() then
        bot:ActionPush_UseAbility( abilityE )
        bot:ActionPush_UseAbility( abilityE )
        bot:ActionPush_UseAbility( abilityE )
        return true
    end
    return false
end

function tripleQuasBuff(bot)
    if quasTrained() then
        bot:ActionPush_UseAbility( abilityQ )
        bot:ActionPush_UseAbility( abilityQ )
        bot:ActionPush_UseAbility( abilityQ )
        return true
    end
    return false
end

function tripleWexBuff(bot)
    if wexTrained() then
        bot:ActionPush_UseAbility( abilityW )
        bot:ActionPush_UseAbility( abilityW )
        bot:ActionPush_UseAbility( abilityW )
        return true
    end
    return false
end

function ConsiderOrbs(bot)
    local me = getHeroVar("Self")
    local botModifierCount = bot:NumModifiers()
    local nQuas = 0
    local nWex = 0
    local nExort = 0
    
    for i = 0, botModifierCount-1, 1 do
        local modName = bot:GetModifierName(i)
        if modName == "modifier_invoker_wex_instance" then
            nWex = nWex + 1
        elseif modName == "modifier_invoker_quas_instance" then
            nQuas = nQuas + 1
        elseif modName == "modifier_invoker_exort_instance" then
            nExort = nExort + 1
        end
        
        if (nWex + nQuas + nExort) >= 3 then break end
    end
    
    if getHeroVar("IsRetreating") or me:getCurrentMode() == constants.MODE_RETREAT then
        if nWex < 3 then 
            return tripleWexBuff(bot)
        end
    elseif bot:GetHealth()/bot:GetMaxHealth() < 0.75 then
        if nQuas < 3 then
            return tripleQuasBuff(bot)
        end
    else
        if nExort < 3 then
            return tripleExortBuff(bot)
        end
    end
    
    return false
end

function CanCastAlacrityOnTarget( target )
    return not target:IsMagicImmune() and not target:IsInvulnerable()
end

function CanCastColdSnapOnTarget( target )
    return target:CanBeSeen() and not target:IsMagicImmune() and not target:IsInvulnerable()
end

function CanCastDeafeningBlastOnTarget( target )
    return target:CanBeSeen() and not target:IsMagicImmune() and not target:IsInvulnerable()
end

function ConsiderTornado(bot, nearbyEnemyHeroes)
    if not quasTrained() or not wexTrained() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Make sure it's castable
    if not abilityTO:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Get some of its values
    local nDistance = abilityTO:GetSpecialValueInt( "travel_distance" )
    local nSpeed = 1000
    local nCastRange = abilityTO:GetCastRange()
    
    --------------------------------------
    -- Global high-priorty usage
    --------------------------------------

    -- Check for a channeling enemy
    for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
        if npcEnemy:IsChanneling() then
            return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
        end
    end

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    --------- RETREATING -----------------------
    if getHeroVar("IsRetreating") then
        for _,npcEnemy in pairs( nearbyEnemyHeroes ) do
            if bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and GetUnitToUnitDistance( bot, npcEnemy ) <= nDistance then
                return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetLocation()
            end
        end
    end

    --------- TEAM FIGHT --------------------------------
    if #nearbyEnemyHeroes >= 2 then
        local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, 200, 0, 0 )

        if locationAoE.count >= 2 then
            return BOT_ACTION_DESIRE_HIGH, locationAoE.targetloc
        end
    end

    --------- CHASING --------------------------------
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        local dist = GetUnitToUnitDistance( target.Obj, bot )
        if dist < (nDistance - 200) then
            return BOT_ACTION_DESIRE_MODERATE, target.Obj:GetExtrapolatedLocation( dist/nSpeed )
        end
    end

    return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderIceWall(bot, nearbyEnemyHeroes)
    if not quasTrained() or not exortTrained() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Make sure it's castable
    if  not abilityIW:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Get some of its values
    local nCastRange = abilityIW:GetSpecialValueInt( "wall_place_distance" )
    local nRadius = abilityIW:GetSpecialValueInt( "wall_element_radius" )

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    --------- RETREATING -----------------------
    if getHeroVar("IsRetreating") then
        for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
            if  bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) or GetUnitToUnitDistance(npcEnemy, bot) < (nCastRange + nRadius) then
                return BOT_ACTION_DESIRE_MODERATE
            end
        end
    end

    --------- CHASING --------------------------------
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        --FIXME: Need to check orientation
        if GetUnitToUnitDistance( bot, target.Obj ) < (nCastRange + nRadius) then
            return BOT_ACTION_DESIRE_MODERATE
        end
    end

    return BOT_ACTION_DESIRE_NONE
end


function ConsiderChaosMeteor(bot, nearbyEnemyHeroes)
    if not exortTrained() or not wexTrained() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Make sure it's castable
    if not abilityCM:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Get some of its values
    local nCastRange = abilityCM:GetCastRange()
    local nDelay = 1.35 -- 0.05 cast point, 1.3 land time
    local nTravelDistance = abilityCM:GetSpecialValueInt("travel_distance")
    local nRadius = abilityCM:GetSpecialValueInt("area_of_effect")

    --------------------------------------
    -- Mode based usage
    --------------------------------------
    if #nearbyEnemyHeroes >= 2 then
        local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange + nTravelDistance/2, nRadius, 0, 0 )
        if locationAoE.count >= 2 then
            return BOT_ACTION_DESIRE_HIGH, locationAoE.targetloc
        end
    end

    --------- CHASING --------------------------------
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        if GetUnitToUnitDistance( target, bot ) < (nCastRange + nTravelDistance/2) then
            if utils.IsCrowdControlled(target.Obj) then
                return BOT_ACTION_DESIRE_MODERATE, target.Obj:GetLocation()
            else
                return BOT_ACTION_DESIRE_MODERATE, target.Obj:GetExtrapolatedLocation( nDelay )
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, {}
end


function ConsiderSunStrike(bot)
    if not exortTrained() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Make sure it's castable
    if not abilitySS:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Get some of its values
    local nRadius = 175
    local nDelay = 2.0 -- 0.05 cast point, 1.7 delay, + some forgiveness
    local nDamage = abilitySS:GetSpecialValueFloat("damage")

    --------------------------------------
    -- Global Usage
    --------------------------------------
    local globalEnemies = GetUnitList(UNIT_LIST_ENEMY_HEROES)
    for _, enemy in pairs(globalEnemies) do
        if enemy:GetHealth() <= nDamage then
            if utils.IsCrowdControlled(enemy) then
                return BOT_ACTION_DESIRE_MODERATE, enemy:GetLocation()
            else
                return BOT_ACTION_DESIRE_MODERATE, enemy:GetExtrapolatedLocation( nDelay )
            end
        end
    end

    --------- CHASING --------------------------------
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        if utils.IsCrowdControlled(target.Obj) then
            return BOT_ACTION_DESIRE_MODERATE, target.Obj:GetLocation()
        else
            return BOT_ACTION_DESIRE_MODERATE, target.Obj:GetExtrapolatedLocation( nDelay )
        end
    end

    return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderDeafeningBlast(bot)
    if not quasTrained() or  not wexTrained() or not exortTrained() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Make sure it's castable
    if not abilityDB:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Get some of its values
    local nCastRange = abilityDB:GetCastRange()
    local nRadius = abilityDB:GetSpecialValueInt("radius_end")
    local nDamage = abilityDB:GetSpecialValueInt("damage")

    --------------------------------------
    -- Mode based usage
    --------------------------------------
    local tableNearbyAttackingAlliedHeroes = bot:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK )
    if ( #tableNearbyAttackingAlliedHeroes >= 1 )
    then
        local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0 )
        local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE )
        if ( locationAoE.count >= 2 and #tableNearbyEnemyHeroes > 0 )
        then
            for _,npcEnemy in pairs (tableNearbyEnemyHeroes)
            do
                if CanCastDeafeningBlastOnTarget (npcEnemy) then
                    return BOT_ACTION_DESIRE_HIGH, locationAoE.targetloc
                end
            end
        end
    end

    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
    if ( bot:GetActiveMode() == BOT_MODE_RETREAT and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH )
    then
        local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE )
        for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
        do
            if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and CanCastDeafeningBlastOnTarget (npcEnemy) )
            then
                return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetLocation()
            end
        end
    end

    -- If a mode has set a target, and we can kill them, do it
    local npcTarget = bot:GetTarget()
    if ( npcTarget ~= nil and npcTarget:IsHero() )
    then
        if( npcTarget:GetActualIncomingDamage( nDamage, DAMAGE_TYPE_MAGICAL  ) > npcTarget:GetHealth() and
            GetUnitToUnitDistance( npcTarget, bot ) < nCastRange - (nCastRange/3) and
            CanCastDeafeningBlastOnTarget (npcTarget) )
        then
            return BOT_ACTION_DESIRE_HIGH, npcTarget:GetLocation()
        end
    end

    -- If we're going after someone
    if ( bot:GetActiveMode() == BOT_MODE_ROAM or
         bot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
         bot:GetActiveMode() == BOT_MODE_GANK or
         bot:GetActiveMode() == BOT_MODE_ATTACK or
         bot:GetActiveMode() == BOT_MODE_DEFEND_ALLY )
    then
        local npcTarget = bot:GetTarget()

        if ( npcTarget ~= nil and npcTarget:IsHero() and
            GetUnitToUnitDistance( npcTarget, bot ) < nCastRange - (nCastRange/3) and
            CanCastDeafeningBlastOnTarget (npcTarget) )
        then
            return BOT_ACTION_DESIRE_MODERATE, npcTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderEMP(bot)
    if not wexTrained() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Make sure it's castable
    if not abilityEMP:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, {}
    end

    -- Get some of its values
    local nCastRange = abilityEMP:GetCastRange()
    local nRadius = abilityEMP:GetSpecialValueInt( "area_of_effect" )
    local nBurn = abilityEMP:GetSpecialValueInt( "mana_burned" )
    local nPDamage = abilityEMP:GetSpecialValueInt( "damage_per_mana_pct" )

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    local tableNearbyAttackingAlliedHeroes = bot:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK )
    if ( #tableNearbyAttackingAlliedHeroes >= 1 )
    then
        local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, ( nRadius/2 ), 0, 0 )

        if ( locationAoE.count >= 2 )
        then
            return BOT_ACTION_DESIRE_HIGH, locationAoE.targetloc
        end
    end

    -- If we're going after someone
    if ( bot:GetActiveMode() == BOT_MODE_ROAM or
         bot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
         bot:GetActiveMode() == BOT_MODE_GANK or
         bot:GetActiveMode() == BOT_MODE_ATTACK or
         bot:GetActiveMode() == BOT_MODE_DEFEND_ALLY )
    then
        local npcTarget = bot:GetTarget()

        if ( npcTarget ~= nil and npcTarget:HasModifier("modifier_invoker_tornado") and GetUnitToUnitDistance( npcTarget, bot ) < (nCastRange - (nRadius / 2)) )
        then
            return BOT_ACTION_DESIRE_MODERATE, npcTarget:GetLocation( )
        end
    end

    return BOT_ACTION_DESIRE_NONE, {}
end

function ConsiderGhostWalk(bot, nearbyEnemyHeroes)
    if not quasTrained() or not wexTrained() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Make sure it's castable
    if not abilityGW:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- WE ARE RETREATNG AND THEY ARE ON US
    if getHeroVar("IsRetreating") then
        for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
            if bot:WasRecentlyDamagedByHero( npcEnemy, 1.0 ) and GetUnitToUnitDistance( npcEnemy, bot ) < 600 then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end


function ConsiderColdSnap(bot)
    if not quasTrained() then
        return  BOT_ACTION_DESIRE_NONE, nil
    end

    -- Make sure it's castable
    if not abilityCS:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    -- Get some of its values
    local nCastRange = abilityCS:GetCastRange()

    --------------------------------------
    -- Global high-priorty usage
    --------------------------------------

    -- Check for a channeling enemy
    local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE )
    for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
    do
        if ( npcEnemy:IsChanneling() )
        then
            return BOT_ACTION_DESIRE_HIGH, npcEnemy
        end
    end

    --------------------------------------
    -- Mode based usage
    --------------------------------------

    -- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
    if ( bot:GetActiveMode() == BOT_MODE_RETREAT and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH )
    then
        local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE )
        for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
        do
            if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and CanCastColdSnapOnTarget(npcEnemy) )
            then
                return BOT_ACTION_DESIRE_MODERATE, npcEnemy
            end
        end
    end

    local tableNearbyAttackingAlliedHeroes = bot:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK )
    if ( #tableNearbyAttackingAlliedHeroes >= 1 )
    then
        local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE )
        for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
        do
            if ( GetUnitToUnitDistance( npcEnemy, bot ) < ( nCastRange ) and CanCastColdSnapOnTarget(npcEnemy) )
            then
                return BOT_ACTION_DESIRE_MODERATE, npcEnemy
            end
        end
    end


    -- If we're going after someone
    if ( bot:GetActiveMode() == BOT_MODE_ROAM or
         bot:GetActiveMode() == BOT_MODE_TEAM_ROAM or
         bot:GetActiveMode() == BOT_MODE_GANK or
         bot:GetActiveMode() == BOT_MODE_ATTACK or
         bot:GetActiveMode() == BOT_MODE_DEFEND_ALLY )
    then
        local npcTarget = bot:GetTarget()

        if ( npcTarget ~= nil and GetUnitToUnitDistance( npcTarget, bot ) < nCastRange and CanCastColdSnapOnTarget(npcTarget) )
        then
            return BOT_ACTION_DESIRE_HIGH, npcTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function ConsiderAlacrity(bot, nearbyEnemyHeroes, nearbyEnemyCreep, nearbyEnemyTowers)
    if not wexTrained() or not exortTrained() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Make sure it's castable
    if not abilityAC:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end

    --------------------------------------
    -- Global high-priorty usage
    --------------------------------------
    -- If we're pushing or defending a lane and can hit 4+ creeps, go for it
    if getHeroVar("ShouldDefend") or getHeroVar("ShouldPush") then
        if #nearbyEnemyCreep >= 3 or #nearbyEnemyTowers > 0 then
            return BOT_ACTION_DESIRE_LOW
        end
    end
    --------------------------------------
    -- Mode based usage
    --------------------------------------
    for _,npcEnemy in pairs( nearbyEnemyHeroes ) do
        if GetUnitToUnitDistance( npcEnemy, bot ) < 600 then
            return BOT_ACTION_DESIRE_MODERATE
        end
    end

    --------- CHASING --------------------------------
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        return BOT_ACTION_DESIRE_MODERATE
    end

    local me = getHeroVar("Self")
    if me:GetMode() == constants.MODE_ROSHAN then
        local npcTarget = bot:GetTarget()
        if utils.NotNilOrDead(npcTarget) then
            return BOT_ACTION_DESIRE_LOW
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function ConsiderForgedSpirit(bot, nearbyEnemyHeroes, nearbyEnemyCreep, nearbyEnemyTowers)
    if not quasTrained() or not exortTrained() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Make sure it's castable
    if abilityFS:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end

    local me = getHeroVar("Self")
    if me:GetMode() == constants.MODE_ROSHAN then
        local npcTarget = bot:GetTarget()
        if utils.NotNilOrDead(npcTarget) then
            return BOT_ACTION_DESIRE_LOW
        end
    end

    --------------------------------------
    -- Global high-priorty usage
    --------------------------------------
    -- If we're pushing or defending a lane and can hit 4+ creeps, go for it
    if getHeroVar("ShouldDefend") or getHeroVar("ShouldPush") then
        if #nearbyEnemyCreep >= 3 or #nearbyEnemyTowers > 0 then
            return BOT_ACTION_DESIRE_LOW
        end
    end
    --------------------------------------
    -- Mode based usage
    --------------------------------------
    for _,npcEnemy in pairs( nearbyEnemyHeroes ) do
        if GetUnitToUnitDistance( npcEnemy, bot ) < 600 then
            return BOT_ACTION_DESIRE_MODERATE
        end
    end

    --------- CHASING --------------------------------
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        return BOT_ACTION_DESIRE_MODERATE
    end

    return BOT_ACTION_DESIRE_NONE
end

for k,v in pairs( ability_usage_invoker ) do _G._savedEnv[k] = v end
