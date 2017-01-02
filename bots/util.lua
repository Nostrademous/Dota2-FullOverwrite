local X = {}
local vec = require(GetScriptDirectory().."/locations")
X.tableNeutralCamps = vec["tableNeutralCamps"]  -- constant - shouldn't be modified runtime use X.jungle instead
X.tableRuneSpawns = vec["tableRuneSpawns"]
----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

local function GetTimeDelta(prevTime)
	local delta = GameTime() - prevTime;
	return delta;
end

function X.TimePassed(prevTime, amount)
	if ( GetTimeDelta(prevTime) > amount ) then
		return true, GameTime();
	else
		return false, GameTime();
	end
end

function X.IsFacingEntity( hUnit, hTarget, degAccuracy )

    local degree = nil;

    -- Do we have a target?
    if(target ~= nil)
    then
        -- Get my hero and my heros target location
        local unitX = hUnit:GetLocation()[1];
        local unitY = hUnit:GetLocation()[2];
        local targetX = hTarget:GetLocation()[1];
        local targetY = hTarget:GetLocation()[2];

        local vX = (targetX-unitX);
        local vY = (targetY-unitY);

        local radians = math.atan( vX , vY );
        degree = (radians * 180 / math.pi);

        -- We adjust the angle
        degree = degree - 45; 

        if ( degree < 0 )
        then
            degree = degree + 360;
        end

        -- Time to check if the facing is good enough
        local botBoundary = degree - degAccuracy;        
        local topBoundary = degree + degAccuracy;
        local flippedBoundaries = false;

        if(botBoundary < 0)
        then
            botBoundary = botBoundary + 360;
            flippedBoundaries = true;
        end

        if(topBoundary > 360)
        then
            topBoundary = topBoundary - 360;
            flippedBoundaries = true;
        end

        if( ( flippedBoundaries and (topBoundary < unit:GetFacing() ) and ( unit:GetFacing() < botBoundary) ) or 
        ( not flippedBoundaries and (botBoundary < unit:GetFacing() ) and ( unit:GetFacing() < topBoundary) )    )
        then
            --print("is facing!");
            return true;
        end
    end

--[[
    if(degree ~= nil)
    then
        -- debug info
        print("-----------------------------")
        print("degree: ");
        print(degree);
        print("facing: ");
        print(GetBot():GetFacing());
        grades = nil;
    end]]
end

----------------------------------------------------------------------------------------------------

function X.GetXUnitsTowardsLocation( fromloc, toloc, units)
    -- Get angle
    local unitX = fromloc[1];
    local unitY = fromloc[2];
    local targetX = toloc[1];
    local targetY = toloc[2];

    local vX = (targetX-unitX);
    local vY = (targetY-unitY);

    local radians = math.atan( vX , vY );

    local point = {}
    point[1] = fromloc[1] + (math.cos(radians) * units);
    point[2] = fromloc[2] + (math.sin(radians) * units);
    return point;
end

----------------------------------------------------------------------------------------------------

function X.GetXUnitsInFront( hUnit, units)
    -- Get angle
    local unitX = hUnit:GetLocation()[1];
    local unitY = hUnit:GetLocation()[2];

    local direction = hUnit:GetFacing() * 3.1415926535 / 180;

    local point = Vector(unitX + (math.cos(direction) * units), unitY + (math.sin(direction) * units))

    return point;
end

----------------------------------------------------------------------------------------------------

-- util function for printing a table
function X.print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end


----------------------------------------------------------------------------------------------------

--function to get current hero level
function X.GetHeroLevel( npcBot )
    local respawnTable = {8, 10, 12, 14, 16, 26, 28, 30, 32, 34, 36, 46, 48, 50, 52, 54, 56, 66, 70, 74, 78,  82, 86, 90, 100};
    local nRespawnTime = npcBot:GetRespawnTime() +1 -- It gives 1 second lower values.
    for k,v in pairs (respawnTable) do
        if v == nRespawnTime then
			return k
        end
    end
	return 1
end

----------------------------------------------------------------------------------------------------

function X.NearestNeutralCamp( hUnit, tCamps )
    local closestDistance = 1000000;
    local closestCamp;
    for k,v in ipairs(tCamps) do
        if v ~= nil and GetUnitToLocationDistance( hUnit, v[VECTOR] ) < closestDistance then
            closestDistance = GetUnitToLocationDistance( hUnit, v[VECTOR] )
            closestCamp = v
            --print(closestCamp..":"..closestDistance)
        end
    end
    return closestCamp
end

----------------------------------------------------------------------------------------------------

function X.NearestRuneSpawn( hUnit, tSpawnVecs )
    local closestDistance = 1000000;
    local closestCamp;
    for k,v in ipairs(tSpawnVecs) do
        if v ~= nil and GetUnitToLocationDistance( hUnit, v ) < closestDistance then
            closestDistance = GetUnitToLocationDistance( hUnit, v )
            closestCamp = v
            --print(closestCamp..":"..closestDistance)
        end
    end
    return closestCamp
end

----------------------------------------------------------------------------------------------------

function X.DistanceToNeutrals(hUnit, largestCampType)
    local camps = {}
    local sCamps = {}
    for i,v in ipairs(vec["tableNeutralCamps"][CAMP_EASY]) do
        camps[GetUnitToLocationDistance( hUnit, v )] = v
    end
    if largestCampType == CAMP_EASY then
        for k,v in spairs(HighScore, function(t,a,b) return t[b] < t[a] end) do
            sCamps[k] = v
        end
        return camps
    end
    for i,v in ipairs(vec["tableNeutralCamps"][CAMP_MEDIUM]) do
        camps[GetUnitToLocationDistance( hUnit, v )] = v
    end
    if largestCampType == CAMP_MEDIUM then
        for k,v in spairs(HighScore, function(t,a,b) return t[b] < t[a] end) do
            sCamps[k] = v
        end
    return camps
    end
    for i,v in ipairs(vec["tableNeutralCamps"][CAMP_HARD]) do
        camps[GetUnitToLocationDistance( hUnit, v )] = v
    end
    if largestCampType == CAMP_HARD then
        for k,v in spairs(HighScore, function(t,a,b) return t[b] < t[a] end) do
            sCamps[k] = v
        end
        return camps
    end
    for i,v in ipairs(vec["tableNeutralCamps"][CAMP_ANCIENT]) do
        camps[GetUnitToLocationDistance( hUnit, v )] = v
    end

    for k,v in spairs(HighScore, function(t,a,b) return t[b] < t[a] end) do
        sCamps[k] = v
    end
    return camps
end

----------------------------------------------------------------------------------------------------

function compare(a,b)
  return a[1] < b[1]
end

----------------------------------------------------------------------------------------------------

function X.spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function X.cloneTable(t)    
  return {unpack(t)}
end

function X.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[X.deepcopy(orig_key)] = X.deepcopy(orig_value)
        end
        setmetatable(copy, X.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function X.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function X.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. X.val_to_str( k ) .. "]"
  end
end

function X.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, X.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        X.key_to_str( k ) .. "=" .. X.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

return X;