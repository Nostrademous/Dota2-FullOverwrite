
require( GetScriptDirectory().."/global_vars" )
require( GetScriptDirectory().."/locations" )
--require( GetScriptDirectory().."/ability_item_usage_templar_assassin" );

local curr_lvl = 0
local prevTime = 0

local SKILL_Q = "templar_assassin_refraction";
local SKILL_W = "templar_assassin_meld";
local SKILL_E = "templar_assassin_psi_blades";
local SKILL_R = "templar_assassin_psionic_trap";    -- Put a trap
local SKILL_D = "templar_assassin_trap";    -- Detonate closest trap to TA (You don't need to skill this one)
local SKILL_Q_SUMMON = "templar_assassin_self_trap"; -- Trap detonates itself (You don't need to skill this one)

local BotAbilityPriority = {
    SKILL_Q,    SKILL_E,    SKILL_Q,    SKILL_E,    SKILL_Q,
    SKILL_R,    SKILL_Q,    SKILL_W,    SKILL_W,    SKILL_W,
    SKILL_W,    SKILL_E,    SKILL_E,    SKILL_R,    "-1",
    "-1",       "-1",       SKILL_R,    "-1",       "-1",
    "-1",       "-1",       "-1",       "-1",       "-1"
};

function ThinkLvlupAbility(bot)

	local sNextAbility = BotAbilityPriority[1];
	
	if sNextAbility ~= "-1" then
		bot:Action_LevelAbility( sNextAbility );
	end
	
	table.remove( BotAbilityPriority, 1 );
end

function Think()
	
    local npcBot = GetBot();
	
	local checkLevel, newTime = global_vars.TimePassed(prevTime, 1.0);
	if checkLevel then
		local cLvl = global_vars.GetHeroLevel( npcBot );
		if ( cLvl > curr_lvl ) then
			ThinkLvlupAbility(npcBot);
			curr_lvl = curr_lvl + 1;
		end
	end
end
