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
	if X[pID][var] == nil then return nil end
	return X[pID][var]
end

return X