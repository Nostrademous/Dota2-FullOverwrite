-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- Some Functions have been copy/pasted from bot-scripting community members 
--- Including: PLATINUM_DOTA2, lenlrx
-------------------------------------------------------------------------------

U = {}

function U.GetDistance(s, t)
	--print("S1: "..s[1]..", S2: "..s[2].." :: T1: "..t[1]..", T2: "..t[2]);
	return math.sqrt((s[1]-t[1])*(s[1]-t[1]) + (s[2]-t[2])*(s[2]-t[2]));
end

function U.GetHeroName(bot)
	local sName = bot:GetUnitName();
	return string.sub(sName, 15, string.len(sName));
end

function U.Fountain(team)
	if team==TEAM_RADIANT then
		return Vector(-7093,-6542);
	end
	return Vector(7015,6534);
end

function U.NotNilOrDead(unit)
	if unit==nil then
		return false;
	end
	if unit:IsAlive() then
		return true;
	end
	return false;
end

function U.GetOtherTeam()
	if GetTeam()==TEAM_RADIANT then
		return TEAM_DIRE;
	else
		return TEAM_RADIANT;
	end
end

function U.TimePassed(prevTime, amount)
	if ( (GameTime() - prevTime) > amount ) then
		return true, GameTime();
	else
		return false, GameTime();
	end
end

function U.LevelUp(bot, AbilityPriority)
	if ( GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS and GetGameState() ~= GAME_STATE_PRE_GAME ) then return end;
	
	local ability = bot:GetAbilityByName(AbilityPriority[1]);
	
	if ( ability == nil ) then
		print( " [" .. bot:GetUnitName() .. "] FAILED AT Leveling " .. AbilityPriority[1] );
		table.remove( AbilityPriority, 1 );
		return;
	end
	
	print( " [" .. bot:GetUnitName() .. "] Contemplating " .. ability:GetName() .. " " .. ability:GetLevel() .. "/" .. ability:GetMaxLevel() );
	if ( ability:CanAbilityBeUpgraded() ) then
		print( "Ability Can Be Upgraded" );
	end
	
	if ( ability:CanAbilityBeUpgraded() and ability:GetLevel() < ability:GetMaxLevel() ) then
		bot:Action_LevelAbility(AbilityPriority[1]);
		print( " [" .. bot:GetUnitName() .. "] Leveling " .. ability:GetName() );
		table.remove( AbilityPriority, 1 );
	end
end

function U.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[U.deepcopy(orig_key)] = U.deepcopy(orig_value)
        end
        setmetatable(copy, U.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function U.clone(org)
	return {unpack(org)}
end

return U;