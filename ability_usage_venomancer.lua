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

local castPNDesire = 0
local castPWDesire = 0
local castVGDesire = 0

function AbilityUsageThink()
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()
    if not npcBot:IsAlive() then return false end

    -- Check if we're already using an ability
    if ( npcBot:IsUsingAbility() or npcBot:IsChanneling() ) then return false end

    abilityPW = bot:GetAbilityByName( "venomancer_plague_ward" )
    abilityVG = bot:GetAbilityByName( "venomancer_venomous_gale" )
    abilityPN = bot:GetAbilityByName( "venomancer_poison_nova" )

    -- Consider using each ability
    castPNDesire = ConsiderPoisonNova(bot)
    castPWDesire, castPWLocation = ConsiderPlagueWard(bot)
    castVGDesire, castVGLocation = ConsiderVenomGale(bot)

    if castPNDesire > castPWDesire and castPNDesire > castVGDesire then
        bot:Action_UseAbility( abilityPN )
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
    return npcTarget:CanBeSeen() and npcTarget:IsHero() and ( GetBot():HasScepter() or not npcTarget:IsMagicImmune() ) and not npcTarget:IsInvulnerable()
end

----------------------------------------------------------
function ConsiderPlagueWard(npcBot)
    -- Make sure it's castable
    if not abilityPW:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- If we want to cast Poison Nova at all, bail
    if castPNDesire > 0 then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- Get some of its values
    local nCastRange = abilityPW:GetCastRange()

    ----------- PUSH TOWER -----------------------
    if getHeroVar("ShouldPush") then
        local tableNearbyTowers = npcBot:GetNearbyTowers( 800, true)
        if tableNearbyTowers[1] > 0 and not tableNearbyTowers[1]:IsInvulnerable() then
            return BOT_ACTION_DESIRE_LOW, tableNearbyTowers[1]:GetLocation()
        end
    end

    ----------- DEFEND TOWER -----------------------
    if getHeroVar("ShouldDefend") then
        local tableNearbyTowers = npcBot:GetNearbyTowers( 800, false)
        if tableNearbyTowers[1] > 0 and not tableNearbyTowers[1]:IsInvulnerable() then
            return BOT_ACTION_DESIRE_MODERATE, tableNearbyTowers[1]:GetLocation()
        end
    end

    ---------- RETREATING -----------------------
    if getHeroVar("IsRetreating") then
        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + 200, true, BOT_MODE_NONE )
        for _,npcEnemy in pairs( tableNearbyEnemyHeroes ) do
            if ( npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) ) then
                if ( CanCastPlagueWardOnTarget( npcEnemy ) ) then
                    return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetLocation()
                end
            end
        end
    end

    ---------- CHASING ------------------------------
    local npcTarget = getHeroVar("Target")
    if utils.ValidTarget(npcTarget) then
        if GetUnitToUnitDistance(npcTarget.Obj, npcBot) < nCastRange then
            return BOT_ACTION_DESIRE_HIGH, npcTarget:GetLocation()
        end
    end

    ----------- LANING ---------------------------
    if utils.IsInLane() and npcBot:GetMana()/npcBot:GetMaxMana() >= 0.1 then
        local tableNearbyEnemyCreeps = npcBot:GetNearbyCreeps( 1000, true)
        if #tableNearbyEnemyCreeps > 0 then
            return BOT_ACTION_DESIRE_LOW, tableNearbyEnemyCreeps[1]:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

----------------------------------------------------------
function ConsiderVenomGale(npcBot)
    -- Make sure it's castable
    if not abilityVG:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- Get some of its values
    local nCastRange = abilityVG:GetCastRange()
    local nRadius = 125

    --------- RETREATING ----------------------------
    if getHeroVar("IsRetreating") then
        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange - 100, true, BOT_MODE_NONE )
        for _, npcEnemy in pairs( tableNearbyEnemyHeroes ) do
            if npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
                if CanCastVenomGaleOnTarget( npcEnemy ) then
                    return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
                end
            end
        end
    end

    ---------- CHASING --------------------------------
    local npcTarget = getHeroVar("Target")
    if utils.ValidTarget(npcTarget) then
        if CanCastVenomGaleOnTarget( npcTarget.Obj )  then
            if GetUnitToUnitDistance( npcTarget.Obj, npcBot ) < nCastRange then
                return BOT_ACTION_DESIRE_HIGH, npcTarget.Obj:GetLocation()
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end


----------------------------------------------------------
function ConsiderPoisonNova(npcBot)
    -- Make sure it's castable
    if not abilityPN:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Get some of its values
    local nRadius = abilityPN:GetSpecialValueInt( "radius" )
    local nCastRange = 0
    local nDamage = abilityPN:GetAbilityDamage()

    ------- RETREATING -----------------------------------
    if getHeroVar("IsRetreating") then
        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( nCastRange + nRadius, true, BOT_MODE_NONE )
        for _, npcEnemy in pairs( tableNearbyEnemyHeroes ) do
            if npcBot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) then
                if CanCastPoisonNovaOnTarget( npcEnemy ) then
                    return BOT_ACTION_DESIRE_MODERATE
                end
            end
        end
    end

    ------ CHASING -------------------------------
    local npcTarget = getHeroVar("Target")
    if utils.ValidTarget(npcTarget) then
        if CanCastPoisonNovaOnTarget( npcTarget.Obj ) and GetUnitToUnitDistance( npcBot, npcTarget.Obj ) < nRadius then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    -------- if we're in creep wave and in range of enemy hero -----
    if utils.IsInLane() then
        local tableNearbyEnemyHeroes = npcBot:GetNearbyHeroes( 1300, true, BOT_MODE_NONE )

        if #tableNearbyEnemyHeroes > 0 then
            local npcTarget = tableNearbyEnemyHeroes[1]

            if npcTarget ~= nil then
                if CanCastPoisonNovaOnTarget( npcTarget ) and GetUnitToUnitDistance( npcBot, npcTarget ) < nRadius then
                    local locationAoE = npcBot:FindAoELocation( true, false, npcBot:GetLocation(), 0, nRadius, 0.0, 100000 )
                    if locationAoE.count >= 3 then
                        return BOT_ACTION_DESIRE_MODERATE
                    end
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

for k,v in pairs( ability_usage_venomancer ) do _G._savedEnv[k] = v end