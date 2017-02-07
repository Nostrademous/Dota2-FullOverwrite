-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- LARGE AMOUNT OF CODE BORROWED FROM: PLATINUM_DOTA2 (Pooya J.)
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "ability_usage_shredder", package.seeall )

local utils = require( GetScriptDirectory().."/utility");
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
	local bot = GetBot()
	gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end
function getHeroVar(var)
	local bot = GetBot()
	return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local Abilities = {
	"shredder_whirling_death",
	"shredder_timber_chain",
	"shredder_reactive_armor",
	"shredder_chakram",
	"shredder_return_chakram",
	"shredder_chakram_2",
	"shredder_return_chakram_2"
}

local UltRetTimer = -10000

local function UseQ()
	local npcBot = GetBot()
	
	local ability = npcBot:GetAbilityByName(Abilities[1])
	
	if ability == nil or not ability:IsFullyCastable() then
		return
	end
	
	local Enemies = npcBot:GetNearbyHeroes(290, true, BOT_MODE_NONE);
	if Enemies~=nil and #Enemies > 0 and npcBot:GetMana() > (100 + ability:GetManaCost()) then
		npcBot:Action_UseAbility(ability)
		return
	end
end

local function UseW(Enemy)
	local npcBot = GetBot()

	local ability = npcBot:GetAbilityByName(Abilities[2])
	if ability == nil or not ability:IsFullyCastable() then
		return false
	end
	
	if GetUnitToUnitDistance(npcBot, Enemy) > ability:GetCastRange() then
		return false
	end
	
	local hitRadios = ability:GetSpecialValueInt("chain_radius")
	
	local enemy = Enemy
	
	if GetUnitToUnitDistance(npcBot, enemy) > ability:GetCastRange() then
		return false
	end
	
	if utils.AreTreesBetween(enemy:GetLocation(), hitRadios) then
		return false
	end
	
	--find a tree behind enemy
	local bestTree = nil
	local mindis = 10000

	local trees = npcBot:GetNearbyTrees(ability:GetCastRange())
	
	for _,tree in pairs(trees) do
		local x = GetTreeLocation(tree)
		local y = npcBot:GetLocation()
		local z = enemy:GetLocation()
		
		if x ~= y then
			local a = 1
			local b = 1
			local c = 0
		
			if x.x - y.x ==0 then
				b = 0
				c = -x.x
			else
				a = -(x.y-y.y)/(x.x-y.x)
				c = -(x.y + x.x*a)
			end
		
			local d = math.abs((a*z.x+b*z.y+c)/math.sqrt(a*a+b*b))
			if d <= hitRadios and mindis > GetUnitToLocationDistance(enemy, x) and (GetUnitToLocationDistance(enemy, x) <= GetUnitToLocationDistance(npcBot, x)) then
				bestTree = tree
				mindis = GetUnitToLocationDistance(enemy, x)
			end
		end
	end
	
	if bestTree ~= nil then
		npcBot:Action_UseAbilityOnLocation(ability, GetTreeLocation(bestTree))
		return true
	end
	
	return false
end

local function UseUlt(Enemy)
	local npcBot = GetBot()
	
	local enemy = Enemy
	local ability = npcBot:GetAbilityByName(Abilities[4])
		
	if getHeroVar("Ulted") then
		return false;
	end
	
	if ability == nil or not ability:IsFullyCastable() then
		return false
	end
	
	if GetUnitToUnitDistance(enemy, npcBot) > ability:GetCastRange() then
		return false
	end
	
	local v = enemy:GetVelocity();
	local sv = utils.GetDistance(Vector(0,0), v)
	if sv > 800 then
		v = (v / sv) * enemy:GetCurrentMovementSpeed()
	end
	
	local x = npcBot:GetLocation()
	local y = enemy:GetLocation()
	
	local s = ability:GetSpecialValueFloat("speed")
	
	local a = v.x*v.x + v.y*v.y - s*s
	local b = -2*(v.x*(x.x-y.x) + v.y*(x.y-y.y))
	local c = (x.x-y.x)*(x.x-y.x) + (x.y-y.y)*(x.y-y.y)
	
	local t = math.max( (-b+math.sqrt(b*b-4*a*c))/(2*a) , (-b-math.sqrt(b*b-4*a*c))/(2*a) )
	
	local dest = (t+0.35)*v + y
	
	if GetUnitToLocationDistance(npcBot, dest) > ability:GetCastRange() or npcBot:GetMana() < (100+ability:GetManaCost()) then
		return false
	end
	
	if enemy:GetMovementDirectionStability() < 0.4 or ((not utils.IsFacingLocation(enemy, utils.Fountain(utils.GetOtherTeam()),60)) and enemy:GetHealth()/enemy:GetMaxHealth() < 0.4) then
		dest = utils.VectorTowards(y,utils.Fountain(utils.GetOtherTeam()),180);
	end
	
	local rod = utils.IsItemAvailable("item_rod_of_atos")
	if rod ~= nil and rod:IsFullyCastable() and rod:GetCastRange() < GetUnitToUnitDistance(npcBot, enemy) then
		dest = enemy:GetLocation()
		npcBot:Action_UseAbilityOnEntity(rod, enemy);
	end
	
	npcBot:Action_UseAbilityOnLocation(ability, dest);
	
	setHerovar("UltTimer", DotaTime())
	setHeroVar("Ulted", true)
	setHeroVar("UltLocation", dest)
	
	return true
end

local function RetUlt()
	local npcBot = GetBot();
	
	if getHeroVar("Ulted") == nil then
		return false
	end
	
	if not getHeroVar("Ulted") and DotaTime() - UltRetTimer > 1 then
		UltRetTimer = DotaTime()
		local ret = npcBot:GetAbilityByName(Abilities[5])
		if ret:IsFullyCastable() then
			npcBot:Action_UseAbility(ret)
		end
		return false;
	end
	
	if DotaTime() - getHeroVar("UltTimer") < 2 then
		return false
	end
	
	local Enemies = npcBot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	
	if getHeroVar("Ulted") then
		local nEn = 0
		for _,hero in pairs(Enemies) do
			if GetUnitToLocationDistance(hero, getHeroVar("UltLocation")) < 190 then
				nEn= nEn + 1
			end
		end
		if nEn == 0 or npcBot:GetMana() < 100 then
			local ret = npcBot:GetAbilityByName(Abilities[5]);
			if ret ~= nil and ret:IsFullyCastable() and (not npcBot:IsChanneling()) and (not npcBot:IsUsingAbility()) and (not npcBot:IsSilenced()) and (not npcBot:IsStunned()) then
				npcBot:Action_UseAbility(ret);
				setHeroVar("Ulted", false)
				setHeroVar("UltTimer", -10000)
				setHeroVar("UltLocation", nil)
				return true
			end
		end
		return false
	end
end

function AbilityUsageThink(nearbyEnemyHeroes, nearbyAlliedHeroes, nearbyEnemyCreep, nearbyAlliedCreep, nearbyEnemyTowers, nearbyAlliedTowers)
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end
	
	local bot = GetBot()
    if not bot:IsAlive() then return false end

    RetUlt()
    
    -- Check if we're already using an ability
    if bot:IsUsingAbility() or bot:IsChanneling() then return false end
	
	UseQ()
	
	local nEn = #nearbyEnemyHeroes
	local nAl = #nearbyAlliedHeroes

	local EnemyCreeps = npcBot:GetNearbyCreeps(1000, false)
	
	if (npcBot:GetMana()/npcBot:GetMaxMana()>0.65 or npcBot:GetMana()>700 or ((EnemyCreeps==nil or #EnemyCreeps==0) and npcBot:GetMana()/npcBot:GetMaxMana()>0.4)) 
		and npcBot:GetHealth()/npcBot:GetMaxHealth()>0.65 and Enemies~=nil and nEn-nAl<2 then
		local enemy, health = utils.GetWeakestHero(npcBot, 1200)
		if enemy ~= nil then
			if not UseUlt(enemy) then
				UseW(enemy)
			end
		end
	end
end

for k,v in pairs( ability_usage_shredder ) do _G._savedEnv[k] = v end