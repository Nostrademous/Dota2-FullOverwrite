-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

require( GetScriptDirectory().."/modifiers" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "fight"
end

function X:OnStart(myBot)
    local bot = GetBot()
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        utils.PartyChat("Trying to kill "..utils.GetHeroName(target), false)
    end
end

function X:OnEnd()
    setHeroVar("Target", nil)
    setHeroVar("RoamTarget", nil)
end

function X:Think(bot)
    if utils.IsBusy(bot) then return end
    
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) then
        local dist = GetUnitToUnitDistance(bot, target)
        local attackRange = bot:GetAttackRange() + bot:GetBoundingRadius() + target:GetBoundingRadius()
        
        if utils.IsMelee(bot) then
            if dist < attackRange then
                if target:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                    gHeroVar.HeroMoveToUnit(bot, target)
                    return
                else
                    gHeroVar.HeroAttackUnit(bot, target, true)
                    return
                end
            else
                if item_usage.UseMovementItems(target:GetLocation()) then return end
                gHeroVar.HeroMoveToUnit(bot, target)
                return
            end
        else
            if dist < attackRange then
                if target:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                    -- move away if we are too close
                    if dist < 0.3*attackRange then
                        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), target:GetLocation(), 0.75*attackRange-dist))
                        return
                    elseif dist > 0.75*attackRange then
                        gHeroVar.HeroMoveToLocation(bot, utils.VectorTowards(bot:GetLocation(), target:GetLocation(), 0.75*attackRange-dist))
                        return
                    end
                else
                    -- move away if we are too close
                    if dist < 0.3*attackRange then
                        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), target:GetLocation(), 0.75*attackRange-dist))
                        return
                    else
                        gHeroVar.HeroAttackUnit(bot, target, true)
                        return
                    end
                end
            else
                if item_usage.UseMovementItems(target:GetLocation()) then return end
                gHeroVar.HeroMoveToUnit(bot, target)
                return
            end
        end
    else
        setHeroVar("Target", nil)
    end
end

function X:Desire(bot)
    if bot:GetHealth()/bot:GetMaxHealth() < 0.35 then
        return BOT_MODE_DESIRE_NONE
    end
    
    local enemyList = gHeroVar.GetNearbyEnemies(bot, 1600)
    if #enemyList == 0 then return BOT_MODE_DESIRE_NONE end
    
    local eTowers = gHeroVar.GetNearbyEnemyTowers(bot, 900)
    local aTowers = gHeroVar.GetNearbyAlliedTowers(bot, 600)
    
    local enemyValue = 0
    for _, enemy in pairs(enemyList) do
        if enemy:GetHealth()/enemy:GetMaxHealth() >= 0.25 and not modifiers.HasDangerousModifiers(enemy) and 
            not utils.IsCrowdControlled(enemy) then
            --utils.myPrint(utils.GetHeroName(enemy), ", OP: ", enemy:GetRawOffensivePower())
            enemyValue = enemyValue + enemy:GetHealth() + enemy:GetRawOffensivePower()
        end
    end
    enemyValue = enemyValue + #eTowers*110
    
    local allyValue = 0
    local allyList = gHeroVar.GetNearbyAllies(bot, 1200)
    for _, ally in pairs(allyList) do
        if not ally:IsIllusion() and ally:GetHealth()/ally:GetMaxHealth() >= 0.25 and not modifiers.HasDangerousModifiers(ally) and 
            not utils.IsCrowdControlled(ally) then
            --utils.myPrint(ally.Name, ", OP: ", ally:GetOffensivePower())
            allyValue = allyValue + ally:GetHealth() + ally:GetOffensivePower()
        end
    end
    allyValue = allyValue + #aTowers*110
    
    --if enemyValue == 0 then utils.myPrint("allyV/enemyV: ", allyValue/enemyValue) end
    
    if allyValue/enemyValue > Max(1.0, (1.6 - bot:GetLevel()*0.1)) then
        local target, _ = utils.GetWeakestHero(bot, 1600)
        if utils.ValidTarget(target) then
            setHeroVar("Target", target)
            return BOT_MODE_DESIRE_MODERATE
        end
    end

    return BOT_MODE_DESIRE_NONE
end

return X