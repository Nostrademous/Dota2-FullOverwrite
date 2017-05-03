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
    for _, mod in pairs(EulEvadeModifiers) do
        if bot:HasModifier(mod) then return true end
    end
    for _, mod in pairs(DispellableModifiers) do
        if bot:HasModifier(mod) then return true end
    end
    return false
end

local DangerousModifiers = {
    "modifier_bloodseeker_rupture"
}

function HasDangerousModifiers(hUnit)
    for _, mod in pairs(DangerousModifiers) do
        if hUnit:HasModifier(mod) then return true end
    end
    return false
end

function IsPhysicalImmune(hUnit)
    local bImmune = hUnit:IsAttackImmune() or hUnit:HasModifier("modifier_item_cyclone") or
                    hUnit:HasModifier("modifier_ghost_state") or hUnit:HasModifier("modifier_item_ethereal_blade_ethereal")
    return bImmune
end

function GetModifierRemainingDuration(hUnit, sName)
    if hUnit:HasModifier(sName) then
        return hUnit:GetModifierRemainingDuration( hUnit:GetModifierByName(sName) )
    end
    return 0
end

function GetModifierStackCount(hUnit, sName)
    if hUnit:HasModifier(sName) then
        return hUnit:GetModifierStackCount( hUnit:GetModifierByName(sName) )
    end
    return 0
end

function IsInvisible(bot)
    if bot:HasModifier("modifier_item_dustofappearance") then return false end
    if bot:HasModifier("modifier_bounty_hunter_track") then return false end
    if bot:HasModifier("modifier_slardar_amplify_damage") then return false end
    
    return bot:IsInvisible()
end

function IsTeleporting( hUnit )
    return hUnit:HasModifier("modifier_teleporting")
end

function IsRuptured(bot)
    return bot:HasModifier("modifier_bloodseeker_rupture")
end

function IsBuildingGlyphed(hBuilding)
    return hBuilding:HasModifier("modifier_fountain_glyph") or hBuilding:IsInvulnerable() or hBuilding:IsAttackImmune() or hBuilding:HasModifier("modifier_backdoor_protection")
end

function printAllMods(hUnit)
    local botModifierCount = hUnit:NumModifiers()
    if botModifierCount == 0 then return false end

    --NOTE: I don't know why, but this one is 0 indexed
    for i = 0, botModifierCount-1, 1 do
        local modName = hUnit:GetModifierName(i)
        utils.myPrint(utils.GetHeroName(hUnit), " mod ["..i.."]: ", modName)
   end
end

-------------------------------------------------------------------------------
for k,v in pairs( modifiers ) do _G._savedEnv[k] = v end
