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
    
    local daggerCastRange = abilityQ:GetCastRange();
    local daggerDamage = 65 + abilityQ:GetSpecialValueInt("attack_factor_tooltip") / 100 * bot:GetAttackDamage();   --Add abilityQ:GetBaseDamage() instead of 65 (patches ruin everything)
    local inRangeEnemyCreeps = gHeroVar.GetNearbyEnemyCreep(bot, daggerCastRange);
    local inRangeEnemyHeroes = gHeroVar.GetNearbyEnemies(bot, daggerCastRange);
    local creepTarget, _ = utils.GetWeakestCreep(inRangeEnemyCreeps);
    local scariestHeroTarget = nil;
    
    if (#inRangeEnemyHeroes > 0) then
        if (#inRangeEnemyHeroes > 1) then
            table.sort(inRangeEnemyHeroes, function(a,b) return a:GetRawOffensivePower() > b:GetRawOffensivePower() end);
        end;
        scariestHeroTarget = inRangeEnemyHeroes[1];
    end;
    
    --Code for lasthitting creeps as my first try
    --Need to check if there is an actual creep with the lowest health
    if (creepTarget ~= nil) then
        local trueDaggerDamage = creepTarget:GetActualIncomingDamage(daggerDamage, DAMAGE_TYPE_PHYSICAL);
        if (creepTarget:GetHealth() <= trueDaggerDamage) then
            bot:Action_UseAbilityOnEntity(abilityQ, creepTarget);
            return true;
        end;    
    end;
    
    --Code for harassing enemy heroes as my second try
    --Need to check if there is an actual hero scary hero within dagger range
    if (scariestHeroTarget ~= nil) then
        if (not utils.IsTargetMagicImmune(scariestHeroTarget)) then   
            bot:Action_UseAbilityOnEntity(abilityQ, scariestHeroTarget);
            return true;
        end;
    end;
    
    return false;
end;

function UseW(bot)
    if not abilitW:IsFullyCastable() then
        return false;
    end;

    local phantomStrikeCastRange = abiltyW:GetCastRange();
    local totalAttackDamage = 4 * bot:GetAttackDamage(); -- phantom_assassin_phantom_strike adds 4 very fast attacks
    local inRangeEnemyCreeps = gHeroVar.GetNearbyEnemyCreep(bot, phantomStrikeCastRange);
    local inRangeEnemyHeroes = gHeroVar.GetNearbyEnemies(bot, phantomStrikeCastRange);
    local creepTarget, _ = utils.GetWeakestCreep(inRangeEnemyCreeps);
    local scariestHeroTarget = nil;
    
    
    if (#inRangeEnemyHeroes > 0) then
        if (#inRangeEnemyHeroes > 1) then
            table.sort(inRangeEnemyHeroes, function(a,b) return a:GetRawOffensivePower() > b:GetRawOffensivePower() end);
        end;
        scariestHeroTarget = inRangeEnemyHeroes[1];
    end;
    
    --phantom_assassin_phantom_strike to kill
    --Need to check if there is an actual hero scary hero within phantom_assassin_phantom_strike range
    if (scariestHeroTarget ~= nil) then
        local trueTotalAttackDamage = GetActualIncomingDamage(totalAttackDamage, DAMAGE_TYPE_PHYSICAL);
        if (scariestHeroTarget:GetHealth < 1.05 * trueTotalAttackDamage) then
            bot:Action_UseAbilityOnEntity(abilityW, scariestHeroTarget);
            return true;
        end;
    end; 
   
   --phantom_assassin_phantom_strike to roshan
   
   --phantom_assassin_phantom_strike to farm
   
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