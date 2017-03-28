-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local utils = require( GetScriptDirectory().."/utility")

require( GetScriptDirectory().."/global_game_state" )

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

function X:GetName()
    return "shrine"
end

function X:OnStart(myBot)
end

function X:OnEnd()
    local bot = GetBot()
    bot.useShrine = nil
end

function X:Think(bot)
    if bot:IsIllusion() then return end
    
    -- if shrine is dead, clear mode
    if not utils.ValidTarget(bot.useShrine) then
        bot.SelfRef:ClearMode()
        return
    end

    if GetUnitToUnitDistance(bot, bot.useShrine) > 300 then
        local loc = bot.useShrine:GetLocation()
        
        local nearbyEnemies = gHeroVar.GetNearbyEnemies(bot, 1600)
        local nearbyETowers = gHeroVar.GetNearbyEnemyTowers(bot, 1600)
        if #nearbyEnemies > 0 or #nearbyETowers > 0 then
            local listDangerHandles = { unpack(nearbyEnemies), unpack(nearbyETowers) }
            loc = utils.DirectionAwayFromDanger(listDangerHandles, loc)
        end
    
        if not modifiers.IsInvisible(bot) then
            if item_usage.UseMovementItems(loc) then return end
            if item_usage.UseGlimmerCape(bot) then return end
        end
        
        gHeroVar.HeroMoveToLocation(bot, loc)
        return
    else
        --utils.myPrint("using Shrine")
        bot:ActionPush_UseShrine(bot.useShrine)
        bot.useShrine = nil
        return
    end
end

function X:Desire(bot)
    
    if not bot:IsIllusion() and bot:GetHealth()/bot:GetMaxHealth() < 0.3 and 
        bot.useShrine == nil then
        local bestShrine = nil
        local distToShrine = 100000
        local Team = GetTeam()
    
        -- determine closest usable shrine
        local SJ1 = GetShrine(Team, SHRINE_JUNGLE_1)
        if SJ1 and SJ1:GetHealth() > 0 and GetShrineCooldown(SJ1) == 0 then
            local dist = GetUnitToUnitDistance(bot, SJ1)
            if dist < distToShrine then
                distToShrine = dist
                bestShrine = SJ1
            end
        end
        local SJ2 = GetShrine(Team, SHRINE_JUNGLE_2)
        if SJ2 and SJ2:GetHealth() > 0 and GetShrineCooldown(SJ2) == 0 then
            local dist = GetUnitToUnitDistance(bot, SJ2)
            if dist < distToShrine then
                distToShrine = dist
                bestShrine = SJ2
            end
        end
        local SB1 = GetShrine(Team, SHRINE_BASE_1)
        if SB1 and SB1:GetHealth() > 0 and GetShrineCooldown(SB1) == 0 then
            local dist = GetUnitToUnitDistance(bot, SB1)
            if dist < distToShrine then
                distToShrine = dist
                bestShrine = SB1
            end
        end
        local SB2 = GetShrine(Team, SHRINE_BASE_2)
        if SB2 and SB2:GetHealth() > 0 and GetShrineCooldown(SB2) == 0 then
            local dist = GetUnitToUnitDistance(bot, SB2)
            if dist < distToShrine then
                distToShrine = dist
                bestShrine = SB2
            end
        end
        local SB3 = GetShrine(Team, SHRINE_BASE_3)
        if SB3 and SB3:GetHealth() > 0 and GetShrineCooldown(SB3) == 0 then
            local dist = GetUnitToUnitDistance(bot, SB3)
            if dist < distToShrine then
                distToShrine = dist
                bestShrine = SB3
            end
        end
        local SB4 = GetShrine(Team, SHRINE_BASE_4)
        if SB4 and SB4:GetHealth() > 0 and GetShrineCooldown(SB4) == 0 then
            local dist = GetUnitToUnitDistance(bot, SB4)
            if dist < distToShrine then
                distToShrine = dist
                bestShrine = SB4
            end
        end
        local SB5 = GetShrine(Team, SHRINE_BASE_5)
        if SB5 and SB5:GetHealth() > 0 and GetShrineCooldown(SB5) == 0 then
            local dist = GetUnitToUnitDistance(bot, SB5)
            if dist < distToShrine then
                distToShrine = dist
                bestShrine = SB5
            end
        end
        
        if utils.ValidTarget(bestShrine) then
            if distToShrine < (bot:DistanceFromFountain() + 3500) then
                bot.useShrine = bestShrine
                return BOT_MODE_DESIRE_VERYHIGH
            end
        end
    end
    
    if bot.useShrine then
        -- if shrine is on cooldown, clear mode 
        -- TODO: will it be on cooldown when we get there, then ok
        if GetShrineCooldown(bot.useShrine) ~= 0 then
            return BOT_MODE_DESIRE_NONE
        end

        -- if we somehow healed up to above 0.5 health and are not under shrine effect
        -- then we can cancel our desire to use shrine
        if bot:GetHealth()/bot:GetMaxHealth() > 0.5 and not bot:HasModifier("modifier_filler_heal") then
            return BOT_MODE_DESIRE_NONE
        end
        
        if bot.SelfRef:getCurrentMode():GetName() == "shrine" then
            return bot.SelfRef:getCurrentModeValue()
        end
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X