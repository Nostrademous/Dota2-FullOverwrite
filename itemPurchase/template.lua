-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

BotsInit = require( "game/botsinit" )
local thisBot = BotsInit.CreateGeneric()

local generic = dofile( GetScriptDirectory().."/itemPurchase/generic" )

-- Implement the appropriate Role-based Item Purchases from below
--generic.ItemsToBuyAsHardCarry = {}
--generic.ItemsToBuyAsMid = {}
--generic.ItemsToBuyAsOfflane = {}
--generic.ItemsToBuyAsSupport = {}
--generic.ItemsToBuyAsJungler = {}
--generic.ItemsToBuyAsRoamer = {}

-- This is the form form implementing
generic.ItemsToBuyAsJungler = {
    StartingItems = {
    },
    UtilityItems = {
    },
    CoreItems = {
    },
    ExtensionItems = {
        OffensiveItems = {
        },
        DefensiveItems = {
        }
    },
    SellItems = {
    }
}

-------------------------------------------------------------------------------
--- DO NOT MODIFY CODE BELOW HERE
-------------------------------------------------------------------------------
function thisBot:Init()
    generic:InitTable()
end

function thisBot:GetPurchaseOrder()
    return generic:GetPurchaseOrder()
end

function thisBot:UpdateTeamBuyList(sItem)
    generic:UpdateTeamBuyList( sItem )
end

function thisBot:ItemPurchaseThink(bot)
    generic:Think(bot)
end

return thisBot
