-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

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
end

function X:Think(bot)
    local target = getHeroVar("Target")
    if utils.ValidTarget(target) and target:IsAlive() then
        local dist = GetUnitToUnitDistance(bot, target)
        local attackRange = bot:GetAttackRange() + bot:GetBoundingRadius() + target:GetBoundingRadius()
        
        if utils.IsMelee(bot) then
            if dist < attackRange then
                if target:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                    gHeroVar.HeroMoveToUnit(bot, target)
                else
                    gHeroVar.HeroAttackUnit(bot, target, true)
                end
            else
                if item_usage.UseMovementItems(target:GetLocation()) then return end
                gHeroVar.HeroMoveToUnit(bot, target)
            end
        else
            if dist < attackRange then
                if target:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                    -- move away if we are too close
                    if dist < 0.3*attackRange then
                        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), target:GetLocation(), 0.75*attackRange-dist))
                    elseif dist > 0.75*attackRange then
                        gHeroVar.HeroMoveToLocation(bot, utils.VectorTowards(bot:GetLocation(), target:GetLocation(), 0.75*attackRange-dist))
                    end
                else
                    -- move away if we are too close
                    if dist < 0.3*attackRange then
                        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), target:GetLocation(), 0.75*attackRange-dist))
                    else
                        if utils.UseOrbEffect(bot, target) then return end
                        
                        gHeroVar.HeroAttackUnit(bot, target, true)
                    end
                end
            else
                if item_usage.UseMovementItems(target:GetLocation()) then return end
                gHeroVar.HeroMoveToUnit(bot, target)
            end
        end
    else
        setHeroVar("Target", nil)
        
        utils.HarassEnemy(bot)
    end
end

function X:Desire(bot)
    if bot:GetHealth()/bot:GetMaxHealth() < 0.35 then
        return BOT_MODE_DESIRE_NONE
    end
    
    local enemyList = gHeroVar.GetNearbyEnemies(bot, 1200)
    if #enemyList == 0 then return BOT_MODE_DESIRE_NONE end
    
    local eTowers = gHeroVar.GetNearbyEnemyTowers(bot, 900)
    local aTowers = gHeroVar.GetNearbyAlliedTowers(bot, 600)
    
    local enemyValue = 0
    local allyValue = 0
    for _, enemy in pairs(enemyList) do
        enemyValue = enemyValue + enemy:GetHealth() + enemy:GetOffensivePower()
    end
    enemyValue = enemyValue + #eTowers*110
    
    local allyList = gHeroVar.GetNearbyAllies(bot, 1200)
    for _, ally in pairs(allyList) do
        allyValue = allyValue + ally:GetHealth() + ally:GetOffensivePower()
    end
    allyValue = allyValue + #aTowers*110
    
    if allyValue/enemyValue > Max(1.0, (1.6 - bot:GetLevel()*0.1)) then
        local target, _ = utils.GetWeakestHero(bot, bot:GetAttackRange()+bot:GetBoundingRadius())
        if utils.ValidTarget(target) then
            setHeroVar("Target", target)
            return BOT_MODE_DESIRE_MODERATE
        end
    else
        return BOT_MODE_DESIRE_NONE
    end

    local allyList2 = gHeroVar.GetNearbyAllies(bot, 1600)
    for _, ally in pairs(allyList2) do
        if not ally:IsIllusion() then
            local allyTarget = ally:GetAttackTarget() --gHeroVar.GetVar(ally:GetPlayerID(), "Target")
            if utils.ValidTarget(allyTarget) and allyTarget:IsHero() and
                utils.GetOtherTeam() == GetTeamForPlayer(allyTarget:GetPlayerID()) then
                setHeroVar("Target", allyTarget)
                return BOT_MODE_DESIRE_MODERATE
            end
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X