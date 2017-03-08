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
        --[[
        local score = getHeroVar("TargetScore")
        for _, ally in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
            if ally:GetPlayerID() ~= bot:GetPlayerID() then
                local allyTarget = gHeroVar.GetVar(ally:GetPlayerID(), "Target")
                if allyTarget and allyTarget == target and GetUnitToUnitDistance(ally, target) < 1200 and
                    ally:GetHealth()/ally:GetMaxHealth() > 0.30 then
                    score = score + gHeroVar.GetVar(ally:GetPlayerID(), "TargetScore")
                end
            end
        end
        --]]
        
        gHeroVar.HeroAttackUnit(bot, target, true)
    else
        setHeroVar("Target", nil)
    end
end

function X:Desire(bot)
    if bot:GetHealth()/bot:GetMaxHealth() < 0.35 then
        return BOT_MODE_DESIRE_NONE
    end
    
    local enemyList = getHeroVar("NearbyEnemies")
    if #enemyList == 0 then return BOT_MODE_DESIRE_NONE end
    
    local enemyValue = 0
    local allyValue = 0
    for _, enemy in pairs(enemyList) do
        enemyValue = enemyValue + enemy:GetHealth() + enemy:GetOffensivePower()
    end
    
    for _, ally in pairs(getHeroVar("NearbyAllies")) do
        allyValue = allyValue + ally:GetHealth() + ally:GetOffensivePower()
    end
    
    if allyValue > enemyValue then
        local target, _ = utils.GetWeakestHero(bot, bot:GetAttackRange()+bot:GetBoundingRadius(), enemyList)
        if target then
            setHeroVar("Target", target)
            return BOT_MODE_DESIRE_MODERATE
        end
    end
    
    if getHeroVar("Target") or getHeroVar("Self"):getCurrentMode():GetName() == "fight" then
        return getHeroVar("Self"):getCurrentModeValue()
    end

    return BOT_MODE_DESIRE_NONE
end

return X