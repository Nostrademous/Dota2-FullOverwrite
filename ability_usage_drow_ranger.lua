-------------------------------------------------------------------------------
--- AUTHOR: pbenologa, Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_drow_ranger", package.seeall )

require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    local bot = bot or GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = bot or GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local Abilities ={
    "drow_ranger_frost_arrows",
    "drow_ranger_wave_of_silence",
    "drow_ranger_trueshot",
    "drow_ranger_marksmanship"
}

local function UseQ(bot)
    local ability = bot:GetAbilityByName(Abilities[1])

    if (ability == nil) or (not ability:IsFullyCastable()) then
        return false
    end

    local target = getHeroVar("Target")

    -- if we don't have a valid target, return
    if not utils.ValidTarget(target) then return false end

    -- if target is magic immune or invulnerable and is crowd controlled, return
    if utils.IsTargetMagicImmune(target.Obj) and utils.IsCrowdControlled(target.Obj) then return false end

    if GetUnitToUnitDistance(bot, target.Obj) < (ability:GetCastRange() + 100) then
        utils.TreadCycle(bot, constants.INTELLIGENCE)
        bot:Action_UseAbilityOnEntity(ability, target.Obj)
        return true
    end

    return false
end

local function UseW(bot)
    local gust = bot:GetAbilityByName(Abilities[2])

    if (gust == nil) or (not gust:IsFullyCastable()) then
        return false
    end

    local Enemies = bot:GetNearbyHeroes(gust:GetCastRange(), true, BOT_MODE_NONE)

    if #Enemies == 0 then return false end

    local wave_speed = gust:GetSpecialValueFloat("wave_speed")
    local delay = gust:GetCastPoint() + GetUnitToUnitDistance(bot, Enemies[1])/wave_speed

    if #Enemies == 1 then
        local enemyHasStun = Enemies[1]:GetStunDuration(true) > 0
        if not utils.IsTargetMagicImmune(Enemies[1]) or not utils.IsCrowdControlled(Enemies[1]) 
        or (not Enemies[1]:IsSilenced()) or Enemies[1]:IsChanneling() 
        and (GetUnitToUnitDistance(bot, Enemies[1]) < 450 or (enemyHasStun and Enemies[1]:IsUsingAbility()) then 
            utils.TreadCycle(bot, constants.INTELLIGENCE)
            bot:Action_UseAbilityOnLocation(gust, Enemies[1]:GetExtrapolatedLocation(delay))
            return true
        end
    else
        for _, enemy in pairs( Enemies ) do
            if enemy:IsChanneling() then
                if gust:GetCastRange() > GetUnitToUnitDistance(bot, enemy) and (not enemy:IsMagicImmune()) then
                    local gustDelay = gust:GetCastPoint() + GetUnitToUnitDistance(bot, enemy)/wave_speed
                    utils.TreadCycle(bot, constants.INTELLIGENCE)
                    bot:Action_UseAbilityOnLocation(gust, enemy:GetExtrapolatedLocation(gustDelay))
                    return true
                end
            end
        end

        --Use Gust as a Defensive skill to fend off chasing enemies
        if getHeroVar("IsRetreating") and (bot:GetHealth()/bot:GetMaxHealth()) < 0.5 then
            for _, enemy in pairs( Enemies ) do
                if gust:GetCastRange() > GetUnitToUnitDistance(bot, enemy) and (not enemy:IsMagicImmune()) then
                    local gustDelay = gust:GetCastPoint() + GetUnitToUnitDistance(bot, enemy)/wave_speed
                    utils.TreadCycle(bot, constants.INTELLIGENCE)
                    bot:Action_UseAbilityOnLocation(gust, enemy:GetExtrapolatedLocation(gustDelay))
                    return true
                end
            end
        end

        local center = utils.GetCenter(Enemies)
        if center ~= nil then
            utils.TreadCycle(bot, constants.INTELLIGENCE)
            bot:Action_UseAbilityOnLocation(gust, center)
            return true
        end
    end

    return false
end

local function UseE(bot)
    local trueshot = bot:GetAbilityByName(Abilities[3])

    if (trueshot == nil) or (not trueshot:IsFullyCastable()) then
        return false
    end
    -- TODO: use GetAttackTarget() to check if drow is attacking a tower before using trueshot not sure which is better
    local towersNearby = bot:GetNearbyTowers(bot:GetAttackRange(), true)

    if towersNearby == nil then return false end

    local alliedCreeps = bot:GetNearbyCreeps(900, false)

    for i, creeps in ipairs(alliedCreeps) do
        if (utils.IsMelee(creeps)) then
            table.remove(alliedCreeps, 1 )
        end
    end

    if (towersNearby ~= nil and #alliedCreeps > 3) then
        bot:Action_UseAbility(trueshot)
        return true
    end

    return false
end

function AbilityUsageThink()
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local bot = GetBot()

    if bot:IsChanneling() or bot:IsUsingAbility() then return false end

    if UseE(bot) then return true end

    if UseW(bot) or UseQ(bot) then return true end
end

for k,v in pairs( ability_usage_drow_ranger ) do _G._savedEnv[k] = v end
