
require( GetScriptDirectory().."/global_vars" )
require( GetScriptDirectory().."/locations" )
--require( GetScriptDirectory().."/ability_item_usage_zuus" );

local curr_lvl = 0
local prevTime = 0

-- FIXME: includes "-1" at talent levels for future easy adds

local SKILL_Q = "zuus_arc_lightning";
local SKILL_W = "zuus_lightning_bolt";
local SKILL_E = "zuus_static_field";
local SKILL_R = "zuus_thundergods_wrath"; 

local BotAbilityPriority = {
	SKILL_W,    SKILL_E,    SKILL_W,    SKILL_E,    SKILL_W,
    SKILL_R,    SKILL_W,    SKILL_E,    SKILL_E,    "-1",
    SKILL_Q,    SKILL_R,    SKILL_Q,    SKILL_Q,    "-1",
    SKILL_Q,    "-1",       SKILL_R,    "-1",       "-1",
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