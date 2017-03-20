-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local think = require( GetScriptDirectory().."/think" )

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/role" )
require( GetScriptDirectory().."/laning_generic" )
require( GetScriptDirectory().."/jungling_generic" )
require( GetScriptDirectory().."/retreat_generic" )
require( GetScriptDirectory().."/ganking_generic" )
require( GetScriptDirectory().."/item_usage" )
require( GetScriptDirectory().."/jungle_status" )
require( GetScriptDirectory().."/buildings_status" )
require( GetScriptDirectory().."/fighting" )
require( GetScriptDirectory().."/global_game_state" )
require( GetScriptDirectory().."/debugging" )

local utils = require( GetScriptDirectory().."/utility" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )
local enemyData = require( GetScriptDirectory().."/enemy_data" )


-------------------------------------------------------------------------------
-- MAIN THINK FUNCTION - DO NOT OVER-LOAD
-------------------------------------------------------------------------------
local NoTarget = { Obj = nil, Id = 0 }

function X:ReAquireTargets(nearbyEnemyHeroes)
    local setTarget = self:getHeroVar("Target")
    if setTarget.Id > 0 and (not utils.ValidTarget(setTarget) or not setTarget.Obj:IsAlive()) then
        for id, v in pairs(nearbyEnemyHeroes) do
            if setTarget.Id == v:GetPlayerID() then
                if IsHeroAlive(setTarget.Id) then
                    utils.myPrint("Updated my Target after re-aquire")
                    self:setHeroVar("Target", {Obj=v, Id=setTarget.Id})
                else
                    utils.myPrint("Target is dead, clearing")
                    self:setHeroVar("Target", NoTarget)
                end
                enemyData[setTarget.Id].Time1 = -100.0
                enemyData[setTarget.Id].Time2 = -100.0
            end
        end
    end

    local gankTarget = self:getHeroVar("GankTarget")
    if gankTarget.Id > 0 and (not utils.ValidTarget(gankTarget) or not gankTarget.Obj:IsAlive()) then
        for id, v in pairs(nearbyEnemyHeroes) do
            if gankTarget.Id == v:GetPlayerID() then
                if IsHeroAlive(gankTarget.Id) then
                    utils.myPrint("Updated my GankTarget after re-aquire")
                    self:setHeroVar("GankTarget", {Obj=v, Id=gankTarget.Id})
                else
                    utils.myPrint("GankTarget is dead, clearing")
                    self:setHeroVar("GankTarget", NoTarget)
                end
            end
            enemyData[gankTarget.Id].Time1 = -100.0
            enemyData[gankTarget.Id].Time2 = -100.0
        end
    end
end

-- LOCAL VARIABLES THAT WE WILL NEED FOR THIS FRAME
local updateFrequency    = 0.03

local EyeRange           = 1200
local nearbyEnemyHeroes  = {}
local nearbyAlliedHeroes = {}
local nearbyEnemyCreep   = {}
local nearbyAlliedCreep  = {}
local nearbyEnemyTowers  = {}
local nearbyAlliedTowers = {}

function X:Think(bot)
    if GetGameState() == GAME_STATE_PRE_GAME and not self.Init then
        self:DoInit(bot)
        return
    elseif GetGameState() == GAME_STATE_PRE_GAME and DotaTime() < -85.0 then
        return
    end

    if GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME then return end

    -- handle any illusions
    if self:DoHandleIllusions(bot) then return end

    -- level up abilities if time
    local checkLevel, newTime = utils.TimePassed(self:getHeroVar("LastLevelUpThink"), 2.0)
    if checkLevel then
        self:setHeroVar("LastLevelUpThink", newTime)
        if bot:GetAbilityPoints() > 0 then
            utils.LevelUp(bot, self:getAbilityPriority())
        end
    end

    -- check if jungle respawn timer was hit to repopulate our table
    jungle_status.checkSpawnTimer()

    -- update our building information
    buildings_status.Update()

    -- do high level thinking (rate limited)
    -- TODO: not sure where to put this
    global_game_state.EvaluateGameState()

    -- draw debug stuff (actual drawing is done on the first call in a frame)
    debugging.draw()

    -- check if I am alive, if not, short-circuit most stuff
    if not bot:IsAlive() then
        local bRet = self:DoWhileDead(bot)
        if bRet then return end
    end

    -- use courier if needed (TO BE REPLACED BY TEAM LEVEL COURIER CONTROLS)
    utils.CourierThink(bot)

    -- update our global enemy info cache
    enemyData.UpdateEnemyInfo()

    -- grab our bot's surrounding info
    nearbyEnemyHeroes   = bot:GetNearbyHeroes(EyeRange, true, BOT_MODE_NONE)
    nearbyAlliedHeroes  = bot:GetNearbyHeroes(EyeRange, false, BOT_MODE_NONE)
    nearbyEnemyCreep    = bot:GetNearbyCreeps(EyeRange, true)
    nearbyAlliedCreep   = bot:GetNearbyCreeps(EyeRange, false)
    nearbyEnemyTowers   = bot:GetNearbyTowers(EyeRange, true)
    nearbyAlliedTowers  = bot:GetNearbyTowers(EyeRange, false)

    -- clear our target info if they are dead
    local target = self:getHeroVar("Target")
    if target.Id > 0 and not IsHeroAlive(target.Id) then
        utils.myPrint("Clearing Target: ", target.Id)
        self:setHeroVar("Target", NoTarget)
        self:RemoveMode(constants.MODE_FIGHT)
        enemyData.PurgeEnemy(target.Id)
        bot:Action_ClearActions(true)
        return
    end
    local target = self:getHeroVar("GankTarget")
    if target.Id > 0 and not IsHeroAlive(target.Id) then
        utils.myPrint("Clearing Target: ", target.Id)
        self:setHeroVar("GankTarget", NoTarget)
        self:RemoveMode(constants.MODE_GANKING)
        enemyData.PurgeEnemy(target.Id)
        bot:Action_ClearActions(true)
        return
    end

    -- require targets if we have lost them or we killed illusions
    self:ReAquireTargets(nearbyEnemyHeroes)

    -- do out Thinking and set our Mode
    local highestDesiredMode, highestDesiredValue = think.MainThink(nearbyEnemyHeroes, nearbyAlliedHeroes, 
                                                                    nearbyEnemyCreep, nearbyAlliedCreep, 
                                                                    nearbyEnemyTowers, nearbyAlliedTowers)
    if highestDesiredValue >= self:getCurrentModeValue() then
        self:AddMode(highestDesiredMode, highestDesiredValue)
    end
    self:PrintModeTransition(utils.GetHeroName(bot))

    if self:getCurrentMode() == constants.MODE_EVADE then
        if self:DoEvade(bot) then return end
    end

    -- check if I am channeling an ability/item (i.e. TP Scroll, Ultimate, etc.)
    -- and don't interrupt if true
    if bot:IsChanneling() then
        --utils.myPrint("Channeling")
        local bRet = self:DoWhileChanneling(bot)
        if bRet then return end
    end

    -- if we are using an ability/item, return to let it complete
    if bot:IsCastingAbility() then
        --utils.myPrint("Casting Ability")
        local target = self:getHeroVar("Target")
        if target.Id == 0 then return end

        if not utils.ValidTarget(target) then return end

        if GetUnitToUnitDistance(bot, target.Obj) < 2000 then return end
    end

    -- if we have queued actions, do them as anything below this can clear them
    -- but only if we are not retreating... or we might die
    if bot:NumQueuedActions() > 0 then
        --utils.myPrint("has "..bot:NumQueuedActions().." queued actions")
        --utils.myPrint("current action is: ", bot:GetCurrentActionType())
        --utils.myPrint("top queued action is: ", bot:GetQueuedActionType(0))
        if not self:getHeroVar("IsRetreating") then
            return
        end
    end

    ---------------------------------------------------------------------
    -- we are not channeling, using an ability, or have actions queued --
    ---------------------------------------------------------------------

    -- consider using an item
    if self:ConsiderItemUse() then
        --utils.myPrint("using item")
        return
    end

    -- consider casting any of our abilities
    if not (bot:IsSilenced() or bot:IsHexed()) then
        if self:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, 
                                   nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers) then
            return
        end
    end

    if self:getCurrentMode() == constants.MODE_FIGHT then
        if self:DoFight(bot) then return end
    end

    if self:getCurrentMode() == constants.MODE_SPECIALSHOP then
        return
    elseif self:getCurrentMode() == constants.MODE_DEFENDLANE then
        return self:DoDefendLane(bot)
    elseif self:getCurrentMode() == constants.MODE_GANKING then
        return self:DoGank(bot)
    elseif self:getCurrentMode() == constants.MODE_PUSHLANE then
        return self:DoPushLane(bot)
    elseif self:getCurrentMode() == constants.MODE_SHRINE then
        return self:DoUseShrine(bot)
    elseif self:getCurrentMode() == constants.MODE_RETREAT then
        --utils.myPrint("DoRetreat reason: ", self:getHeroVar("RetreatReason"))
        return self:DoRetreat(bot, self:getHeroVar("RetreatReason"))
    elseif self:getCurrentMode() == constants.MODE_RUNEPICKUP then
        return self:DoGetRune(bot)
    elseif self:getCurrentMode() == constants.MODE_WARD then
        return self:DoWard(bot)
    elseif self:getCurrentMode() == constants.MODE_JUNGLING then
        return self:DoJungle(bot)
    elseif self:getCurrentMode() == constants.MODE_LANING then
        return self:DoLane(bot)
    end
end

-------------------------------------------------------------------------------
-- FUNCTION DEFINITIONS - OVER-LOAD THESE IN HERO LUA IF YOU DESIRE
-------------------------------------------------------------------------------

function X:DoWhileDead(bot)
    --utils.myPrint("I am dead")

    if self:getCurrentMode() == constants.MODE_SHRINE then
        think.UpdatePlayerAssignment(bot, "UseShrine", nil)
    end

    self:setCurrentMode(constants.MODE_NONE, BOT_MODE_DESIRE_NONE)

    -- reset are various variables to default values
    self:setHeroVar("BackTimer", nil)
    self:setHeroVar("RuneTarget", nil)
    self:setHeroVar("RuneLoc", nil)
    self:setHeroVar("IsRetreating", false)
    self:setHeroVar("Target", NoTarget)
    self:setHeroVar("GankTarget", NoTarget)
    self:setHeroVar("UsingShrine", false)
    self:setHeroVar("ShrineMode", nil)
    self:setHeroVar("Shrine", nil)
    self:setHeroVar("ShouldPush", false)
    self:setHeroVar("DoDefendLane", {})

    self:MoveItemsFromStashToInventory(bot)
    local bb = self:ConsiderBuyback(bot)
    if (bb) then
        bot:ActionImmediate_Buyback()
    end
    return true
end

function X:DoWhileChanneling(bot)
    item_usage.UseGlimmerCape(bot)
    return true
end

function X:ConsiderBuyback(bot)
    -- FIXME: Write Buyback logic here
    -- GetBuybackCooldown(), GetBuybackCost()
    if ( bot:HasBuyback() ) then
        return false -- FIXME: for now always return false
    end
    return false
end

-- Pure Abstract Function - Designed for Overload
function X:ConsiderAbilityUse(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
    return false
end
-------------------------------------------------

function X:ConsiderItemUse()
    if item_usage.UseItems() then return true end
end


function X:Determine_ShouldIFight(bot)
    global_game_state.GlobalFightDetermination()
    if self:getHeroVar("Target").Id > 0 then
        return true
    end
    return false
end

function X:Determine_ShouldIDefendLane(bot)
    return global_game_state.DetectEnemyPush()
end



function X:DoRetreat(bot, reason)
    if reason == constants.RETREAT_FOUNTAIN then
        if getHeroVar("RetreatLane") == nil then
            utils.myPrint("DoRetreat - STARTING TO RETREAT TO FOUNTAIN")
        end

        self:setHeroVar("IsRetreating", true)

        -- if we healed up enough, change our reason for retreating
        if bot:DistanceFromFountain() >= 5000 and (bot:GetHealth()/bot:GetMaxHealth()) > 0.6 and (bot:GetMana()/bot:GetMaxMana()) > 0.6 then
            utils.myPrint("DoRetreat - Upgrading from RETREAT_FOUNTAIN to RETREAT_DANGER")
            self:setHeroVar("RetreatReason", constants.RETREAT_DANGER)
            return true
        end

        if bot:DistanceFromFountain() > 0 or (bot:GetHealth()/bot:GetMaxHealth()) < 1.0 or (bot:GetMana()/bot:GetMaxMana()) < 1.0 then
            retreat_generic.Think(bot, utils.Fountain(GetTeam()))
            return true
        end
        --utils.myPrint("DoRetreat - RETREAT FOUNTAIN End".." - DfF: ".. bot:DistanceFromFountain()..", H: "..bot:GetHealth())
    elseif reason == constants.RETREAT_DANGER then
        if getHeroVar("RetreatLane") == nil then
            utils.myPrint("STARTING TO RETREAT b/c OF DANGER")
        end

        self:setHeroVar("IsRetreating", true)

        local enemyTooClose = false
        for _, enemy in pairs(nearbyEnemyHeroes) do
            if GetUnitToUnitDistance(bot, enemy) < Max(650, enemy:GetAttackRange()) then
                enemyTooClose = true
                break
            end
        end

        if bot:TimeSinceDamagedByAnyHero() < 3.0 or enemyTooClose then
            if bot:DistanceFromFountain() < 5000 and (bot:GetHealth()/bot:GetMaxHealth()) < 1.0 then
                retreat_generic.Think(bot)
                return true
            elseif bot:DistanceFromFountain() >= 5000 and (bot:GetHealth()/bot:GetMaxHealth()) < 0.6 then
                retreat_generic.Think(bot)
                return true
            elseif (bot:GetHealth()/bot:GetMaxHealth()) < 0.75 then
                retreat_generic.Think(bot)
                return true
            end
        end
        --utils.myPrint("DoRetreat - RETREAT DANGER End".." - DfF: "..bot:DistanceFromFountain()..", H: "..bot:GetHealth())
    elseif reason == constants.RETREAT_TOWER then
        --utils.myPrint("STARTING TO RETREAT b/c of tower damage")

        local mypos = bot:GetLocation()
        if utils.IsTowerAttackingMe() then
            local rLoc = mypos

            --set the target to go back
            local bInLane, cLane = utils.IsInLane()
            if bInLane then
                local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), cLane, false) - 0.05
                rLoc = GetLocationAlongLane(cLane, enemyFrontier)
            else
                rLoc = utils.VectorTowards(mypos, utils.Fountain(GetTeam()), 300)
            end

            gHeroVar.HeroMoveToLocation(bot, rLoc)
            --utils.myPrint("TowerRetreat: ", d)
            return true
        end
        --utils.myPrint("DoRetreat - RETREAT TOWER End")
    elseif reason == constants.RETREAT_CREEP then
        --utils.myPrint("STARTING TO RETREAT b/c of creep damage")

        local mypos = bot:GetLocation()
        if utils.IsCreepAttackingMe(1.0) then
            local rLoc = mypos

            --set the target to go back
            local bInLane, cLane = utils.IsInLane()
            if bInLane then
                --utils.myPrint("Creep Retreat - InLane: ", cLane)
                local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), cLane, false) - 0.05
                rLoc = GetLocationAlongLane(cLane, enemyFrontier)
            else
                --utils.myPrint("Creep Retreat - Not InLane")
                rLoc = utils.VectorTowards(mypos, utils.Fountain(GetTeam()), 300)
            end

            gHeroVar.HeroMoveToLocation(bot, rLoc)

            return true
        end
        --utils.myPrint("DoRetreat - RETREAT CREEP End")
    end

    -- If we got here, we are done retreating
    --utils.myPrint("done retreating from reason: "..reason)
    self:RemoveMode(constants.MODE_RETREAT)
    self:setHeroVar("IsRetreating", false)
    self:setHeroVar("RetreatReason", nil)
    self:setHeroVar("RetreatLane", nil)
    return true
end

function X:DoEvade(bot)
    local aoes = getHeroVar("nearbyAOEs")
    if #aoes > 0 then
        for _, aoe in pairs(aoes) do
            local distFromCenter = GetUnitToLocationDistance(bot, aoe.location)
            if distFromCenter < aoe.radius then
                local escapeDist = aoe.radius - distFromCenter
                local escapeLoc = utils.VectorAway(bot:GetLocation(), aoe.location, escapeDist+50)
                gHeroVar.HeroMoveToLocation(bot, escapeLoc)
                return true
            else
                self:RemoveMode(constants.MODE_EVADE)
                return true
            end
        end
    else
        self:RemoveMode(constants.MODE_EVADE)
        return true
    end
    return false
end

function X:DoFight(bot)
    local target = self:getHeroVar("Target")
    if target.Id > 0 and IsHeroAlive(target.Id) then
        if utils.ValidTarget(target) then

            local inRangeEnemyTowers = {}
            for _, eTower in pairs(nearbyEnemyTowers) do
                if GetUnitToUnitDistance(bot, eTower) < 750 then
                    table.insert(inRangeEnemyTowers, eTower)
                end
            end

            local inRangeAlliedTowers = {}
            for _, aTower in pairs(nearbyAlliedTowers) do
                if GetUnitToUnitDistance(bot, aTower) < 650 then
                    table.insert(inRangeAlliedTowers, aTower)
                end
            end

            if #inRangeEnemyTowers == 0 and #nearbyEnemyHeroes == 1 then
                local enemy = nearbyEnemyHeroes[1]

                if enemy ~= target.Obj then
                    utils.myPrint("Unhandled situation, fix me!")
                    self:setHeroVar("Target", {Obj=enemy, Id=enemy:GetPlayerID()})
                end

                local ourDmgToTarget = 0
                for _, ally in pairs(nearbyAlliedHeroes) do
                    if GetUnitToUnitDistance( ally, enemy ) < enemy:GetAttackRange() then
                        ourDmgToTarget = ally:GetEstimatedDamageToTarget( true, enemy, 5.0, DAMAGE_TYPE_ALL )
                    end
                end

                local enemyDmgToMe = 0
                for _, enemy in pairs(nearbyEnemyHeroes) do
                    if GetUnitToUnitDistance( bot, enemy ) < enemy:GetAttackRange() then
                        enemyDmgToMe = enemyDmgToMe + enemy:GetEstimatedDamageToTarget( false, bot, 5.0, DAMAGE_TYPE_ALL )
                    end
                end

                if ourDmgToTarget > enemyDmgToMe and bot:GetHealth()+50 > enemyDmgToMe then
                    if enemy:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                        if utils.IsMelee(bot) then
                            if item_usage.UseMovementItems(enemy:GetLocation()) then return true end
                            bot:Action_MoveToUnit(enemy)
                        else
                            local dist = GetUnitToUnitDistance(bot, enemy)
                            if dist > 0.7*bot:GetAttackRange() then
                                if item_usage.UseMovementItems(enemy:GetLocation()) then return true end
                                gHeroVar.HeroMoveToLocation(bot, utils.VectorTowards(bot:GetLocation(), enemy:GetLocation(), dist-0.7*bot:GetAttackRange()))
                            elseif dist < 0.4*bot:GetAttackRange() then
                                gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), enemy:GetLocation(), 0.7*bot:GetAttackRange()-dist))
                            end
                        end
                    else
                        gHeroVar.HeroAttackUnit(bot, enemy, true)
                    end
                    return true
                else
                    utils.myPrint("Abandoning my fight against single enemy - too risky")
                    self:RemoveMode(MODE_FIGHT)
                    self:setHeroVar("Target", NoTarget)
                    return false
                end
                return false
            elseif #inRangeEnemyTowers > 0 and #nearbyEnemyHeroes > 1 then
                utils.myPrint("Abandoning Fight - a tower is close and more than 1 enemies")
                -- FIXME: Check number of allies vs number of enemies accounting for tower
                self:RemoveMode(MODE_FIGHT)
                self:setHeroVar("Target", NoTarget)
                return false
            elseif #nearbyEnemyHeroes > 1 then
                local ourDmgToTarget = 0
                for _, ally in pairs(nearbyAlliedHeroes) do
                    if GetUnitToUnitDistance( ally, target.Obj ) < target.Obj:GetAttackRange() then
                        ourDmgToTarget = ally:GetEstimatedDamageToTarget( true, target.Obj, 5.0, DAMAGE_TYPE_ALL )
                    end
                end

                local enemyDmgToMe = 0
                for _, enemy in pairs(nearbyEnemyHeroes) do
                    if GetUnitToUnitDistance( bot, enemy ) < enemy:GetAttackRange() then
                        enemyDmgToMe = enemyDmgToMe + enemy:GetEstimatedDamageToTarget( false, bot, 5.0, DAMAGE_TYPE_ALL )
                    end
                end
                if ourDmgToTarget > target.Obj:GetHealth() and enemyDmgToMe < ourDmgToTarget then --(bot:GetHealth() + 100) then
                    if target.Obj:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                        if utils.IsMelee(bot) then
                            if item_usage.UseMovementItems(enemy:GetLocation()) then return true end
                            bot:Action_MoveToUnit(target.Obj)
                        else
                            local dist = GetUnitToUnitDistance(bot, target.Obj)
                            if dist > 0.7*bot:GetAttackRange() then
                                if item_usage.UseMovementItems(enemy:GetLocation()) then return true end
                                gHeroVar.HeroMoveToLocation(bot, utils.VectorTowards(bot:GetLocation(), target.Obj:GetLocation(), dist-0.7*bot:GetAttackRange()))
                            elseif dist < 0.4*bot:GetAttackRange() then
                                gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), target.Obj:GetLocation(), 0.7*bot:GetAttackRange()-dist))
                            end
                        end
                    else
                        gHeroVar.HeroAttackUnit(bot, target.Obj, true)
                    end
                else
                    utils.myPrint("Abandoning my fight... doesn't look favorable")
                    self:RemoveMode(MODE_FIGHT)
                    self:setHeroVar("Target", NoTarget)
                    return false
                end
            elseif #inRangeEnemyTowers > 0 then
                local towerDmgToMe = 0
                local myDmgToTarget = bot:GetEstimatedDamageToTarget( true, target.Obj, 5.0, DAMAGE_TYPE_ALL )
                for _, tow in pairs(inRangeEnemyTowers) do
                    towerDmgToMe = towerDmgToMe + tow:GetEstimatedDamageToTarget( false, bot, 5.0, DAMAGE_TYPE_PHYSICAL )
                end
                if myDmgToTarget > target.Obj:GetHealth() and towerDmgToMe < (bot:GetHealth() + 100) then
                    --print(utils.GetHeroName(bot), " - we are tower diving for the kill")
                    if target.Obj:IsAttackImmune() or (bot:GetLastAttackTime() + bot:GetSecondsPerAttack()) > GameTime() then
                        if utils.IsMelee(bot) then
                            if item_usage.UseMovementItems(enemy:GetLocation()) then return true end
                            bot:Action_MoveToUnit(target.Obj)
                        else
                            local dist = GetUnitToUnitDistance(bot, target.Obj)
                            if dist > 0.7*bot:GetAttackRange() then
                                if item_usage.UseMovementItems(target.Obj:GetLocation()) then return true end
                                gHeroVar.HeroMoveToLocation(bot, utils.VectorTowards(bot:GetLocation(), target.Obj:GetLocation(), dist-0.7*bot:GetAttackRange()))
                            elseif dist < 0.4*bot:GetAttackRange() then
                                gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), target.Obj:GetLocation(), 0.7*bot:GetAttackRange()-dist))
                            end
                        end
                    else
                        gHeroVar.HeroAttackUnit(bot, target.Obj, true)
                    end
                    return true
                else
                    utils.myPrint("Abandoning my fight... enemy tower presence makes it not faovrable")
                    self:RemoveMode(MODE_FIGHT)
                    self:setHeroVar("Target", NoTarget)
                    return false
                end
            end
        else -- target alive but we don't see it
            if #nearbyEnemyTowers > 0 and GetUnitToUnitDistance(bot, nearbyEnemyTowers[1]) < 750 then
                self:RemoveMode(constants.MODE_FIGHT)
                setHeroVar("Target", NoTarget)
                return false
            end

            local timeSinceSeen = GetHeroLastSeenInfo(target.Id).time
            if timeSinceSeen > 3.0 then
                self:RemoveMode(constants.MODE_FIGHT)
                setHeroVar("Target", NoTarget)
                return false
            else
                local pLoc = enemyData.PredictedLocation(target.Id, timeSinceSeen)
                if pLoc then
                    if item_usage.UseMovementItems(pLoc) then return true end
                    gHeroVar.HeroMoveToLocation(bot, pLoc)
                    return true
                else
                    self:RemoveMode(constants.MODE_FIGHT)
                    setHeroVar("Target", NoTarget)
                    return false
                end
            end
        end
    else
        --utils.myPrint("TargetId was: ", target.Id)
        utils.AllChat("UMad bro?")
        self:RemoveMode(MODE_FIGHT)
        self:setHeroVar("Target", NoTarget)
    end

    return false
end

function X:DoUseShrine(bot)
    if bot:IsIllusion() then return false end

    -- if we somehow healed up to above 0.5 health and are not under shrine effect
    -- then we can cancel our desire to use shrine
    if bot:GetHealth()/bot:GetMaxHealth() > 0.5 and not bot:HasModifier("modifier_filler_heal") then
        utils.myPrint("Don't need to use shrine, canceling")
        self:setHeroVar("ShrineMode", nil)
        self:setHeroVar("Shrine", nil)
        self:RemoveMode(constants.MODE_SHRINE)
        think.UpdatePlayerAssignment(bot, "UseShrine", nil)
        return false
    end

    local botShrineMode = self:getHeroVar("ShrineMode")
    local shrine = self:getHeroVar("Shrine")

    --utils.myPrint("botShrineMode: ", botShrineMode[1], ", shrineLoc: ", tostring(shrine:GetLocation()))

    if botShrineMode then
        if shrine and GetUnitToUnitDistance(bot, shrine) > 300 then
            gHeroVar.HeroMoveToLocation(bot, shrine:GetLocation())
            local mvAbility = getHeroVar("HasMovementAbility")
            if mvAbility and mvAbility[1]:IsFullyCastable() then
                local newLoc = utils.VectorTowards(bot:GetLocation(), shrine:GetLocation(), mvAbility[2])
                gHeroVar.HeroPushUseAbilityOnLocation(bot, mvAbility[1], newLoc)
            end
            return true
        elseif botShrineMode[1] ~= constants.SHRINE_USE then
            if #botShrineMode[2] == 0 then
                self:setHeroVar("ShrineMode", {constants.SHRINE_USE, {}})
            else
                utils.myPrint("Waiting on more friends: ", #botShrineMode[2])
                for _, id in pairs(botShrineMode[2]) do
                    utils.myPrint("\tID: ", id)
                end
            end
            return true
        end
    end

    if shrine and shrine:GetHealth() > 0 and GetShrineCooldown(shrine) == 0 then
        utils.myPrint("using Shrine")
        bot:ActionPush_UseShrine(shrine)
        return true
    elseif bot:HasModifier("modifier_filler_heal") then
        return true
    end

    self:setHeroVar("ShrineMode", nil)
    self:setHeroVar("Shrine", nil)
    self:RemoveMode(constants.MODE_SHRINE)
    think.UpdatePlayerAssignment(bot, "UseShrine", nil)

    return false
end

function X:DoDefendAlly(bot)
    return true
end

function X:DoPushLane(bot)
    local Shrines = bot:GetNearbyShrines(750, true)
    local Barracks = bot:GetNearbyBarracks(750, true)
    local Ancient = GetAncient(utils.GetOtherTeam())

    if #nearbyEnemyHeroes > 0 then
        self:setHeroVar("ShouldPush", false)
        self:RemoveMode(constants.MODE_PUSHLANE)
        return false
    end

    if #nearbyEnemyTowers == 0 and #Shrines == 0 and #Barracks == 0 then
        if GetUnitToLocationDistance(bot, Ancient:GetLocation()) < 500 then
            if utils.NotNilOrDead(Ancient) and not Ancient:HasModifier("modifier_fountain_glyph") then
                gHeroVar.HeroAttackUnit(bot, Ancient, true)
                return true
            end
        end
    end

    -- we are pushing lane but no structures nearby, so push forward in lane
    local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), self:getHeroVar("CurLane"), false)
    local frontier = Min(1.0, enemyFrontier)
    local dest = GetLocationAlongLane(self:getHeroVar("CurLane"), Min(1.0, frontier))

    if utils.IsTowerAttackingMe() and #nearbyAlliedCreep > 0 then
        if utils.DropTowerAggro(bot, nearbyAlliedCreep) then return true end
    elseif utils.IsTowerAttackingMe() then
        self:RemoveMode(constants.MODE_PUSHLANE)
        return false
    end

    if #nearbyEnemyCreep > 0 then
        if #nearbyAlliedCreep > 0 then
            creep, _ = utils.GetWeakestCreep(nearbyEnemyCreep)
            if creep then
                gHeroVar.HeroAttackUnit(bot, creep, true)
                return true
            end
        else
            self:RemoveMode(constants.MODE_PUSHLANE)
            return false
        end
    end

    if #nearbyEnemyTowers > 0 and (#nearbyAlliedCreep > 1 or
        (#nearbyAlliedCreep == 1 and nearbyAlliedCreep[1]:GetHealth() > 162) or
        nearbyEnemyTowers[1]:GetHealth()/nearbyEnemyTowers[1]:GetMaxHealth() < 0.1) then
        for _, tower in ipairs(nearbyEnemyTowers) do
            if utils.NotNilOrDead(tower) and (not tower:HasModifier("modifier_fountain_glyph")) then
                --self:setHeroVar("ShouldPush", true)
                gHeroVar.HeroAttackUnit(bot, tower, true)
                return true
            else
                local dist = GetUnitToUnitDistance(bot, nearbyEnemyTowers[1])
                if dist < 710 then
                    gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), nearbyEnemyTowers[1]:GetLocation(), 710-dist))
                    return true
                end
            end
        end
    end

    if #Barracks > 0 then
        for _, barrack in ipairs(Barracks) do
            if utils.NotNilOrDead(barrack) and (not barrack:HasModifier("modifier_fountain_glyph")) then
                gHeroVar.HeroAttackUnit(bot, barrack, true)
                return true
            end
        end
    end

    if #Shrines > 0 then
        for _, shrine in ipairs(Shrines) do
            if utils.NotNilOrDead(shrine) and (not shrine:HasModifier("modifier_fountain_glyph")) then
                gHeroVar.HeroAttackUnit(bot, shrine, true)
                return true
            end
        end
    end

    utils.MoveSafelyToLocation(bot, dest)

    return false
end

function X:DoDefendLane(bot)
    debugging.SetBotState(utils.GetHeroName(bot), 2, "DO DEFEND LANE")
    local defendInfo = self:getHeroVar("DoDefendLane")
    local lane = defendInfo[1]
    local building = defendInfo[2]
    local numEnemies = defendInfo[3]
    local hBuilding = buildings_status.GetHandle(GetTeam(), building)

    -- if lane and hBuilding and hBuilding:TimeSinceDamagedByAnyHero() < 5.0 then
    if lane and hBuilding and numEnemiesNearBuilding(building) > 0 then -- FIXME: fix  defense is over  trigger
        utils.myPrint("Defending lane '"..lane.."' building: ", hBuilding:GetUnitName())
        local distFromBuilding = GetUnitToUnitDistance(bot, hBuilding)
        local timeToReachBuilding = distFromBuilding/bot:GetCurrentMovementSpeed()

        if timeToReachBuilding <= 5.0 then
            gHeroVar.HeroMoveToLocation(bot, hBuilding:GetLocation())
            return true
        else
            print("TPing")
            item_usage.UseTP(bot, hBuilding:GetLocation())
            return true
        end
    else
        print("Mission accomplished, the tower is safe!")
        self:RemoveMode(constants.MODE_DEFENDLANE)
        self:setHeroVar("DoDefendLane", {})
    end
    return false
end

function X:DoGank(bot)
    local bStillGanking = true
    local gankTarget = self:getHeroVar("GankTarget")
    if gankTarget.Id > 0 and IsHeroAlive(gankTarget.Id) then
        local bTimeToKill = ganking_generic.ApproachTarget(bot, gankTarget)
        if bTimeToKill then
            bStillGanking = ganking_generic.KillTarget(bot, gankTarget)
            self:RemoveMode(constants.MODE_GANKING)
            self:setHeroVar("GankTarget", NoTarget)
        end

        if not bStillGanking then
            utils.myPrint("clearing gank")
            self:RemoveMode(constants.MODE_GANKING)
            self:setHeroVar("GankTarget", NoTarget)
            self:setHeroVar("Target", NoTarget)
        end
    else
        if utils.ValidTarget(gankTarget) then
            utils.myPrint("clearing gank - target [Id:"..gankTarget.Id.."] Health: ", gankTarget.Obj:GetHealth(), ", Alive: ", IsHeroAlive(gankTarget.Id))
        else
            utils.myPrint("clearing gank - target [Id:"..gankTarget.Id.."] Alive: ", IsHeroAlive(gankTarget.Id))
        end
        self:RemoveMode(constants.MODE_GANKING)
        self:setHeroVar("GankTarget", NoTarget)
        self:setHeroVar("Target", NoTarget)
    end

    return bStillGanking
end

function X:DoRoam(bot)
    return true
end

function X:DoJungle(bot)
    jungling_generic.Think(bot)

    return true
end

function X:DoRoshan(bot)
    --FIXME: Implement Roshan fight and clear action stack when he dead
    self:RemoveMode(MODE_ROSHAN)
    return true
end

function X:AnalyzeLanes(nLane)
    if utils.InTable(nLane, self:getHeroVar("CurLane")) then
        return
    end

    if #nLane > 1 then
        local newLane = nLane[RandomInt(1, #nLane)]
        utils.myPrint("Randomly switching to lane: ", newLane)
        self:setHeroVar("CurLane", newLane)
    elseif #nLane == 1 then
        utils.myPrint("Switching to lane: ", nLane[1])
        self:setHeroVar("CurLane", nLane[1])
    else
        utils.myPrint("Switching to lane: ", LANE_MID)
        self:setHeroVar("CurLane", LANE_MID)
    end

    self:setHeroVar("LaningState", 1) -- 1 is LaningState.Moving
    return
end

function X:DoChangeLane(bot)
    local listBuildings = global_game_state.GetLatestVulnerableEnemyBuildings()
    local nLane = {}

    -- check Tier 1 towers
    if utils.InTable(listBuildings, 1) then table.insert(nLane, LANE_TOP) end
    if utils.InTable(listBuildings, 4) then table.insert(nLane, LANE_MID) end
    if utils.InTable(listBuildings, 7) then table.insert(nLane, LANE_BOT) end
    -- if we have found a standing Tier 1 tower, end
    if #nLane > 0 then
        return self:AnalyzeLanes(nLane)
    end

    -- check Tier 2 towers
    if utils.InTable(listBuildings, 2) then table.insert(nLane, LANE_TOP) end
    if utils.InTable(listBuildings, 5) then table.insert(nLane, LANE_MID) end
    if utils.InTable(listBuildings, 8) then table.insert(nLane, LANE_BOT) end
    -- if we have found a standing Tier 2 tower, end
    if #nLane > 0 then
        return self:AnalyzeLanes(nLane)
    end

    -- check Tier 3 towers & buildings
    if utils.InTable(listBuildings, 3) or utils.InTable(listBuildings, 12) or utils.InTable(listBuildings, 13) then table.insert(nLane, LANE_TOP) end
    if utils.InTable(listBuildings, 6) or utils.InTable(listBuildings, 14) or utils.InTable(listBuildings, 15) then table.insert(nLane, LANE_MID) end
    if utils.InTable(listBuildings, 9) or utils.InTable(listBuildings, 16) or utils.InTable(listBuildings, 17) then table.insert(nLane, LANE_BOT) end
    -- if we have found a standing Tier 3 tower, end
    if #nLane > 0 then
        return self:AnalyzeLanes(nLane)
    end

    return
end

function X:DoGetRune(bot)
    local runeLoc = self:getHeroVar("RuneLoc")
    local runeTarget = self:getHeroVar("RuneTarget")
    if runeTarget == nil or GetRuneStatus(runeTarget) == RUNE_STATUS_MISSING then
        self:setHeroVar("RuneTarget", nil)
        self:setHeroVar("RuneLoc", nil)
        self:RemoveMode(MODE_RUNEPICKUP)
        think.UpdatePlayerAssignment(bot, "GetRune", nil)
        return false
    else
        local dist = utils.GetDistance(bot:GetLocation(), runeLoc)
        if dist > 500 then
            gHeroVar.HeroMoveToLocation(bot, runeLoc)
            return true
        elseif GetRuneStatus(runeTarget) ~= RUNE_STATUS_MISSING then
            bot:Action_PickUpRune(runeTarget)
            return true
        end
    end
    return false
end

function X:DoWard(bot, wardType)
    local wardType = wardType or "item_ward_observer"
    local dest = self:getHeroVar("WardLocation")
    if dest ~= nil then
        local dist = GetUnitToLocationDistance(bot, dest)
        if dist <= constants.WARD_CAST_DISTANCE then
            local ward = item_usage.HaveWard(wardType)
            if ward then
                gHeroVar.HeroPushUseAbilityOnLocation(bot, ward, dest, constants.WARD_CAST_DISTANCE)
                U.InitPath()
                self:RemoveMode(MODE_WARD)
                self:setHeroVar("WardLocation", nil)
                self:setHeroVar("WardCheckTimer", GameTime())
                return true
            end
        else
            U.MoveSafelyToLocation(bot, dest)
            return true
        end
    else
        utils.myPrint("ERROR - BAD WARD LOC")
    end

    return false
end

function X:DoLane(bot)
    -- check if we shuld change lanes
    --self:DoChangeLane(bot)

    laning_generic.Think(bot, nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)

    return true
end

function X:MoveItemsFromStashToInventory(bot)
    utils.MoveItemsFromStashToInventory(bot)
end

function X:SaveLocation(bot)
    if self.Init then
        self:setHeroVar("LastLocation", bot:GetLocation())
    end
end

function X:DoHandleIllusions(bot)
    return bot:IsIllusion()
end

-------------------------------------------------------------------------------------
-- BELOW ARE COMPLETELY VIRTUAL FUNCTIONS THAT NEED TO BE IMLEMENTED IN HERO FILES --
-------------------------------------------------------------------------------------

function X:DoCleanCamp(bot, neutrals)
    gHeroVar.HeroAttackUnit(bot, neutrals[1], true)
end

function X:GetMaxClearableCampLevel(bot)
    return constants.CAMP_ANCIENT
end

function X:IsReadyToGank(bot)
    return false
end

function X:GetNukeDamage( hHero, hTarget )
    return 0, {}, 0, 0, 0, 10000
end

function X:QueueNuke( hHero, hTarget, actionQueue, engageDist )
    return
end

return X;
