

----------------------------------------------------------------------------------------------------

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
				if ( IsPlayerInHeroSelectionControl(2) )
				then
					SelectHero( 2, "npc_dota_hero_antimage" );
				end
				
				if ( IsPlayerInHeroSelectionControl(3) )
				then
					SelectHero( 3, "npc_dota_hero_riki" );
				end
				
				if ( IsPlayerInHeroSelectionControl(4) )
				then
					SelectHero( 4, "npc_dota_hero_bane" );
				end
				
				if ( IsPlayerInHeroSelectionControl(5) )
				then
					SelectHero( 5, "npc_dota_hero_bloodseeker" );
				end
				
				if ( IsPlayerInHeroSelectionControl(6) )
				then
					SelectHero( 6, "npc_dota_hero_crystal_maiden" );
				end
			elseif ( GetTeam() == TEAM_DIRE )
			then
				print( "selecting dire" );
				SelectHero( 7, "npc_dota_hero_drow_ranger" );
				SelectHero( 8, "npc_dota_hero_lich" );
				SelectHero( 9, "npc_dota_hero_juggernaut" );
				SelectHero( 10, "npc_dota_hero_mirana" );
				SelectHero( 11, "npc_dota_hero_nevermore" );
			end
		elseif ( a == GAMEMODE_1V1MID )
		then
			print ( "1V1 MID" )
			if ( GetTeam() == TEAM_RADIANT )
			then
				print( "selecting radiant" );
				SelectHero( 2, "npc_dota_hero_underlord" );
			elseif ( GetTeam() == TEAM_DIRE )
			then
				print( "selecting dire" );
				SelectHero( 7, "npc_dota_hero_drow_ranger" );
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
