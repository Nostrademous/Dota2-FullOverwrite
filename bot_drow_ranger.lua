-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )
require( GetScriptDirectory().."/item_purchase_drow_ranger" )
require ( GetScriptDirectory().."/ability_usage_drow_ranger" )
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

local DROW_RANGER_SKILL_Q = "drow_ranger_frost_arrows"
local DROW_RANGER_SKILL_W = "drow_ranger_wave_of_silence"
local DROW_RANGER_SKILL_E = "drow_ranger_trueshot"
local DROW_RANGER_SKILL_R = "drow_ranger_marksmanship"

local DROW_RANGER_ABILITY1 = "special_bonus_movement_speed_15"
local DROW_RANGER_ABILITY2 = "special_bonus_all_stats_5"
local DROW_RANGER_ABILITY3 = "special_bonus_hp_175"
local DROW_RANGER_ABILITY4 = "special_bonus_attack_speed_20"
local DROW_RANGER_ABILITY5 = "special_bonus_unique_drow_ranger_1"
local DROW_RANGER_ABILITY6 = "special_bonus_strength_14"
local DROW_RANGER_ABILITY7 = "special_bonus_unique_drow_ranger_2"
local DROW_RANGER_ABILITY8 = "special_bonus_unique_drow_ranger_3"

local DrowRangerAbilityPriority = {
	DROW_RANGER_SKILL_Q,    DROW_RANGER_SKILL_E,    DROW_RANGER_SKILL_W,    DROW_RANGER_SKILL_Q,    DROW_RANGER_SKILL_Q,
    DROW_RANGER_SKILL_R,    DROW_RANGER_SKILL_Q,    DROW_RANGER_SKILL_E,    DROW_RANGER_SKILL_E,    DROW_RANGER_ABILITY2,
    DROW_RANGER_SKILL_W,    DROW_RANGER_SKILL_R,    DROW_RANGER_SKILL_E,    DROW_RANGER_SKILL_W,    DROW_RANGER_ABILITY3,
    DROW_RANGER_SKILL_W,    DROW_RANGER_SKILL_R,    DROW_RANGER_ABILITY5,   DROW_RANGER_ABILITY8
};

local drowRangerActionStack = { [1] = constants.ACTION_NONE }

botDrow = dt:new()

function botDrow:new(o)
	o = o or dt:new(o)
	setmetatable(o, self)
	self.__index = self
	return o
end

drowRangerBot = botDrow:new{actionStack = drowRangerActionStack, abilityPriority = DrowRangerAbilityPriority}
--drowRangerBot:printInfo()

drowRangerBot.Init = false

function drowRangerBot:DoHeroSpecificInit(bot)
	self:setHeroVar("HasOrbAbility", SKILL_Q)
	self:setHeroVar("OutOfRangeCasting", -1000.0)
end

function drowRangerBot:ConsiderAbilityUse()
	ability_usage_drow_ranger.AbilityUsageThink()
end

function Think()
    local npcBot = GetBot()
	
	drowRangerBot:Think(npcBot)
	
	if npcBot:GetLevel() == 6 and not (utils.HaveItem(bot, "item_dragon_lance")) then
		drowRangerBot:DoJungle(npcBot)
	else
		drowRangerBot:DoPushLane(npcBot)
	end
end

-- We over-write DoRetreat behavior for JUNGLER Drow Ranger
function drowRangerBot:DoRetreat(bot, reason)
	-- if we got creep damage and are a JUNGLER do special stuff
    local pushing = getHeroVar("ShouldPush")
	if reason == constants.RETREAT_CREEP and 
		(self:GetAction() ~= constants.ACTION_LANING or (pushing ~= nil and pushing ~= false)) then
		-- if our health is lower than maximum( 15% health, 100 health )
		if bot:GetHealth() < math.max(bot:GetMaxHealth()*0.15, 100) then
			setHeroVar("IsRetreating", true)
			if ( self:HasAction(constants.ACTION_RETREAT) == false ) then
				self:AddAction(constants.ACTION_RETREAT)
				setHeroVar("IsInLane", false)
			end
		end
		-- if we are retreating - piggyback on retreat logic movement code
		if self:GetAction() == constants.ACTION_RETREAT then
			-- we use '.' instead of ':' and pass 'self' so it is the correct self
			return dt.DoRetreat(self, bot, 1)
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

function drowRangerBot:GetMaxClearableCampLevel(bot)
	if DotaTime() < 30 then
		return constants.CAMP_EASY
	end

	local marksmanship = bot:GetAbilityByName("drow_ranger_marksmanship")
	
	if utils.HaveItem(bot, "item_dragon_lance") and marksmanship:GetLevel() >= 1 then
		return constants.CAMP_ANCIENT
	elseif utils.HaveItem(bot, "item_power_treads") and marksmanship:GetLevel() == 1 then
		return constants.CAMP_HARD
	end

	return constants.CAMP_MEDIUM
end

-- function drowRangerBot:IsReadyToGank(bot)
    -- local frostArrow = bot:GetAbilityByName("drow_ranger_frost_arrows")
	
	-- if utils.HaveItem(bot, "item_dragon_lance") and frostArrow:GetLevel >= 4 then
		-- return true
	-- end
    -- return false -- that's all we need
-- end

function drowRangerBot:DoCleanCamp(bot, neutrals)

	local frostArrow = bot:GetAbilityByName("drow_ranger_frost_arrows")
	
	for i, neutral in ipairs(neutrals) do
		
		local eDamage = bot:GetEstimatedDamageToTarget(true, neutral, bot:GetAttackSpeed(), DAMAGE_TYPE_PHYSICAL)
		if not (eDamage > neutral:GetHealth()) then 
			
			if not (neutral:HasModifier("modifier_drow_ranger_frost_arrows_slow")) then -- TODO: add kiting when creep is to strong
				bot:Action_UseAbilityOnEntity(frostArrow, neutral);
				bot:Action_AttackUnit(neutral, true)
			end
				bot:Action_AttackUnit(neutral, true)
			break
		end
	end
end