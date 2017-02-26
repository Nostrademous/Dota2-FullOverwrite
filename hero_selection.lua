-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

local RadiantBots = {
    "npc_dota_hero_drow_ranger",
    "npc_dota_hero_crystal_maiden",
    "npc_dota_hero_bloodseeker",
    "npc_dota_hero_invoker",
    "npc_dota_hero_viper"
}

local DireBots = {
    "npc_dota_hero_axe",
    "npc_dota_hero_zuus",
    "npc_dota_hero_phantom_assassin",
    "npc_dota_hero_oracle",
    "npc_dota_hero_lion"
}

function Think()
	gs = GetGameState()
	print( "game state: ", gs )

	if ( gs == GAME_STATE_HERO_SELECTION ) then
		a = GetGameMode()

		if ( a == GAMEMODE_AP ) then
			print ( "All Pick" )
			if ( GetTeam() == TEAM_RADIANT ) then
				print( "selecting radiant" )
                local IDs = GetTeamPlayers(GetTeam())
                for index, id in pairs(IDs) do
                    if IsPlayerBot(id) then
                        SelectHero(id, RadiantBots[index])
                    end
                end
			elseif ( GetTeam() == TEAM_DIRE ) then
				print( "selecting dire" )
                local IDs = GetTeamPlayers(GetTeam())
                for index, id in pairs(IDs) do
                    if IsPlayerBot(id) then
                        SelectHero(id, DireBots[index])
                    end
                end
			end
		end
	end
end

function UpdateLaneAssignments()
	if ( GetTeam() == TEAM_RADIANT ) then
		return {
			[1] = LANE_BOT,
			[2] = LANE_BOT,
			[3] = LANE_BOT,
			[4] = LANE_MID,
			[5] = LANE_TOP,
		};
	elseif ( GetTeam() == TEAM_DIRE ) then
		return {
			[1] = LANE_BOT,
			[2] = LANE_MID,
			[3] = LANE_TOP,
			[4] = LANE_TOP,
			[5] = LANE_TOP,
		};
	end
end
