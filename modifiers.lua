-------------------------------------------------------------------------------
--- AUTHOR: pbenologa, Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "modifiers", package.seeall )

local utils = require( GetScriptDirectory().."/utility" )

-------------------------------------------------------------------------------
-- Inits
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- DoT Modifiers
-------------------------------------------------------------------------------

local DoTModifiers={
    "modifier_abyssal_underlord_firestorm_burn",
    "modifier_axe_battle_hunger",
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

function HasActiveDOTDebuff(bot)
    local botModifierCount = bot:NumModifiers()
    if botModifierCount == 0 then return false end

    --NOTE: I don't know why, but this one is 0 indexed
    for i = 0, botModifierCount-1, 1 do
        local modName = bot:GetModifierName(i)
        if utils.InTable(DoTModifiers, modName) then
            return true
        end
    end

    --[[
    for i = 1, #DoTModifiers do
        if bot:HasModifier(DoTModifiers[i]) then return true end
    end
    --]]

    return false
end

local DispellableModifiers = {
    "modifier_bounty_hunter_track",
    "modifier_slardar_amplify_damage"
}

local EulEvadeModifiers = {
    "modifier_sniper_assassinate",
    "modifier_ice_blast" -- AA ult shatter
}

function HasEulModifier(bot)
    local botModifierCount = bot:NumModifiers()
    if botModifierCount == 0 then return false end
    
    for i = 0, botModifierCount-1, 1 do
        local modName = bot:GetModifierName(i)
        
        if utils.InTable(EulEvadeModifiers, modName) then
            if GetModifierRemainingDuration(i) < 2.0 then
                return true
            end
        end
        
        if utils.InTable(DispellableModifiers, modName) then
            return true
        end
    end
    
    return false
end

function IsInvisible(bot)
    return bot:HasModifier("modifier_invisible")
end

function IsRuptured(bot)
    return bot:HasModifier("modifier_bloodseeker_rupture")
end

-------------------------------------------------------------------------------
for k,v in pairs( modifiers ) do _G._savedEnv[k] = v end
