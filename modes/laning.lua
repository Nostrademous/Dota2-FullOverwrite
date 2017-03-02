-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

----------
local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

----------

X.listEnemies = {}
X.listAllies = {}

X.me                = nil
X.AttackRange       = 150
X.AttackSpeed       = 0.6

X.CurLane           = 0
X.ShouldPush        = false
X.LanePos           = nil
X.BackTimer         = -1000

X.LaningStates = {
    Start       = 0,
    Moving      = 1,
    CSing       = 2,
    MovingToPos = 3
}

X.LaningState = X.LaningStates.Start

-------------------------------

local function Start(bot)
    if X.CurLane == LANE_MID then
        gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_2))
    elseif X.CurLane == LANE_TOP then
        gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_2)+Vector(-250, 1000))
    elseif X.CurLane == LANE_BOT then
        if utils.IsCore(bot) then
            gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_1))
        else
            gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_1)+Vector(-250, -250))
        end
    end

    if DotaTime() >= 0.3 then
        X.LaningState = X.LaningStates.Moving
    end
end

local function Moving(bot)
    local frontier = GetLaneFrontAmount(GetTeam(), X.CurLane, false)
    local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), X.CurLane, false)
    frontier = Min(frontier, enemyFrontier)

    if utils.HarassEnemy(bot, listEnemies) then return end
    
    local dest = GetLocationAlongLane(X.CurLane, Min(1.0, frontier))
    gHeroVar.HeroMoveToLocation(bot, dest)

    local listEnemyCreep = bot:GetNearbyCreeps(1200, true)
    if #listEnemyCreep > 0 then
        X.LaningState = X.LaningStates.MovingToPos
    end
end

local function MovingToPos(bot)
    local listAlliedCreep = bot:GetNearbyCreeps(1200, false)
    -- if we are attacked by tower, drop aggro
    if utils.IsTowerAttackingMe() and #listAlliedCreep > 0 then
        if utils.DropTowerAggro(bot, listAlliedCreep) then return end
    -- else move away
    elseif utils.IsTowerAttackingMe() then
        local listEnemyTowers = bot:GetNearbyTowers(700, true)
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
        return
    end

    -- if we are close to tower, don't get into tower range
    local listEnemyTowers = bot:GetNearbyTowers(710, true)
    if #listEnemyTowers > 0 then
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        if dist < 710 then
            gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
        end
    end
    
    if utils.HarassEnemy(bot, listEnemies) then return end

    local bNeedToGoHigher = false
    local higherDest = nil
    local listEnemyCreep = bot:GetNearbyCreeps(1200, true)
    for _, eCreep in ipairs(listEnemyCreep) do
        if eCreep:GetHealth()/eCreep:GetMaxHealth() <= 0.5 and utils.GetHeightDiff(bot, eCreep) < 0 then
            bNeedToGoHigher = true
            higherDest = eCreep:GetLocation()
            break
        end
    end

    local cpos = X.LanePos
    if #listEnemyTowers == 0 then
        cpos = GetLocationAlongLane(CurLane, GetLaneFrontAmount(utils.GetOtherTeam(), X.CurLane, false))
    else
        cpos = GetLocationAlongLane(CurLane, GetLaneFrontAmount(utils.GetOtherTeam(), X.CurLane, false) - 0.05)
    end
    
    local bpos = GetLocationAlongLane(CurLane, X.LanePos-0.02)

    local dest = utils.VectorTowards(cpos, bpos, 500)
    if bNeedToGoHigher and #listAlliedCreep > 0 and #listEnemies == 0 then
        dest = higherDest
    end

    gHeroVar.HeroMoveToLocation(bot, dest)

    X.LaningState = X.LaningStates.CSing
end

local function DenyNearbyCreeps(bot)
    local listAlliedCreep = bot:GetNearbyCreeps(1200, false)
    if #listAlliedCreep == 0 then
        return false
    end

    local WeakestCreep, WeakestCreepHealth = utils.GetWeakestCreep(listAlliedCreep)

    if WeakestCreep == nil then
        return false
    end

    X.AttackRange = bot:GetAttackRange() + bot:GetBoundingRadius()

    local eDamage = bot:GetEstimatedDamageToTarget(true, WeakestCreep, bot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL)
    if utils.IsMelee(bot) then
        damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (bot:GetAttackPoint() / (1 + bot:GetAttackSpeed()))
    else
        damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (bot:GetAttackPoint() / (1 + bot:GetAttackSpeed()) + GetUnitToUnitDistance(bot, WeakestCreep) / 1100)
    end

    if WeakestCreep ~= nil and damage > WeakestCreep:GetMaxHealth() then
        -- this occasionally will happen when a creep gets nuked by a target or AOE ability and takes
        -- a large amount of damage so it has a huge health drop delta, in that case just use eDamage
        damage = eDamage
    end

    if damage > WeakestCreep:GetHealth() and utils.GetDistance(bot:GetLocation(),WeakestCreep:GetLocation()) < X.AttackRange then
        utils.TreadCycle(bot, constants.AGILITY)
        gHeroVar.HeroAttackUnit(bot, WeakestCreep, true)
        return true
    end

    local approachScalar = 2.0
    if utils.IsMelee(bot) then
        approachScalar = 2.5
    end

    if WeakestCreepHealth < approachScalar*damage and utils.GetDistance(bot:GetLocation(),WeakestCreep:GetLocation()) > bot:GetAttackRange() then
        local dest = utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(X.CurLane, X.LanePos-0.03), X.AttackRange - 20 )
        gHeroVar.HeroMoveToLocation(bot, dest)
        return true
    end
    
    -- try to keep lane equilibrium
    if WeakestCreep ~= nil then
        local healthRatio = WeakestCreep:GetHealth()/WeakestCreep:GetMaxHealth()
        local listEnemyCreep = bot:GetNearbyCreeps(1200, false)
        if healthRatio < 0.5 and WeakestCreepHealth > 2.0*damage and #listAlliedCreep >= #listEnemyCreep then
            gHeroVar.HeroAttackUnit(bot, WeakestCreep, true)
        end
    end
    
    return false
end

local function PushCS(bot, WeakestCreep, nAc, damage, AS)
    utils.TreadCycle(bot, constants.AGILITY)
    if WeakestCreep:GetHealth() > damage and WeakestCreep:GetHealth() < (damage + 17*nAc*AS) and nAc > 1 then
        if #listEnemyCreep > 1 then
            if listEnemyCreep[1] ~= WeakestCreep then
                gHeroVar.HeroAttackUnit(bot, listEnemyCreep[1], true)
            else
                gHeroVar.HeroAttackUnit(bot, listEnemyCreep[2], true)
            end
            return true
        else
            return false
        end
    end
    
    if utils.HarassEnemy(bot, listEnemies) then return end

    gHeroVar.HeroAttackUnit(bot, WeakestCreep, false)
    return true
end

local function CSing(bot)
    local listAlliedCreep = bot:GetNearbyCreeps(1200, false)
    if #listAlliedCreep == 0 then
        if not X.ShouldPush then
            X.LaningState = X.LaningStates.Moving
            return
        end
    end

    local listEnemyCreep = bot:GetNearbyCreeps(1200, true)
    if #listEnemyCreep == 0 then
        X.LaningState = X.LaningStates.Moving
        return
    end
    
    local listEnemyTowers = bot:GetNearbyTowers(710, true)
    if #listEnemyTowers > 0 then
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
        return
    end

    X.AttackRange = bot:GetAttackRange() + bot:GetBoundingRadius()
    X.AttackSpeed = bot:GetAttackPoint()

    local NoCoreAround = true
    for _,hero in pairs(X.listAllies) do
        if utils.IsCore(hero) then
            NoCoreAround = false
        end
    end

    if X.ShouldPush and (#X.listEnemies > 0 or DotaTime() < (60*3)) then
        X.ShouldPush = false
    end

    if utils.IsCore(bot) or (NoCoreAround and #X.listEnemies < 2) then
        local WeakestCreep, WeakestCreepHealth = utils.GetWeakestCreep(listEnemyCreep)

        if WeakestCreep == nil then
            X.LaningState = X.LaningStates.Moving
            return
        end

        local nAc = 0
        if WeakestCreep ~= nil then
            for _,acreep in pairs(listAlliedCreep) do
                if utils.NotNilOrDead(acreep) and GetUnitToUnitDistance(acreep, WeakestCreep) < 120 then
                    nAc = nAc + 1
                end
            end
        end

        local eDamage = bot:GetEstimatedDamageToTarget(true, WeakestCreep, bot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL)
        if utils.IsMelee(bot) then
            damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (bot:GetAttackPoint() / (1 + bot:GetAttackSpeed()))
        else
            damage = eDamage + utils.GetCreepHealthDeltaPerSec(WeakestCreep) * (bot:GetAttackPoint() / (1 + bot:GetAttackSpeed()) + GetUnitToUnitDistance(bot, WeakestCreep) / 1100)
        end

        if WeakestCreep ~= nil and damage > WeakestCreep:GetMaxHealth() then
            -- this occasionally will happen when a creep gets nuked by a target or AOE ability and takes
            -- a large amount of damage so it has a huge health drop delta, in that case just use eDamage
            damage = eDamage
        end

        if WeakestCreep ~= nil and WeakestCreepHealth < damage then
            utils.TreadCycle(bot, constants.AGILITY)
            gHeroVar.HeroAttackUnit(bot, WeakestCreep, true)
            return
        end

        if X.ShouldPush and WeakestCreep ~= nil then
            local bDone = PushCS(bot, WeakestCreep, nAc, damage, X.AttackSpeed)
            if bDone then return end
        end

        -- check if enemy has a breakable buff
        if #X.listEnemies > 0 and #X.listEnemies <= #X.listAllies then
            local breakableEnemy = nil
            for _, enemy in pairs(X.listEnemies) do
                if utils.EnemyHasBreakableBuff(enemy) then
                    breakableEnemy = enemy
                    break
                end
            end
            if breakableEnemy then
                --print(utils.GetHeroName(breakableEnemy).." has a breakable buff running")
                if (not utils.UseOrbEffect(bot, breakableEnemy)) then
                    if GetUnitToUnitDistance(bot, breakableEnemy) < (X.AttackRange+breakableEnemy:GetBoundingRadius()) then
                        utils.TreadCycle(bot, constants.AGILITY)
                        gHeroVar.HeroAttackUnit(bot, breakableEnemy, true)
                        return
                    end
                end
            end
        end

        local approachScalar = 2.0
        if utils.IsMelee(bot) then
            approachScalar = 2.5
        end

        if (not X.ShouldPush) and WeakestCreepHealth < damage*approachScalar and GetUnitToUnitDistance(bot,WeakestCreep) > X.AttackRange and EnemyTowers == nil then
            local dest = utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(X.CurLane, X.LanePos-0.03), X.AttackRange-20)
            gHeroVar.HeroMoveToLocation(bot, dest)
            return
        end

        if not X.ShouldPush then
            if DenyNearbyCreeps(bot) then
                return
            end
        end
    elseif not NoCoreAround then
        -- we are not a Core, we are not pushing, deny only
        if not X.ShouldPush then
            if DenyNearbyCreeps(bot) then
                return
            end
        end
    end
    
    -- if we got here we decided there are no creeps to kill/deny
    X.LaningState = X.LaningStates.MovingToPos
    
    if utils.HarassEnemy(bot, listEnemies) then return end
end

local function GetBack(bot)
    if GameTime() - X.BackTimer < 1 then
        return true
    end

    if #X.listEnemies == 0 then
        return false
    end

    local stunDuration = 0
    local estDmgToMe = 0
    
    for _, enemy in pairs(X.listEnemies) do
        if enemy:GetHealth()/enemy:GetMaxHealth() > 0.1 and 
            GetUnitToUnitDistance(bot, enemy) <= (enemy:GetAttackRange() + enemy:GetBoundingRadius() + bot:GetBoundingRadius()) then
            stunDuration = stunDuration + enemy:GetStunDuration(true) + 0.5*enemy:GetSlowDuration(true)
        end
    end
    
    for _, enemy in pairs(X.listEnemies) do
        if enemy:GetHealth()/enemy:GetMaxHealth() > 0.1 and 
            GetUnitToUnitDistance(bot, enemy) <= (enemy:GetAttackRange() + enemy:GetBoundingRadius() + bot:GetBoundingRadius()) then
            estDmgToMe = estDmgToMe + enemy:GetEstimatedDamageToTarget(true, bot, 3.0 + stunDuration, DAMAGE_TYPE_ALL)
        end
    end
    
    if (1.15-0.15*#X.listAllies)*estDmgToMe > bot:GetHealth() then
        X.BackTimer = GameTime() + 3.0
        return true
    end

    X.BackTimer = -1000
    return false
end

local function StayBack(bot)
    local LaneFront = GetLaneFrontAmount(GetTeam(), X.CurLane, false)
    local LaneEnemyFront = GetLaneFrontAmount(utils.GetOtherTeam(), X.CurLane, false)
    local BackFront = Min(LaneFront, LaneEnemyFront)

    local BackPos = GetLocationAlongLane(X.CurLane, BackFront - 0.05)

    if #X.listEnemies > 0 then
        table.sort(X.listEnemies, function(e1, e2) return GetUnitToUnitDistance(bot, e1) < GetUnitToUnitDistance(bot, e2) end)
        if GetUnitToUnitDistance(bot, X.listEnemies[1]) < 700 then
            BackPos = GetLocationAlongLane(X.CurLane, utils.PositionAlongLane(X.listEnemies[1], X.CurLane) - 0.05)
        end
    end

    gHeroVar.HeroMoveToLocation(bot, BackPos)
end

local function LaningStatePrint(state)
    if state == 0 then return "Start"
    elseif state == 1 then return "Moving"
    elseif state == 2 then return "CSing"
    elseif state == 3 then return "MovingToPos"
    else return "<UNKNOWN>"
    end
end

local function LoadLaningData(bot)
    X.LaningState = X.me:getHeroVar("LaningState")
    X.CurLane     = X.me:getHeroVar("CurLane")
    X.LanePos     = utils.PositionAlongLane(bot, X.CurLane)
    X.ShouldPush  = X.me:getHeroVar("ShouldPush")

    if not bot:IsAlive() then
        X.LaningState = X.LaningStates.Moving
    end

    X.listEnemies = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    X.listAllies  = bot:GetNearbyHeroes(800, false, BOT_MODE_NONE)
end

local function SaveLaningData()
    X.me:setHeroVar("LaningState", X.LaningState)
    X.me:setHeroVar("ShouldPush", X.ShouldPush)
end

function X:GetName()
    return "Laning Mode"
end

function X:OnStart(myBot)
    X.me = myBot
    X.BackTimer = -1000.0
    X.me:setHeroVar("LaningState", X.LaningStates.Start)
end

function X:OnEnd()
end

--------------------------------

X.States = {
    [X.LaningStates.Start]        = Start,
    [X.LaningStates.Moving]       = Moving,
    [X.LaningStates.CSing]        = CSing,
    [X.LaningStates.MovingToPos]  = MovingToPos,
}

----------------------------------

function X:Think(bot)
    LoadLaningData(bot)
    
    if GetBack(bot) then
        StayBack(bot)
        return
    end

    if utils.IsBusy(bot) then return end

    --utils.myPrint("LaningState: ", LaningStatePrint(X.LaningState))
    X.States[X.LaningState](bot)

    SaveLaningData()
end

return X