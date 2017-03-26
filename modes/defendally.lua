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
    return "defendally"
end

function X:OnStart(myBot)
end

function X:OnEnd()
    local bot = GetBot()
    bot.defendAllyTarget = nil
end

function X:Think(bot)
    if utils.ValidTarget(bot.defendAllyTarget) then
        gHeroVar.HeroAttackUnit(bot, bot.defendAllyTarget, true)
    else
        bot.defendAllyTarget = nil
    end
end

local function GetDefendeesTarget(bot)
    local nearAllies = gHeroVar.GetNearbyAllies(bot, 1600)

    local alliesNeedingHelp = {}
    for _, ally in pairs(nearAllies) do
        if not ally:IsIllusion() and (ally.SelfRef:getCurrentMode():GetName() == "retreat"
            or ally.SelfRef:getCurrentMode():GetName() == "shrine") then
            table.insert(alliesNeedingHelp, ally)
        end
    end

    local enemies = GetUnitList(UNIT_LIST_ENEMY_HEROES)

    local candidateEnemy = nil
    local candidateEnemyScore = 0

    if #alliesNeedingHelp > 0 then
        for _, enemy in pairs(enemies) do
            if utils.ValidTarget(enemy) then
                local numAlliesDamaged = 0
                for _, ally in pairs(alliesNeedingHelp) do
                    if ally:WasRecentlyDamagedByHero(enemy, 3.0) then
                        numAlliesDamaged = numAlliesDamaged + 1
                    end
                end

                if numAlliesDamaged > 0 then
                    local dmg = bot:GetEstimatedDamageToTarget(true, enemy, 4.5, DAMAGE_TYPE_ALL)
                    if candidateEnemyScore < dmg/enemy:GetHealth() then
                        candidateEnemyScore = dmg/enemy:GetHealth()
                        candidateEnemy = enemy
                    end
                end
            end
        end
    end

    return candidateEnemy
end

function X:Desire(bot)
    if bot:GetHealth()/bot:GetMaxHealth() < 0.45 then
        return BOT_MODE_DESIRE_NONE
    end

    bot.defendAllyTarget = GetDefendeesTarget(bot)
    if utils.ValidTarget(bot.defendAllyTarget) then
        return BOT_MODE_DESIRE_MODERATE
    end

    return BOT_MODE_DESIRE_NONE
end

return X