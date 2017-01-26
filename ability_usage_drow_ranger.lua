-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_drow_ranger", package.seeall )

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

local function UseQ()
    local npcBot = GetBot()

    local frostArrow = npcBot:GetAbilityByName(Abilities[1])

    if (frostArrow == nil) or (not frostArrow:IsFullyCastable()) then
        return false
    end

    local Enemies = npcBot:GetNearbyHeroes(frostArrow:GetCastRange() + 100, true, BOT_MODE_NONE)
    table.sort(Enemies, function(n1, n2) return n1:GetHealth() < n2:GetHealth() end) -- sort by health

    if #Enemies == 1 then
        setHeroVar("Target", Enemies[#Enemies])
        return false
    end

    local target = getHeroVar("Target") -- get highest health enemy

    if target ~= nil and GetUnitToUnitDistance(npcBot, target) < frostArrow:GetCastRange() and (not target:IsRooted()) or (not target:IsStunned()) then
        npcBot:Action_UseAbilityOnEntity(frostArrow, target)
        return true
    end

    if (npcBot:GetMana()/npcBot:GetMaxMana()) > 0.5 and #Enemies > 0 and #Enemies < 3 and (getHeroVar("OutOfRangeCasting") + frostArrow:GetCastPoint()) < GameTime() then
        local weakestHero, weakestHeroHealth = utils.GetWeakestHero(npcBot, frostArrow:GetCastRange() + 100)
        if weakestHero ~= nil and (not weakestHero:IsRooted()) or (not weakestHero:IsStunned()) then
            npcBot:Action_UseAbilityOnEntity(frostArrow, weakestHero)
            setHeroVar("OutOfRangeCasting", GameTime())
            return true
        end
    end

    return false
end

local function UseW()
    local npcBot = GetBot()

    local gust = npcBot:GetAbilityByName(Abilities[2])

    if (gust == nil) or (not gust:IsFullyCastable()) then
        return false
    end

    local Enemies = npcBot:GetNearbyHeroes(gust:GetCastRange(), true, BOT_MODE_NONE)

    if #Enemies == 0 then return false end

    local enemy = getHeroVar("Target")
    if enemy == nil then return false end

    if #Enemies == 1 then
        local wave_speed = gust:GetSpecialValueFloat("wave_speed")
        local delay = gust:GetCastPoint() + GetUnitToUnitDistance(npcBot, Enemies[1])/wave_speed
        if (not enemy:IsSilenced()) or (not enemy:IsRooted()) or (not enemy:IsStunned()) and GetUnitToUnitDistance(npcBot, Enemies[1]) < 350 then
            npcBot:Action_UseAbilityOnLocation(gust, Enemies[1]:GetExtrapolatedLocation(delay))
            return true
        end
    else
        local center = utils.GetCenter(Enemies)
        if center ~= nil then
            npcBot:Action_UseAbilityOnLocation(gust, center)
            return true
        end
    end

    return false
end

local function UseE()
    local npcBot = GetBot()

    local trueshot = npcBot:GetAbilityByName(Abilities[3])

    if (trueshot == nil) or (not trueshot:IsFullyCastable()) then
        return false
    end
    -- TODO: use GetAttackTarget() to check if drow is attacking a tower before using trueshot not sure which is better
    local towersNearby = npcBot:GetNearbyTowers(npcBot:GetAttackRange(), true)

    if towersNearby == nil then return false end

    local alliedCreeps = npcBot:GetNearbyCreeps(900, false)

    for i, creeps in ipairs(alliedCreeps) do

        if (utils.IsMelee(creeps)) then
            table.remove(alliedCreeps, 1 )
        end

    end

    if (towersNearby ~= nil and #alliedCreeps > 2) then
        npcBot:Action_UseAbility(trueshot)
        return true
    end

    return false
end

function AbilityUsageThink()
    if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return false end

    local npcBot = GetBot()

    if npcBot:IsChanneling() or npcBot:IsUsingAbility() then return false end

    if UseE() then return true end

    if getHeroVar("Target") == nil then return false end

    if UseW() or UseQ() then return true end
end

for k,v in pairs( ability_usage_drow_ranger ) do _G._savedEnv[k] = v end
