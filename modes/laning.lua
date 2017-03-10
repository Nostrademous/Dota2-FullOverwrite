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

local function setHeroVar(var, value)
    gHeroVar.SetVar(GetBot():GetPlayerID(), var, value)
end

local function getHeroVar(var)
    return gHeroVar.GetVar(GetBot():GetPlayerID(), var)
end

----------

local listEnemies = {}
local listAllies = {}
local AttackRange       = 600
local AttackSpeed       = 1
local CurLane           = 0
local ShouldPush        = false
local LanePos           = nil

local LaningStates = {
    Start       = 0,
    Moving      = 1,
    CSing       = 2,
    MovingToPos = 3
}

local LaningState = LaningStates.Start

-------------------------------

local function Start(bot)
    if CurLane == LANE_MID then
        gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_2))
    elseif CurLane == LANE_TOP then
        gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_2)+Vector(-250, 1000))
    elseif CurLane == LANE_BOT then
        if utils.IsCore(bot) then
            gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_1))
        else
            gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_1)+Vector(-250, -250))
        end
    end

    if DotaTime() >= 0.3 then
        LaningState = LaningStates.Moving
    end
end

local function Moving(bot)
    local frontier = GetLaneFrontAmount(GetTeam(), CurLane, false)
    local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), CurLane, false)
    frontier = Min(frontier, enemyFrontier)

    if utils.HarassEnemy(bot, listEnemies) then return end
    
    local dest = GetLocationAlongLane(CurLane, Min(1.0, frontier))
    gHeroVar.HeroMoveToLocation(bot, dest)

    if #gHeroVar.GetNearbyEnemyCreep(bot, 1200) > 0 then
        LaningState = LaningStates.MovingToPos
    end
end

local function MovingToPos(bot)
    local listAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, 1200)
    -- if we are attacked by tower, drop aggro
    if utils.IsTowerAttackingMe() and #listAlliedCreep > 0 then
        if utils.DropTowerAggro(bot, listAlliedCreep) then
            return
        end
    -- else move away
    elseif utils.IsTowerAttackingMe() then
        local listEnemyTowers = gHeroVar.GetNearbyEnemyTowers(bot, 1200)
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
        return
    end

    -- if we are close to tower, don't get into tower range
    local listEnemyTowers = gHeroVar.GetNearbyEnemyTowers(bot, 710)
    if #listEnemyTowers > 0 then
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        if dist < 710 then
            gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
        end
    end
    
    if utils.HarassEnemy(bot, listEnemies) then return end

    local bNeedToGoHigher = false
    local higherDest = nil
    local listEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)
    for _, eCreep in ipairs(listEnemyCreep) do
        if eCreep:GetHealth()/eCreep:GetMaxHealth() <= 0.5 and utils.GetHeightDiff(bot, eCreep) < 0 then
            bNeedToGoHigher = true
            higherDest = eCreep:GetLocation()
            break
        end
    end

    local cpos = LanePos
    if #listEnemyTowers == 0 then
        cpos = GetLocationAlongLane(CurLane, GetLaneFrontAmount(utils.GetOtherTeam(), CurLane, false))
    else
        cpos = GetLocationAlongLane(CurLane, GetLaneFrontAmount(utils.GetOtherTeam(), CurLane, false) - 0.05)
    end
    
    local bpos = GetLocationAlongLane(CurLane, LanePos - 0.02)

    local dest = utils.VectorTowards(cpos, bpos, 500)
    if bNeedToGoHigher and #listAlliedCreep > 0 and #listEnemies == 0 then
        dest = higherDest
    end

    gHeroVar.HeroMoveToLocation(bot, dest)

    LaningState = LaningStates.CSing
end

local function DenyNearbyCreeps(bot)
    local listAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, 1200)
    if #listAlliedCreep == 0 then
        return false
    end

    local WeakestCreep, WeakestCreepHealth = utils.GetWeakestCreep(listAlliedCreep)

    if WeakestCreep == nil then
        return false
    end

    AttackRange = bot:GetAttackRange() + bot:GetBoundingRadius()

    local damage = 0
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

    if damage > WeakestCreep:GetHealth() and utils.GetDistance(bot:GetLocation(),WeakestCreep:GetLocation()) < AttackRange then
        utils.TreadCycle(bot, constants.AGILITY)
        gHeroVar.HeroAttackUnit(bot, WeakestCreep, true)
        return true
    end

    local approachScalar = 2.0
    if utils.IsMelee(bot) then
        approachScalar = 2.5
    end

    if WeakestCreepHealth < approachScalar*damage and utils.GetDistance(bot:GetLocation(), WeakestCreep:GetLocation()) > AttackRange then
        local dest = utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(CurLane, LanePos-0.03), AttackRange - 20 )
        gHeroVar.HeroMoveToLocation(bot, dest)
        return true
    end
    
    -- try to keep lane equilibrium
    if WeakestCreep ~= nil then
        local healthRatio = WeakestCreep:GetHealth()/WeakestCreep:GetMaxHealth()
        if healthRatio < 0.5 and WeakestCreepHealth > 2.5*damage and #listAlliedCreep >= #gHeroVar.GetNearbyEnemyCreep(bot, 1200) then
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
    local listAlliedCreep = gHeroVar.GetNearbyAlliedCreep(bot, 1200)
    if #listAlliedCreep == 0 then
        if not ShouldPush then
            LaningState = LaningStates.Moving
            return
        end
    end

    local listEnemyCreep = gHeroVar.GetNearbyEnemyCreep(bot, 1200)
    if #listEnemyCreep == 0 then
        LaningState = LaningStates.Moving
        return
    end
    
    local listEnemyTowers = gHeroVar.GetNearbyEnemyTowers(bot, 1200)
    if #listEnemyTowers > 0 then
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        if dist > 750 then
            gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 750-dist))
            return
        end
    end

    AttackRange = bot:GetAttackRange() + bot:GetBoundingRadius()
    AttackSpeed = bot:GetAttackPoint()

    local NoCoreAround = true
    for _,hero in pairs(listAllies) do
        if utils.IsCore(hero) then
            NoCoreAround = false
        end
    end

    if ShouldPush and (#listEnemies > 0 or DotaTime() < (60*3)) then
        ShouldPush = false
    end

    if utils.IsCore(bot) or (NoCoreAround and #listEnemies < 2) then
        local WeakestCreep, WeakestCreepHealth = utils.GetWeakestCreep(listEnemyCreep)

        if WeakestCreep == nil then
            LaningState = LaningStates.Moving
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

        if ShouldPush and WeakestCreep ~= nil then
            local bDone = PushCS(bot, WeakestCreep, nAc, damage, AttackSpeed)
            if bDone then return end
        end

        -- check if enemy has a breakable buff
        if #listEnemies > 0 and #listEnemies <= #listAllies then
            local breakableEnemy = nil
            for _, enemy in pairs(listEnemies) do
                if utils.EnemyHasBreakableBuff(enemy) then
                    breakableEnemy = enemy
                    break
                end
            end
            if breakableEnemy then
                --print(utils.GetHeroName(breakableEnemy).." has a breakable buff running")
                if (not utils.UseOrbEffect(bot, breakableEnemy)) then
                    if GetUnitToUnitDistance(bot, breakableEnemy) < (AttackRange+breakableEnemy:GetBoundingRadius()) then
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

        if (not ShouldPush) and WeakestCreepHealth < damage*approachScalar and GetUnitToUnitDistance(bot, WeakestCreep) > AttackRange and #listEnemyTowers == 0 then
            local dest = utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(CurLane, LanePos-0.03), AttackRange-20)
            gHeroVar.HeroMoveToLocation(bot, dest)
            return
        end

        if not ShouldPush then
            if DenyNearbyCreeps(bot) then
                return
            end
        end
    elseif not NoCoreAround then
        -- we are not a Core, we are not pushing, deny only
        if not ShouldPush then
            if DenyNearbyCreeps(bot) then
                return
            end
        end
    end
    
    -- if we got here we decided there are no creeps to kill/deny
    LaningState = LaningStates.MovingToPos
    
    if utils.HarassEnemy(bot, listEnemies) then return end
end

local function GetBack(bot)
    if GameTime() - getHeroVar("BackTimer") < 1 then
        return true
    end

    if bot:WasRecentlyDamagedByCreep(0.5) and bot:GetHealth() < 900 and bot:GetHealth()/bot:GetMaxHealth() < 0.8 then
        setHeroVar("BackTimer", GameTime())
        return true
    end
    
    if #listEnemies == 0 then
        return false
    end
    
    local allyTowers = gHeroVar.GetNearbyAlliedTowers(bot, 600)
    if #allyTowers > 0 and #listEnemies <= 3 then
        return false
    end
    
    local enemyDmg = 0
    for _, enemy in pairs(listEnemies) do
        if utils.NotNilOrDead(enemy) then
            local damage = enemy:GetEstimatedDamageToTarget(true, bot, 4, DAMAGE_TYPE_ALL)
            enemyDmg = enemyDmg + damage
        end
    end
    
    if enemyDmg*0.7 > bot:GetHealth() then
        setHeroVar("BackTimer", GameTime())
        return true
    end
    
    if enemyDmg > bot:GetHealth() and bot:TimeSinceDamagedByAnyHero() < 2 then
        setHeroVar("BackTimer", GameTime())
        return true
    end

    local stunDuration = 0
    local estDmgToMe = 0
    
    for _, enemy in pairs(listEnemies) do
        if enemy:GetHealth()/enemy:GetMaxHealth() > 0.1 and 
            GetUnitToUnitDistance(bot, enemy) <= (enemy:GetAttackRange() + enemy:GetBoundingRadius() + bot:GetBoundingRadius()) then
            stunDuration = stunDuration + enemy:GetStunDuration(true) + 0.5*enemy:GetSlowDuration(true)
        end
    end
    
    for _, enemy in pairs(listEnemies) do
        if enemy:GetHealth()/enemy:GetMaxHealth() > 0.1 and 
            GetUnitToUnitDistance(bot, enemy) <= (enemy:GetAttackRange() + enemy:GetBoundingRadius() + bot:GetBoundingRadius()) then
            estDmgToMe = estDmgToMe + enemy:GetEstimatedDamageToTarget(true, bot, Min(3.0, stunDuration), DAMAGE_TYPE_ALL)
        end
    end
    
    if (1.15-0.15*#listAllies)*estDmgToMe > bot:GetHealth() then
        setHeroVar("BackTimer", GameTime())
        return true
    end

    setHeroVar("BackTimer", -1000)
    return false
end

local function StayBack(bot)
    local LaneFront = GetLaneFrontAmount(GetTeam(), CurLane, false)
    local LaneEnemyFront = GetLaneFrontAmount(utils.GetOtherTeam(), CurLane, false)
    local BackFront = Min(LaneFront, LaneEnemyFront)

    local BackPos = GetLocationAlongLane(CurLane, BackFront - 0.05) + RandomVector(200)
    gHeroVar.HeroMoveToLocation(bot, BackPos)
    setHeroVar("LaningStateInfo", "StayBack")
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
    LaningState = getHeroVar("LaningState")
    CurLane     = getHeroVar("CurLane")
    LanePos     = utils.PositionAlongLane(bot, CurLane)
    ShouldPush  = getHeroVar("ShouldPush")

    if not bot:IsAlive() then
        LaningState = LaningStates.Moving
    end

    listEnemies = gHeroVar.GetNearbyEnemies(bot, 1200)
    listAllies  = gHeroVar.GetNearbyAllies(bot, 1200)
end

local function SaveLaningData()
    setHeroVar("LaningState", LaningState)
    setHeroVar("ShouldPush", ShouldPush)
end

function X:GetName()
    return "laning"
end

function X:OnStart(myBot)
    setHeroVar("BackTimer", -1000.0)
    setHeroVar("LaningState", LaningStates.Start)
end

function X:OnEnd()
end

--------------------------------

local States = {
    [LaningStates.Start]        = Start,
    [LaningStates.Moving]       = Moving,
    [LaningStates.CSing]        = CSing,
    [LaningStates.MovingToPos]  = MovingToPos
}

----------------------------------

function X:Think(bot)

    if utils.IsBusy(bot) then return end
    
    LoadLaningData(bot)
    
    if GetBack(bot) then
        StayBack(bot)
        return
    end

    --utils.myPrint("LaningState: ", LaningStatePrint(LaningState))
    setHeroVar("LaningStateInfo", LaningStatePrint(LaningState))
    States[LaningState](bot)
    SaveLaningData()
end

function X:Desire(bot)
    return BOT_MODE_DESIRE_VERYLOW
end

return X