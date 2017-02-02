-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
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

local function UseQ()
    local npcBot = GetBot()

    local frostArrow = npcBot:GetAbilityByName(Abilities[1])

    if (frostArrow == nil) or (not frostArrow:IsFullyCastable()) then
        return false
    end

    local Enemies = npcBot:GetNearbyHeroes(frostArrow:GetCastRange(), true, BOT_MODE_NONE)
    local target = getHeroVar("Target")
    
    if #Enemies == 0 or not utils.ValidTarget(target) then return false end

    if GetUnitToUnitDistance(npcBot, target.Obj) < frostArrow:GetCastRange() and (not target.Obj:IsRooted()) or (not target.Obj:IsStunned()) and (not target.Obj:IsMagicImmune()) then
        npcBot:Action_UseAbilityOnEntity(frostArrow, target.Obj)
        return true
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

    local wave_speed = gust:GetSpecialValueFloat("wave_speed")
    local delay = gust:GetCastPoint() + GetUnitToUnitDistance(npcBot, Enemies[1])/wave_speed

    if #Enemies == 1 then
        local enemyHasStun = Enemies[1]:GetStunDuration(true) > 0
        if (not Enemies[1]:IsSilenced()) or (not Enemies[1]:IsRooted()) or (not Enemies[1]:IsStunned()) and (not Enemies[1]:IsMagicImmune())
        or Enemies[1]:IsChanneling() and (GetUnitToUnitDistance(npcBot, Enemies[1]) < 350 or enemyHasStun) then
            utils.TreadCycle(npcBot, constants.INTELLIGENCE)
            npcBot:Action_UseAbilityOnLocation(gust, Enemies[1]:GetExtrapolatedLocation(delay))
            utils.TreadCycle(npcBot, constants.AGILITY)
            return true
        end
    else
        for _, enemy in pairs( Enemies ) do
            if enemy:IsChanneling() then
                if gust:GetCastRange() > GetUnitToUnitDistance(npcBot, enemy) and (not enemy:IsMagicImmune()) then
                    local gustDelay = gust:GetCastPoint() + GetUnitToUnitDistance(npcBot, enemy)/wave_speed
                    utils.TreadCycle(npcBot, constants.INTELLIGENCE)
                    npcBot:Action_UseAbilityOnLocation(gust, enemy:GetExtrapolatedLocation(gustDelay))
                    utils.TreadCycle(npcBot, constants.AGILITY)
                    return true
                end
            end
        end

        --Use Gust as a Defensive skill to fend off chasing enemies
        if getHeroVar("IsRetreating") and (npcBot:GetHealth()/npcBot:GetMaxHealth()) < 0.5 then
            for _, enemy in pairs( Enemies ) do
                if utils.IsHeroAttackingMe(enemy, 2.0) then
                    if gust:GetCastRange() > GetUnitToUnitDistance(npcBot, enemy) and (not enemy:IsMagicImmune()) then
                        local gustDelay = gust:GetCastPoint() + GetUnitToUnitDistance(npcBot, enemy)/wave_speed
                        utils.TreadCycle(npcBot, constants.INTELLIGENCE)
                        npcBot:Action_UseAbilityOnLocation(gust, enemy:GetExtrapolatedLocation(gustDelay))
                        utils.TreadCycle(npcBot, constants.AGILITY)
                        return true
                    end
                end
            end
        end

        local center = utils.GetCenter(Enemies)
        if center ~= nil then
            utils.TreadCycle(npcBot, constants.INTELLIGENCE)
            npcBot:Action_UseAbilityOnLocation(gust, center)
            utils.TreadCycle(npcBot, constants.AGILITY)
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

    if (towersNearby ~= nil and #alliedCreeps > 3) then
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

    if UseW() or UseQ() then return true end
end

for k,v in pairs( ability_usage_drow_ranger ) do _G._savedEnv[k] = v end
