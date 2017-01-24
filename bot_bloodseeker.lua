-------------------------------------------------------------------------------
--- AUTHOR: Keithen
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_bloodseeker" )
require ( GetScriptDirectory().."/ability_usage_bloodseeker" )
require( GetScriptDirectory().."/jungling_generic" )
require( GetScriptDirectory().."/constants" )

local utils = require( GetScriptDirectory().."/utility" )
local dt = require( GetScriptDirectory().."/decision_tree" )
local gHeroVar = require( GetScriptDirectory().."/global_hero_data" )

function setHeroVar(var, value)
	local bot = GetBot()
	gHeroVar.SetVar(bot:GetPlayerID(), var, value)
end

function getHeroVar(var)
	local bot = GetBot()
	return gHeroVar.GetVar(bot:GetPlayerID(), var)
end

local BLOODSEEKER_SKILL_Q = "bloodseeker_bloodrage";
local BLOODSEEKER_SKILL_W = "bloodseeker_blood_bath";
local BLOODSEEKER_SKILL_E = "bloodseeker_thirst";
local BLOODSEEKER_SKILL_R = "bloodseeker_rupture";

local BLOODSEEKER_ABILITY1 = "special_bonus_armor_5"
local BLOODSEEKER_ABILITY2 = "special_bonus_attack_damage_25"
local BLOODSEEKER_ABILITY3 = "special_bonus_attack_speed_30"
local BLOODSEEKER_ABILITY4 = "special_bonus_hp_250"
local BLOODSEEKER_ABILITY5 = "special_bonus_respawn_reduction_30"
local BLOODSEEKER_ABILITY6 = "special_bonus_all_stats_10"
local BLOODSEEKER_ABILITY7 = "special_bonus_unique_bloodseeker"
local BLOODSEEKER_ABILITY8 = "special_bonus_lifesteal_30"

local BloodseekerAbilityPriority = {
	BLOODSEEKER_SKILL_Q,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_Q,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_Q,
    BLOODSEEKER_SKILL_R,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_ABILITY2,
    BLOODSEEKER_SKILL_Q,    BLOODSEEKER_SKILL_R,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_SKILL_W,    BLOODSEEKER_ABILITY3,
    BLOODSEEKER_SKILL_E,    BLOODSEEKER_SKILL_R,    BLOODSEEKER_ABILITY5,   BLOODSEEKER_ABILITY8
};

local bloodseekerActionStack = { [1] = constants.ACTION_NONE }

botBS = dt:new()

function botBS:new(o)
	o = o or dt:new(o)
	setmetatable(o, self)
	self.__index = self
	return o
end

bloodseekerBot = botBS:new{actionStack = bloodseekerActionStack, abilityPriority = BloodseekerAbilityPriority}
--bloodseekerBot:printInfo()

bloodseekerBot.Init = false

function bloodseekerBot:ConsiderAbilityUse()
	ability_usage_bloodseeker.AbilityUsageThink()
end

function Think()
    local npcBot = GetBot()

	bloodseekerBot:Think(npcBot)
	
	if npcBot:GetLevel() == 25 and getHeroVar("Role") ~= constants.ROLE_HARDCARRY then
		setHeroVar("Role", constants.ROLE_HARDCARRY)
		setHeroVar("CurLane", LANE_BOT) --FIXME: don't hardcode this
	end
end

-- We over-write DoRetreat behavior for JUNLGER Bloodseeker
function bloodseekerBot:DoRetreat(bot, reason)
	-- if we got creep damage and are a JUNGLER do special stuff
	
	local bloodragePct = {0.25, 0.30, 0.35, 0.40}
	
    local pushing = getHeroVar("ShouldPush")
	local bloodrage = bot:GetAbilityByName("bloodseeker_bloodrage")
	local target = getHeroVar("Target")
	local estimatedDamage = bot:GetEstimatedDamageToTarget(true, target, bot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL)
	local actualDamage = target:GetActualDamage(estimatedDamage, DAMAGE_TYPE_PHYSICAL)
	local bloodrageHeal = bloodragePct[bloodrage.GetLevel()] * target:GetMaxHealth()
	local healthThreshold = math.max(bot:GetMaxHealth()*0.15, 100)
	
	if reason == constants.RETREAT_CREEP and 
		(self:GetAction() ~= constants.ACTION_LANING or (pushing ~= nil and pushing ~= false)) then
		-- if our health is lower than maximum( 15% health, 100 health )
		if bot:GetHealth() < healthThreshold then
			if (actualDamage < target:GetHealth()) and bot:GetHealth + bloodrageHeal < healthThreshold then
				setHeroVar("RetreatReason", constants.RETREAT_FOUNTAIN)
				if ( self:HasAction(constants.ACTION_RETREAT) == false ) then
					self:AddAction(constants.ACTION_RETREAT)
					setHeroVar("IsInLane", false)
				end
			end
		end
		-- if we are retreating - piggyback on retreat logic movement code
		if self:GetAction() == constants.ACTION_RETREAT then
			-- we use '.' instead of ':' and pass 'self' so it is the correct self
			return dt.DoRetreat(self, bot, getHeroVar("RetreatReason"))
		end

		-- we are not retreating, allow decision tree logic to fall through
		-- to the next level
		return false
	-- if we are not a jungler, invoke default DoRetreat behavior
	else
		-- we use '.' instead of ':' and pass 'self' so it is the correct self
		return dt.DoRetreat(self, bot, reason)
	end
end

function bloodseekerBot:GetMaxClearableCampLevel(bot)
	if DotaTime() < 30 then
		return constants.CAMP_EASY
	end

	local bloodrage = bot:GetAbilityByName("bloodseeker_bloodrage")
	if bloodrage:GetLevel() >= 4 then
		return constants.CAMP_ANCIENT
	elseif utils.HaveItem(bot, "item_iron_talon") and bloodrage:GetLevel() >= 2 then
		return constants.CAMP_HARD
	end

	return constants.CAMP_MEDIUM
end

function bloodseekerBot:IsReadyToGank(bot)
    local rupture = bot:GetAbilityByName("bloodseeker_rupture")
    return rupture:IsFullyCastable() -- that's all we need
end

function bloodseekerBot:DoCleanCamp(bot, neutrals)
	local bloodraged =  bot:HasModifier("modifier_bloodseeker_bloodrage")
	local bloodrage = bot:GetAbilityByName("bloodseeker_bloodrage")
	if not bloodraged and bloodrage:IsCooldownReady() then -- bloodrage all the time
		bot:Action_UseAbilityOnEntity(bloodrage, bot)
	end
	table.sort(neutrals, function(n1, n2) return n1:GetHealth() < n2:GetHealth() end) -- sort by health
	local it = utils.IsItemAvailable("item_iron_talon")
	if bloodraged and it ~= nil then -- we are bloodraged and have an iron talon
		local it_target = neutrals[#neutrals] -- neutral with most health
		if it_target:GetHealth() > 0.5 * it_target:GetMaxHealth() then -- is it worth it? TODO: add a absolute minimum / use it on big guys only
			bot:Action_UseAbilityOnEntity(it, it_target); -- TODO: make sure it's not an ancient!
		end
	end
	for i, neutral in ipairs(neutrals) do
		local eDamage = bot:GetEstimatedDamageToTarget(true, neutral, bot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL)
		if not (eDamage > neutral:GetHealth()) or bloodraged then -- make sure we lasthit with bloodrage on
			setHeroVar("Target", neutral)
			bot:Action_AttackUnit(neutral, true)
			break
		end
	end
	-- TODO: don't attack if we should wait on all neutrals!
end
