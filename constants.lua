-------------------------------------------------------------------------------
--- AUTHOR: Nostrademous
--- GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite
-------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "constants", package.seeall )

ACTION_NONE			= "ACTION_NONE"
ACTION_LANING		= "ACTION_LANING"
ACTION_RETREAT 		= "ACTION_RETREAT"
ACTION_FIGHT		= "ACTION_FIGHT"
ACTION_CHANNELING	= "ACTION_CHANNELING"
ACTION_MOVING		= "ACTION_MOVING"

ROLE_UNKNOWN 		= 0
ROLE_HARDCARRY 		= 1
ROLE_MID 			= 2
ROLE_OFFLANE 		= 3
ROLE_SEMISUPPORT 	= 4
ROLE_HARDSUPPORT 	= 5
ROLE_ROAMER 		= 6
ROLE_JUNGLER 		= 7

for k,v in pairs( constants ) do	_G._savedEnv[k] = v end