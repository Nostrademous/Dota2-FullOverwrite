-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

X = {}

function X.InitHeroVar(pID)
	if X[pID] == nil then
		X[pID] = {}
	end
end

function X.SetVar(pID, var, value)
	X[pID][var] = value
end

function X.GetVar(pID, var)
	return X[pID][var]
end

function X.SetGlobalVar(var, value)
	X[var] = value
end

function X.GetGlobalVar(var)
	return X[var]
end

return X