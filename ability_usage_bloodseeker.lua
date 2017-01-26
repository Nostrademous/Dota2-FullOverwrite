-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_bloodseeker", package.seeall )

require( GetScriptDirectory().."/fight_simul" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

local Abilities ={
    "bloodseeker_bloodrage",
    "bloodseeker_blood_bath",
    "bloodseeker_thirst",
    "bloodseeker_rupture"
};

local function UseW()
    local npcBot = GetBot()
    local ability = npcBot:GetAbilityByName(Abilities[2])
    if ability == nil or (not ability:IsFullyCastable()) then return false end

    local ult = npcBot:GetAbilityByName(Abilities[4])

    local Enemies = npcBot:GetNearbyHeroes(1500, true, BOT_MODE_NONE)

    if #Enemies == 1 and ( ult ~= nil and ult:IsFullyCastable() ) then
        setHeroVar("Target", Enemies[1])
        return false
    end

    local target = getHeroVar("Target")
    if target ~= nil and GetUnitToUnitDistance(npcBot, target) > 1500 then
        return false
    end

    if #Enemies == 1 then
        local delay = ability:GetSpecialValueFloat("delay_plus_castpoint_tooltip")
        npcBot:Action_UseAbilityOnLocation(ability, Enemies[1]:GetExtrapolatedLocation(delay))
        return true
    else
        local center = utils.GetCenter(Enemies)
        if center ~= nil then
            npcBot:Action_UseAbilityOnLocation(ability, center)
            return true
        end
    end

    return false
end

local function UseUlt()
    -- TODO: don't use it if we can kill the enemy by rightclicking / have teammates around
    local npcBot = GetBot()
    local ability = npcBot:GetAbilityByName(Abilities[4])
    if ability == nil or (not ability:IsFullyCastable()) then return false end

    local enemy = getHeroVar("Target")
    if enemy == nil then return false end
    
    --[[
    local enemyTowers = npcBot:GetNearbyTowers(1200, true)
    local enemyHeroes = npcBot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    if #enemyHeroes == 0 and #enemyTowers == 0 and (enemy:GetHealth()/enemy:GetMaxHealth()) < 0.2 then
        return false
    end
    --]]
    local timeToKillRightClicking = fight_simul.estimateTimeToKill(npcBot, enemy)
    utils.myPrint("Estimating Time To Kill with Right Clicks: ", timeToKillRightClicking)
    if timeToKillRightClicking < 3.0 then
        utils.myPrint("Not Using Ult")
        return false
    end

    if GetUnitToUnitDistance(enemy, npcBot) < (ability:GetCastRange() - 100) then
        npcBot:Action_UseAbilityOnEntity(ability, enemy)
        return true
    end

    return false
end

local function UseQ()
    local npcBot = GetBot()
    local ability = npcBot:GetAbilityByName(Abilities[1])
    if ability == nil or (not ability:IsFullyCastable()) then return false end

    local enemy = getHeroVar("Target")
    if enemy ~= nil and GetUnitToUnitDistance(enemy, npcBot) < (ability:GetCastRange() - 100) then
        npcBot:Action_UseAbilityOnEntity(ability, enemy)
        return true
    end
    
    if npcBot:HasModifier("modifier_bloodseeker_bloodrage") then return false end
    
    npcBot:Action_UseAbilityOnEntity(ability, npcBot)
    return true
end

function AbilityUsageThink()
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local npcBot = GetBot()

    if npcBot:IsChanneling() or npcBot:IsUsingAbility() then return false end

    if getHeroVar("Target") == nil then return false end

    if UseQ() or UseUlt() or UseW() then return true end
end

for k,v in pairs( ability_usage_bloodseeker ) do _G._savedEnv[k] = v end
