-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- CONTRIBUTOR: Code based on work by Platinum_dota2
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "laning", package.seeall )

----------
local utils = require( GetScriptDirectory().."/utility")
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

----------

local listEnemies = {}
local listAllies = {}

local me                = nil
local AttackRange       = 150
local AttackSpeed       = 0.6

local CurLane           = 0
local ShouldPush        = false
local LanePos           = nil
local BackTimer         = -1000

local LaningStates={
    Start       = 0,
    Moving      = 1,
    CSing       = 2,
    MovingToPos = 3
}

local LaningState = LaningStates.Start

-------------------------------

local function HarassEnemy(bot)
    local listAlliedTowers = bot:GetNearbyTowers(600, false)
    for _, enemy in pairs(listEnemies) do
        for _, myTower in pairs(listAlliedTowers) do
            local stunAbilities = me:getHeroVar("HasStun")
            if stunAbilities then
                for _, stun in pairs(stunAbilities) do
                    if not enemy:IsStunned() and stun[1]:IsFullyCastable() then
                        local behaviorFlag = stun[1]:GetBehavior()
                        if utils.CheckFlag(behaviorFlag, ABILITY_BEHAVIOR_UNIT_TARGET) then
                            bot:Action_UseAbilityOnEntity(stun[1], enemy)
                            return true
                        elseif utils.CheckFlag(behaviorFlag, ABILITY_BEHAVIOR_POINT) then
                            bot:Action_UseAbilityOnLocation(stun[1], enemy:GetExtrapolatedLocation(stun[2]+me:getHeroVar("AbilityDelay")))
                            return true
                        end
                    end
                end
            end
            gHeroVar.HeroAttackUnit(bot, enemy, true)
            return true
        end
    end
    
    if utils.UseOrbEffect(bot) then return true end
    
    local listEnemyCreep = bot:GetNearbyCreeps(1200, true)
    local listAlliedCreep = bot:GetNearbyCreeps(1200, false)
    if #listEnemies == 1 and (#listEnemyCreep < #listAlliedCreep or #listEnemyCreep == 0) and 
        GetUnitToUnitDistance(bot, listEnemies[1]) < (bot:GetAttackRange()+bot:GetBoundingRadius()) then
        gHeroVar.HeroAttackUnit(bot, listEnemies[1], true)
        return true
    end
    
    return false
end

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

    if HarassEnemy(bot) then return end
    
    local dest = GetLocationAlongLane(CurLane, Min(1.0, frontier))
    gHeroVar.HeroMoveToLocation(bot, dest)

    if #listEnemyCreep > 0 then
        LaningState = LaningStates.MovingToPos
    end
end

local function MovingToPos(bot)
    local listAlliedCreep = bot:GetNearbyCreep(1200, false)
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
    
    if HarassEnemy(bot) then return end

    local bNeedToGoHigher = false
    local higherDest = nil
    local listEnemyCreep = bot:GetNearbyCreep(1200, true)
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

    gHeroVar.HeroMoveToLocation(bot, dest)

    LaningState = LaningStates.CSing
end

local function DenyNearbyCreeps(bot)
    local listAlliedCreep = bot:GetNearbyCreep(1200, false)
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
    local listAlliedCreep = bot:GetNearbyCreep(1200, false)
    if #listAlliedCreep == 0 then
        if not ShouldPush then
            LaningState = LaningStates.Moving
            return
        end
    end

    local listEnemyCreep = bot:GetNearbyCreep(1200, true)
    if #listEnemyCreep == 0 then
        LaningState = LaningStates.Moving
        return
    end
    
    local listEnemyTowers = bot:GetNearbyTowers(710, true)
    if #listEnemyTowers > 0 then
        gHeroVar.HeroMoveToLocation(bot, utils.VectorAway(bot:GetLocation(), listEnemyTowers[1]:GetLocation(), 710-dist))
        return
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
    
    if HarassEnemy(bot) then return end
end

local function GetBack(bot)
    if GameTime() - BackTimer < 1 then
        return true
    end

    if #listEnemies == 0 then
        return false
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
            estDmgToMe = estDmgToMe + enemy:GetEstimatedDamageToTarget(true, bot, 3.0 + stunDuration, DAMAGE_TYPE_ALL)
        end
    end
    
    if (1.15-0.15*#listAllies)*estDmgToMe > bot:GetHealth() then
        BackTimer = GameTime() + 3.0
        return true
    end

    BackTimer = -1000
    return false
end

local function StayBack(bot)
    local LaneFront = GetLaneFrontAmount(GetTeam(), CurLane, false)
    local LaneEnemyFront = GetLaneFrontAmount(utils.GetOtherTeam(), CurLane, false)
    local BackFront = Min(LaneFront, LaneEnemyFront)

    local BackPos = GetLocationAlongLane(CurLane, BackFront - 0.05)

    if #listEnemies > 0 then
        table.sort(listEnemies, function(e1, e2) return GetUnitToUnitDistance(bot, e1) < GetUnitToUnitDistance(bot, e2) end)
        if GetUnitToUnitDistance(bot, listEnemies[1]) < 700 then
            BackPos = GetLocationAlongLane(CurLane, utils.PositionAlongLane(listEnemies[1], CurLane) - 0.05)
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
    LaningState = me:getHeroVar("LaningState")
    CurLane     = me:getHeroVar("CurLane")
    LanePos     = utils.PositionAlongLane(bot, CurLane)
    ShouldPush  = me:getHeroVar("ShouldPush")

    if not bot:IsAlive() then
        LaningState = LaningStates.Moving
    end

    listEnemies = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    listAllies  = bot:GetNearbyHeroes(800, false, BOT_MODE_NONE)
end

local function SaveLaningData()
    me:setHeroVar("LaningState", LaningState)
    me:setHeroVar("ShouldPush", shouldPush)
end

function OnStart(myBot)
    me = myBot
    LaningState = LaningState.Start
    BackTimer = -1000.0
end

function OnEnd()
end

--------------------------------

local States = {
[LaningStates.Start]        = Start,
[LaningStates.Moving]       = Moving,
[LaningStates.CSing]        = CSing,
[LaningStates.MovingToPos]  = MovingToPos,
}

----------------------------------

function Think(bot)
    LoadLaningData(bot)
    
    if GetBack(bot) then
        StayBack(bot)
        return
    end

    if utils.IsBusy(bot) then return end

    --utils.myPrint("LaningState: ", LaningStatePrint(LaningState))
    States[LaningState](bot)

    SaveLaningData()
end


--------
for k,v in pairs( laning ) do _G._savedEnv[k] = v end
