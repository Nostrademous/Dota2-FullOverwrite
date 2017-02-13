-------------------------------------------------------------------------------
--- AUTHOR: Yavimaya, Nostrademous (adjusted code for our framework)
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_venomancer", package.seeall )

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

----------------------------------------------------------

local Abilities =   {
    "venomancer_venomous_gale",
    "venomancer_poison_sting",
    "venomancer_plague_ward",
    "venomancer_poison_nova"
}

local castPNDesire = 0
local castPWDesire = 0
local castVGDesire = 0

local function comboDamage( bot, enemy, abilityVG, abilityPN )
    --FIXME: Implement
    local mana = bot:GetMana()
    local manaCostCombo = abilityVG:GetManaCost() + abilityPN:GetManaCost()
    
    if (mana < manaCostCombo) or (not abilityVG:IsFullyCastable()) or (not abilityPN:IsFullyCastable()) then return 0, 0 end
    
    -- Venomous Gale deals tick_damage every 3.0 seconds over 15.0 second period
    local damageVG = abilityVG:GetSpecialValueInt("strike_damage") + abilityVG:GetSpecialValueInt("tick_damage")*5.0
    
    -- Poison Nove deals damage in 1 second intervals, starting immediately as the debuff is placed, resulting in 17 instances
    local damagePN = 0
    if bot:HasScepter() then
        damagePN = abilityPN:GetSpecialValueInt("damage_scepter") * 17.0
    else
        damagePN = abilityPN:GetSpecialValueInt("damage") * 17.0
    end
    
    local actualDmgCombo = enemy:GetActualIncomingDamage(damagePN + damageVG, DAMAGE_TYPE_MAGICAL)
end

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()
    if not bot:IsAlive() then return false end

    -- Check if we're already using an ability
    if ( bot:IsUsingAbility() or bot:IsChanneling() ) then return false end

    local abilityVG = bot:GetAbilityByName( Abilities[1] )
    local abilityPW = bot:GetAbilityByName( Abilities[3] )
    local abilityPN = bot:GetAbilityByName( Abilities[4] )

    -- Consider using each ability
    castPNDesire = ConsiderPoisonNova(bot, abilityPN, nearbyEnemyHeroes)
    castPWDesire, castPWLocation = ConsiderPlagueWard(bot, abilityPW, nearbyEnemyHeroes, nearbyEnemyCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    castVGDesire, castVGLocation = ConsiderVenomGale(bot, abilityVG, nearbyEnemyHeroes, nearbyEnemyCreep)

    if castPNDesire > castPWDesire and castPNDesire > castVGDesire then
        gHeroVar.HeroUseAbility(bot,  abilityPN )
        return true
    end

    if castPWDesire > 0 then
        bot:Action_UseAbilityOnLocation( abilityPW, castPWLocation )
        return true
    end

    if castVGDesire > 0 then
        bot:Action_UseAbilityOnLocation( abilityVG, castVGLocation )
        return true
    end

    return false
end

----------------------------------------------------------

function CanCastPlagueWardOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and not utils.IsTargetMagicImmune(npcTarget)
end

function CanCastVenomGaleOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and not utils.IsTargetMagicImmune(npcTarget)
end

function CanCastPoisonNovaOnTarget( npcTarget )
    return npcTarget:CanBeSeen() and npcTarget:IsHero() and not utils.IsTargetMagicImmune(npcTarget)
end

----------------------------------------------------------
function ConsiderVenomGale(npcBot, abilityVG, nearbyEnemyHeroes, nearbyEnemyCreep)
    -- Make sure it's castable
    if not abilityVG:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- Get some of its values
    local nCastRange = abilityVG:GetCastRange()
    local nRadius = 125

    --------- RETREATING ----------------------------
    if getHeroVar("IsRetreating") then
        for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
            if GetUnitToUnitDistance(npcBot, npcEnemy) < (nCastRange - 100) and npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
                if CanCastVenomGaleOnTarget( npcEnemy ) then
                    return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
                end
            end
        end
    end

    --------- CHASING --------------------------------
    local npcTarget = getHeroVar("Target")
    if utils.ValidTarget(npcTarget) then
        if CanCastVenomGaleOnTarget( npcTarget.Obj )  then
            if GetUnitToUnitDistance( npcTarget.Obj, npcBot ) < nCastRange then
                return BOT_ACTION_DESIRE_HIGH, npcTarget.Obj:GetLocation()
            end
        end
    end
    
    --------- LANING ---------------------------
    if utils.IsInLane() then
        if npcBot:GetMana()/npcBot:GetMaxMana() >= 0.8 and utils.IsCore() then
            if #nearbyEnemyCreep > 0 and GetUnitToUnitDistance(npcBot, nearbyEnemyCreep[1]) < nCastRange then
                return BOT_ACTION_DESIRE_LOW, nearbyEnemyCreep[1]:GetLocation()
            end
        elseif npcBot:GetMana()/npcBot:GetMaxMana() >= 0.5 then
            local weakHero, weakHealth = utils.GetWeakestHero(npcBot, nCastRange + 200)
            if weakHero and weakHealth/weakHero:GetMaxHealth() < 0.6 then
                return BOT_ACTION_DESIRE_LOW, weakHero:GetLocation()
            end
        end
    end
    
    return BOT_ACTION_DESIRE_NONE, 0
end

----------------------------------------------------------
function ConsiderPlagueWard(npcBot, abilityPW, nearbyEnemyHeroes, nearbyEnemyCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    -- Make sure it's castable
    if not abilityPW:IsFullyCastable() or abilityPW:GetLevel() < 2 then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- If we want to cast Poison Nova at all, bail
    if castPNDesire > 0 then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- Get some of its values
    local nCastRange = abilityPW:GetCastRange()

    ------------ PUSH TOWER -----------------------
    if getHeroVar("ShouldPush") then
        if #nearbyEnemyTowers > 0 and GetUnitToUnitDistance(npcBot, nearbyEnemyTowers[1]) < nCastRange then
            return BOT_ACTION_DESIRE_LOW, nearbyEnemyTowers[1]:GetLocation()
        end
    end

    ------------ DEFEND TOWER -----------------------
    if getHeroVar("ShouldDefend") then
        if #nearbyAlliedTowers > 0 and GetUnitToUnitDistance(npcBot, nearbyAlliedTowers[1]) < nCastRange then
            return BOT_ACTION_DESIRE_MODERATE, nearbyAlliedTowers[1]:GetLocation()
        end
    end

    ------------ RETREATING -----------------------
    if getHeroVar("IsRetreating") then
        for _,npcEnemy in pairs( nearbyEnemyHeroes ) do
            if npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and GetUnitToUnitDistance(npcBot, npcEnemy) < (nCastRange+200) then
                if ( CanCastPlagueWardOnTarget( npcEnemy ) ) then
                    return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetLocation()
                end
            end
        end
    end

    ------------ CHASING ------------------------------
    local npcTarget = getHeroVar("Target")
    if utils.ValidTarget(npcTarget) then
        if GetUnitToUnitDistance(npcTarget.Obj, npcBot) < nCastRange then
            return BOT_ACTION_DESIRE_HIGH, npcTarget:GetLocation()
        end
    end

    ------------ LANING ---------------------------
    if utils.IsInLane() then
        if utils.IsCore() and npcBot:GetMana()/npcBot:GetMaxMana() >= 0.1 then
            if #nearbyEnemyCreep > 0 and GetUnitToUnitDistance(npcBot, nearbyEnemyCreep[1]) < nCastRange then
                return BOT_ACTION_DESIRE_LOW, nearbyEnemyCreep[1]:GetLocation()
            end
        elseif npcBot:GetMana()/npcBot:GetMaxMana() >= 0.25 then
            local weakHero, _ = utils.GetWeakestHero(npcBot, nCastRange + 200)
            if weakHero then
                return BOT_ACTION_DESIRE_LOW, weakHero:GetLocation()
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

----------------------------------------------------------
function ConsiderPoisonNova(npcBot, abilityPN, nearbyEnemyHeroes)
    -- Make sure it's castable
    if not abilityPN:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Get some of its values
    local nRadius = abilityPN:GetSpecialValueInt( "radius" )
    local nCastRange = 0
    local nDamage = abilityPN:GetAbilityDamage()

    --------- RETREATING -----------------------------------
    if getHeroVar("IsRetreating") then
        for _, npcEnemy in pairs( nearbyEnemyHeroes ) do
            if GetUnitToUnitDistance(npcBot, npcEnemy) < (nCastRange + nRadius) and npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
                if CanCastPoisonNovaOnTarget( npcEnemy ) then
                    return BOT_ACTION_DESIRE_MODERATE
                end
            end
        end
    end

    --------- CHASING -------------------------------
    local npcTarget = getHeroVar("Target")
    if utils.ValidTarget(npcTarget) then
        if CanCastPoisonNovaOnTarget( npcTarget.Obj ) and GetUnitToUnitDistance( npcBot, npcTarget.Obj ) < nRadius then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    --------- if we're in creep wave and in range of enemy hero -----
    if utils.IsInLane() then
        if #nearbyEnemyHeroes > 0 then
            local npcTarget = nearbyEnemyHeroes[1]

            if CanCastPoisonNovaOnTarget( npcTarget ) and GetUnitToUnitDistance( npcBot, npcTarget ) < nRadius then
                local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), 0, nRadius, 0.0, 100000 )
                if locationAoE.count >= 3 then
                    return BOT_ACTION_DESIRE_MODERATE
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

for k,v in pairs( ability_usage_venomancer ) do _G._savedEnv[k] = v end