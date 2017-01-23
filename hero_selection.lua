-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

function Think()
	gs = GetGameState()
	print( "game state: ", gs )

	if ( gs == GAME_STATE_HERO_SELECTION )
	then
		a = GetGameMode()
		print( "game mode: ", a);

		if ( a == GAMEMODE_AP )
		then 
			print ( "All Pick" )
			if ( GetTeam() == TEAM_RADIANT )
			then
				print( "selecting radiant" );
				SelectHero( 2, "npc_dota_hero_drow_ranger" );
				SelectHero( 3, "npc_dota_hero_viper" );
				SelectHero( 4, "npc_dota_hero_bloodseeker" );
				SelectHero( 5, "npc_dota_hero_lina" );
				SelectHero( 6, "npc_dota_hero_crystal_maiden" );
			elseif ( GetTeam() == TEAM_DIRE )
			then
				print( "selecting dire" );
				SelectHero( 7, "npc_dota_hero_axe" );
				SelectHero( 8, "npc_dota_hero_lion" );
				SelectHero( 9, "npc_dota_hero_juggernaut" );
				SelectHero( 10, "npc_dota_hero_witch_doctor" );
				SelectHero( 11, "npc_dota_hero_viper" );
			end
		elseif ( a == GAMEMODE_1V1MID )
		then
			print ( "1V1 MID" )
			if ( GetTeam() == TEAM_RADIANT )
			then
				print( "selecting radiant" );
				SelectHero( 2, "npc_dota_hero_abyssal_underlord" );
			elseif ( GetTeam() == TEAM_DIRE )
			then
				print( "selecting dire" );
				SelectHero( 7, "npc_dota_hero_drow_ranger" );
			end
		end
	end
end

function UpdateLaneAssignments()
	if ( GetTeam() == TEAM_RADIANT ) then
		return {
			[1] = LANE_BOT,
			[2] = LANE_TOP,
			[3] = LANE_BOT,
			[4] = LANE_MID,
			[5] = LANE_BOT,
		};
	elseif ( GetTeam() == TEAM_DIRE ) then
		return {
			[1] = LANE_BOT,
			[2] = LANE_BOT,
			[3] = LANE_TOP,
			[4] = LANE_BOT,
			[5] = LANE_MID,
		};
	end
end