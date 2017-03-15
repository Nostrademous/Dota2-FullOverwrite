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
    if bot.useShrine and bot.useShrine >= 0 then
        global_game_state.RemovePIDFromShrine(bot.useShrine, bot:GetPlayerID())
    end
    bot.useShrine = -1
    bot.shrineUseMode = nil
end

function X:Think(bot)
    if bot:IsIllusion() then return end
    
    -- below will happen right after we use shrine while waiting for heal
    -- TODO: eventually we shouldn't be in this mode, but rather just know we need
    -- to stay in range of shrine while being healed, but can do other things
    if not bot.useShrine or bot.useShrine == -1 then return end
    
    local hShrine = global_game_state.GetShrineState(bot.useShrine).handle
    
    -- if shrine is dead, clear mode
    if not utils.NotNilOrDead(hShrine) then
        getHeroVar("Self"):ClearMode()
        return
    end
    
    -- if shrine is on cooldown, clear mode 
    -- TODO: will it be on cooldown when we get there, then ok
    if GetShrineCooldown(hShrine) ~= 0 then
        global_game_state.RemovePIDFromShrine(bot.useShrine, bot:GetPlayerID())
        getHeroVar("Self"):ClearMode()
        return
    end

    -- if we somehow healed up to above 0.5 health and are not under shrine effect
    -- then we can cancel our desire to use shrine
    if bot:GetHealth()/bot:GetMaxHealth() > 0.5 and not bot:HasModifier("modifier_filler_heal") then
        utils.myPrint("Don't need to use shrine, canceling")
        global_game_state.RemovePIDFromShrine(bot.useShrine, bot:GetPlayerID())
        getHeroVar("Self"):ClearMode()
        return
    end
    
    if bot:HasModifier("modifier_filler_heal") then
        -- TODO: we shouldn't return here really, we can do all kinds of things,
        -- just need to stay in range of heal radius while we are not full health/mana
        return
    end

    if bot.shrineUseMode then
        if hShrine and GetUnitToUnitDistance(bot, hShrine) > 300 then
            bot:Action_MoveToLocation(hShrine:GetLocation())
            local mvAbility = getHeroVar("HasMovementAbility")
            if mvAbility and mvAbility[1]:IsFullyCastable() then
                local newLoc = utils.VectorTowards(bot:GetLocation(), hShrine:GetLocation(), mvAbility[2])
                bot:ActionPush_UseAbilityOnLocation(mvAbility[1], newLoc)
            end
            return
        elseif bot.shrineUseMode ~= constants.SHRINE_USE then
            utils.myPrint("Waiting on more friends: ", #global_game_state.GetShrineState(bot.useShrine).pidsLookingForHeal)
            for _, id in pairs(global_game_state.GetShrineState(bot.useShrine).pidsLookingForHeal) do
                utils.myPrint("\tID: ", id)
            end
            return
        elseif bot.shrineUseMode == constants.SHRINE_USE then
            utils.myPrint("using Shrine")
            bot:ActionPush_UseShrine(hShrine)
            bot.shrineUseMode = nil
            local savedShrineID = bot.useShrine
            for _, id in pairs(global_game_state.GetShrineState(bot.useShrine).pidsLookingForHeal) do
                for _, ally in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
                    if ally:IsBot() and not ally:IsIllusion() and ally:GetPlayerID() == id then
                        ally.useShrine = -1
                    end
                end
            end
            global_game_state.GetShrineState(savedShrineID).pidsLookingForHeal = {}
            return
        else
            utils.pause("Shrine Exception!")
        end
    end

    getHeroVar("Self"):ClearMode()
    return
end

function X:Desire(bot)
    if bot.useShrine and bot.useShrine >= 0 then
        if not utils.NotNilOrDead(global_game_state.GetShrineState(bot.useShrine).handle) then
            return BOT_MODE_DESIRE_NONE
        end
    
        local nearbyAllies = gHeroVar.GetNearbyAllies(bot, 400)
        local numAllies = 0
        for _, ally in pairs(nearbyAllies) do
            if utils.InTable(global_game_state.GetShrineState(bot.useShrine).pidsLookingForHeal, ally:GetPlayerID()) then
                if GetUnitToUnitDistance(ally, global_game_state.GetShrineState(bot.useShrine).handle) < 400 then
                    numAllies = numAllies + 1
                end
            end
        end

        if numAllies == #global_game_state.GetShrineState(bot.useShrine).pidsLookingForHeal then
            bot.shrineUseMode = constants.SHRINE_USE
            return BOT_MODE_DESIRE_ABSOLUTE
        else
            --utils.myPrint("NumAllies: ", numAllies, ", #useShrine.allies: ", #bot.useShrine.allies)
            bot.shrineUseMode = constants.SHRINE_WAITING
            return BOT_MODE_DESIRE_VERYHIGH
        end
    end
    
    if bot:HasModifier("modifier_filler_heal") and 
        (bot:GetHealth() ~= bot:GetMaxHealth() or bot:GetMana() ~= bot:GetMaxMan()) then
        -- TODO: we shouldn't return here really, we can do all kinds of things,
        -- just need to stay in range of heal radius while we are not full health/mana
        return BOT_MODE_DESIRE_VERYHIGH
    end
    
    return BOT_MODE_DESIRE_NONE
end

return X