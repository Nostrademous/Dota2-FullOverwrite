-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local genericAbility = BotsInit.CreateGeneric()

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

function UseQ(bot)
    if not abilityQ:IsFullyCastable() then
        return false;
    end;
    
    --Code for lasthitting creeps as my first try
    local daggerRange = abilityQ:GetCastRange();
    local daggerDamage = 65 + abilityQ:GetSpecialValueInt("attack_factor_tooltip") / 100 * bot:GetAttackDamage();
    local inRangeEnemyCreeps = gHeroVar.GetNearbyEnemyCreep(bot, daggerRange);
    
    local daggerTarget, _ = utils.GetWeakestCreep(inRangeEnemyCreeps);
    --Need to check if there is an actual creep with the lowest health
    if (daggerTarget ~= nil) then
        local trueDaggerDamage = daggerTarget:GetActualIncomingDamage( daggerDamage, DAMAGE_TYPE_PHYSICAL);
        if (daggerTarget:GetHealth() <= trueDaggerDamage) then
            bot:Action_UseAbilityOnEntity(abilityQ, daggerTarget);
            return true;
        end;
        
    end;
    return false;
end;

function genericAbility:AbilityUsageThink(bot)
    -- Check if we're already using an ability
    if utils.IsBusy(bot) then return true end
    
    -- Check to see if we are CC'ed
    if utils.IsCrowdControlled(bot) then return false end

    if abilityQ == "" then abilityQ = bot:GetAbilityByName( "phantom_assassin_stifling_dagger" ) end
    if abilityW == "" then abilityW = bot:GetAbilityByName( "phantom_assassin_phantom_strike" ) end
    if abilityE == "" then abilityE = bot:GetAbilityByName( "phantom_assassin_blur" ) end
    if abilityR == "" then abilityR = bot:GetAbilityByName( "phantom_assassin_coup_de_grace" ) end
    
    -- WRITE CODE HERE --
    if UseQ(bot) then return true end
    
    return false
end

function genericAbility:nukeDamage( bot, enemy )
    if enemy == nil or enemy:IsNull() then return 0, {}, 0, 0, 0 end

    local comboQueue = {}
    local manaAvailable = bot:GetMana()
    local dmgTotal = 0
    local castTime = 0
    local stunTime = 0
    local slowTime = 0
    local engageDist = 10000
    
    -- WRITE CODE HERE --
    
    return dmgTotal, comboQueue, castTime, stunTime, slowTime, engageDist
end

function genericAbility:queueNuke(bot, enemy, castQueue, engageDist)
    -- WRITE CODE HERE --
    
    return false
end

return genericAbility