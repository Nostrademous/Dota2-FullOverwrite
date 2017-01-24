-------------------------------------------------------------------------------
--- AUTHOR: pbenologa
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

require( GetScriptDirectory().."/constants" )

-------------------------------------------------------------------------------
-- Inits
-------------------------------------------------------------------------------

M = {}

-------------------------------------------------------------------------------
-- DoT Modifiers
-------------------------------------------------------------------------------

M.DoTModifiers={
	"modifier_abyssal_underlord_firestorm_burn",
	"modifier_axe_battle_hunger",
	"modifier_bloodseeker_rupture",
	"modifier_brewmaster_fire_permanent_immolation",
	"modifier_dazzle_poison_touch",
	"modifier_disruptor_thunder_strike",
	"modifier_dragon_knight_corrosive_breath_dot",
	"modifier_earth_spirit_magnetize",
	"modifier_ember_spirit_searing_chains",
	"modifier_huskar_burning_spear_debuff",
	"modifier_ice_blast",
	"modifier_item_urn_damage",
	"modifier_jakiro_dual_breath_burn",
	"modifier_jakiro_liquid_fire_burn",
	"modifier_ogre_magi_ignite",
	"modifier_phoenix_fire_spirit_burn",
	"modifier_silencer_curse_of_the_silent",
	"modifier_venomancer_poison_sting",
	"modifier_viper_corrosive_skin",
	"modifier_warlock_shadow_word"
}

function U.HasActiveDOTDebuff(bot)
	for dot = 1, #M.DoTModifiers do
		if bot:HasModifier(M.DoTModifiers[dot]) then
			return true
		end
	end
	return false
end

-------------------------------------------------------------------------------

return U;