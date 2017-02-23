-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

-------
_G._savedEnv = getfenv()
module( "laning_generic", package.seeall )
----------
local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
    local bot = GetBot()
    gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
    local bot = GetBot()
    return gHeroVar.GetVar(bot:GetPlayerID(), var)
end
----------

local listEnemies = {}
local listAllies = {}
local listEnemyCreep = {}
local listAlliedCreep = {}
local listEnemyTowers = {}
local listAlliedTowers = {}

local CurLane           = nil
local BaseDamage        = 50
local AttackRange       = 150
local AttackSpeed       = 0.6
local LastTiltTime      = 0.0

local DamageThreshold   = 1.0
local MoveThreshold     = 1.0

local ShouldPush        = false
local IsCore            = nil
local LanePos           = nil

local LaningStates={
    Start       = 0,
    Moving      = 1,
    CSing       = 2,
    MovingToPos = 3,
    GettingBack = 4,
    MovingToLane= 5
}

local LaningState = LaningStates.Start

-------------------------------

local function HarassEnemy(bot)
    for _, enemy in pairs(listEnemies) do
        for _, myTower in pairs(listAlliedTowers) do
            if GetUnitToUnitDistance(myTower, enemy) < 600 then
                local stunAbilities = gHeroVar.GetVar(bot:GetPlayerID(),"HasStun")
                if stunAbilities then
                    for _, stun in pairs(stunAbilities) do
                        if not enemy:IsStunned() and stun[1]:IsFullyCastable() then
                            local behaviorFlag = stun[1]:GetBehavior()
                            if utils.CheckFlag(behaviorFlag, ABILITY_BEHAVIOR_UNIT_TARGET) then
                                bot:Action_UseAbilityOnEntity(stun[1], enemy)
                                return true
                            elseif utils.CheckFlag(behaviorFlag, ABILITY_BEHAVIOR_POINT) then
                                bot:Action_UseAbilityOnLocation(stun[1], enemy:GetExtrapolatedLocation(stun[2]))
                                return true
                            end
                        end
                    end
                end
                gHeroVar.HeroAttackUnit(bot, enemy, true)
                return true
            end
        end
    end
    
    if utils.UseOrbEffect(bot) then return true end
    
    if #listEnemies == 1 and (#listEnemyCreep < #listAlliedCreep or #listEnemyCreep == 0) and 
        GetUnitToUnitDistance(bot, listEnemies[1]) < (bot:GetAttackRange()+bot:GetBoundingRadius()) then
        gHeroVar.HeroAttackUnit(bot, listEnemies[1], true)
        return true
    end
    
    return false
end

local function MovingToLane(bot)
    local dest = GetLocationAlongLane(getHeroVar("CurLane"),GetLaneFrontAmount(GetTeam(), getHeroVar("CurLane"), false) - 0.04)

    if GetUnitToLocationDistance(bot, dest) < 300 then
        LaningState = LaningStates.Moving
        return
    end
    
    utils.MoveSafelyToLocation(bot, dest)
end

local function Start(bot)
    if CurLane == LANE_MID then
        gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_2))
    elseif CurLane == LANE_TOP then
        gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_2)+Vector(-250, 1000))
    elseif CurLane == LANE_BOT then
        if IsCore then
            gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_1))
        else
            gHeroVar.HeroMoveToLocation(bot, GetRuneSpawnLocation(RUNE_BOUNTY_1)+Vector(-250, -250))
        end
    end

    if DotaTime() > 1 then
        LaningState = LaningStates.Moving
    end
end

local function Moving(bot)
    local frontier = GetLaneFrontAmount(GetTeam(), CurLane, true)
    local enemyFrontier = GetLaneFrontAmount(utils.GetOtherTeam(), CurLane, false)
    frontier = Min(frontier, enemyFrontier)
    
    if ShouldPush then
        frontier = 1.0
    end

    --[[
    local noTower = true
    if #listEnemyTowers > 0 and GetUnitToUnitDistance(bot, listEnemyTowers[1]) > 750 then
        noTower = false
    end
    --]]

    local target = GetLocationAlongLane(CurLane, Min(1.0, frontier))
    --utils.myPrint( "Lane: ", CurLane, " Going Forward :: MyLanePos:  ", LanePos, " TARGET: ", target[1], ",", target[2])
    utils.MoveSafelyToLocation(bot, target)
    
    if HarassEnemy(bot) then return true end

    if #listEnemyCreep > 0 then
        LaningState = LaningStates.MovingToPos
    end
end

local function MovingToPos(bot)
    if utils.IsTowerAttackingMe(0.1) and #listAlliedCreep > 0 then
        if utils.DropTowerAggro(bot, listAlliedCreep) then return true end
    elseif utils.IsTowerAttackingMe(0.1) and #listEnemyTowers > 0 then
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        if dist < 710 then
            gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
        end
    end

    if #listEnemyTowers > 0 then
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        if dist < 710 then
            gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
        end
    end
    
    if HarassEnemy(bot) then return true end

    local bNeedToGoHigher = false
    local higherDest = nil
    for _, eCreep in ipairs(listEnemyCreep) do
        if eCreep:GetHealth()/eCreep:GetMaxHealth() <= 0.5 and utils.GetHeightDiff(bot, eCreep) < 0 then
            bNeedToGoHigher = true
            higherDest = eCreep:GetLocation()
            break
        end
    end

    local cpos = LanePos
    if #listEnemyTowers == 0 then
        cpos = GetLocationAlongLane(CurLane, GetLaneFrontAmount(utils.GetOtherTeam(),CurLane, false))
    else
        cpos = GetLocationAlongLane(CurLane, GetLaneFrontAmount(utils.GetOtherTeam(),CurLane, false) - 0.05)
    end
    
    local bpos = GetLocationAlongLane(CurLane, LanePos-0.02)

    local dest = utils.VectorTowards(cpos, bpos, 500)
    if bNeedToGoHigher and #listAlliedCreep > 0 then
        dest = higherDest
    end

    local rndtilt = RandomVector(75)

    dest = dest + rndtilt

    gHeroVar.HeroMoveToLocation(bot, dest)

    LaningState = LaningStates.CSing
end

local function GettingBack(bot)
    if #listAlliedCreep > 0 or LanePos < 0.18 then
        LaningState = LaningStates.Moving
        return
    end

    gHeroVar.HeroMoveToLocation(bot, GetLocationAlongLane(CurLane, Max(LanePos-0.03, 0.0)))
end

local function DenyNearbyCreeps(bot)
    if #listAlliedCreep == 0 then
        return false
    end

    local WeakestCreep, WeakestCreepHealth = utils.GetWeakestCreep(listAlliedCreep)

    if WeakestCreep == nil then
        return false
    end

    AttackRange = bot:GetAttackRange()

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

    if WeakestCreepHealth < approachScalar*damage and utils.GetDistance(bot:GetLocation(),WeakestCreep:GetLocation()) > bot:GetAttackRange() then
        local dest = utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(CurLane,LanePos-0.03), AttackRange - 20 )
        gHeroVar.HeroMoveToLocation(bot, dest)
        return true
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
    
    if HarassEnemy(bot) then return true end

    gHeroVar.HeroAttackUnit(bot, WeakestCreep, false)
    return true
end

local function CSing(bot)
    if #listAlliedCreep == 0 then
        if not ShouldPush then
            LaningState = LaningStates.Moving
            return
        end
    end

    if #listEnemyCreep == 0 then
        LaningState = LaningStates.Moving
        return
    end
    
    if #listEnemyTowers > 0 then
        local dist = GetUnitToUnitDistance(bot, listEnemyTowers[1])
        if dist < 710 then
            gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
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

    if IsCore or (NoCoreAround and #listEnemies < 2) then
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

        if (not ShouldPush) and WeakestCreepHealth < damage*approachScalar and GetUnitToUnitDistance(bot,WeakestCreep) > AttackRange and EnemyTowers == nil then
            local dest = utils.VectorTowards(WeakestCreep:GetLocation(),GetLocationAlongLane(CurLane,LanePos-0.03), AttackRange-20)
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
    
    if HarassEnemy(bot) then return true end
end

--------------------------------

local States = {
[LaningStates.Start]=Start,
[LaningStates.Moving]=Moving,
[LaningStates.CSing]=CSing,
[LaningStates.MovingToPos]=MovingToPos,
[LaningStates.GettingBack]=GettingBack,
[LaningStates.MovingToLane]=MovingToLane
}

----------------------------------

local function Updates(bot, lE, lA, lEC, lAC, lET, lAT)
    listEnemies = lE
    listAllies = lA
    listEnemyCreep = lEC
    listAlliedCreep = lAC
    listEnemyTowers = lET
    listAlliedTowers = lAT

    CurLane = getHeroVar("CurLane")
    LanePos = utils.PositionAlongLane(bot, CurLane)

    if getHeroVar("IsCore") == nil then
        IsCore = utils.IsCore(bot)
        setHeroVar("IsCore", IsCore)
    else
        IsCore = getHeroVar("IsCore")
    end

    if getHeroVar("LaningState") ~= nil then
        LaningState = getHeroVar("LaningState")
    end

    if getHeroVar("MoveThreshold") ~= nil then
        MoveThreshold = getHeroVar("MoveThreshold")
    end

    if getHeroVar("DamageThreshold") ~= nil then
        DamageThreshold = getHeroVar("DamageThreshold")
    end

    if getHeroVar("ShouldPush") ~= nil then
        ShouldPush = getHeroVar("ShouldPush")
    end

    if ( not bot:IsAlive() ) or ( LanePos < 0.15 and LaningState ~= LaningStates.Start ) then
        LaningState = LaningStates.Moving
    end
end

local function GetBack(bot)
    if getHeroVar("BackTimer") == nil then
        setHeroVar("BackTimer", -1000)
        return false
    end

    if DotaTime() - getHeroVar("BackTimer") < 1 then
        return true
    end

    if #listEnemies == 0 then
        return false
    end

    if #listAlliedTowers > 0 and (#listEnemies - #listAllies) < 2 then
        return false
    end

    if #listEnemies > #listAllies then
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
                estDmgToMe = estDmgToMe + enemy:GetEstimatedDamageToTarget(true, bot, 3.0 + stunDuration, DAMAGE_TYPE_ALL)
            end
        end
        
        if bot:WasRecentlyDamagedByAnyHero(2.0) and estDmgToMe > 0.9*bot:GetHealth() then
            setHeroVar("BackTimer", DotaTime()+2.0)
            return true
        end
    end

    setHeroVar("BackTimer", -1000)
    return false
end

local function StayBack(bot)
    local LaneFront = GetLaneFrontAmount(GetTeam(), getHeroVar("CurLane"), true)
    local LaneEnemyFront = GetLaneFrontAmount(utils.GetOtherTeam(), getHeroVar("CurLane"), false)
    local BackFront = Min(LaneFront, LaneEnemyFront)

    local BackPos = GetLocationAlongLane(getHeroVar("CurLane"), BackFront - 0.03)

    gHeroVar.HeroMoveToLocation(bot, BackPos)
end

local function LaningStatePrint(state)
    if state == 0 then return "Start"
    elseif state == 1 then return "Moving"
    elseif state == 2 then return "CSing"
    elseif state == 3 then return "MovingToPos"
    elseif state == 4 then return "GettingBack"
    elseif state == 5 then return "MovingToLane"
    else return "<UNKNOWN>"
    end
end

function Think(bot, listEnemies, listAllies, listEnemyCreep, listAlliedCreep, listEnemyTowers, listAlliedTowers)
    if getHeroVar("BackTimer") == nil then
        setHeroVar("BackTimer", -1000)
        local dest = GetLocationAlongLane(getHeroVar("CurLane"), GetLaneFrontAmount(GetTeam(), getHeroVar("CurLane"), true)-0.04)
        if GetUnitToLocationDistance(bot, dest) > 1500 then
            utils.InitPath(bot)
            setHeroVar("LaningState", LaningStates.MovingToLane)
        end
    end

    Updates(bot, listEnemies, listAllies, listEnemyCreep, listAlliedCreep, listEnemyTowers, listAlliedTowers)
    
    if GetBack(bot) then
        StayBack(bot)
        return
    end

    --utils.myPrint("LaningState: ", LaningStatePrint(LaningState))

    States[LaningState](bot)

    setHeroVar("LaningState", LaningState)
    setHeroVar("ShouldPush", shouldPush)
end


--------
for k,v in pairs( laning_generic ) do _G._savedEnv[k] = v end
