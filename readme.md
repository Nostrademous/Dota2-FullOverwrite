
### AUTHOR: Nostrademous
### GITHUB REPO: https://github.com/Nostrademous/Dota2-FullOverwrite

This is a full bot over-write implementation. This means that for each hero 
(eventually all of them, but we start with small sample) we will implement 
a bot_\<heroName>.lua file with an implementation of the Think() function.

This is a **WORK IN PROGRESS**. I share it in the hope that other developers will 
find it useful and potentially contribute by requesting pull commits against 
this code base building a better community bot framework. 

**Contributors**
The code representing this bot codebase is largely comprised of work of the 
author and many contributors of the "Dota 2 Bot Scripting Forums" which can be 
found here: http://dev.dota2.com/forumdisplay.php?f=497

These include: lenLRX, Platinum_dota2, ironmano, Justus Mea, and many others
that I have lost track of.

Please drop me a message if you believe I have used your code and have not
given the appropriate credit.

**Code Layout:**
------------

The design intention was to largely leverage the concept of class-based 
inheritance as existant in Object Oriented Programming languagues, but in LUA.
To that end, there exists a "decision_tree.lua" base class that loosely 
defines the behavior of every bot we make by the virtue of the fact that all 
bot_\<heroName>.lua files will derive off of it. This allows the hero-specific 
files to only over-load those decision_tree.lua functions that they want the 
specific hero to handle differently, while keeping other aspects of bot 
behavior untouched.

Current Files:
--------------

* **readme.md** - this file

* **constants.lua** - constants that allow for easy use of our defined values 
	across all files
	
* **utility.lua** - many utility functions that are used by other files which 
	implement generic logic and behaviors of the bots
	
* **hero_selection.lua** - basic and very simple hero selection and lane 
	assignment for the bots. The lane assignment is only useful for not 
	implemented bot_<heroName>s as the ones that are implemented have 
	their lane assignment controlled by the ROLE they are assigned. This 
	whole file will eventually be scrapped I think for a better counter-
	picker implementation based on hero choices made by opposing team. For 
	now it's just a stepping stool to get other stuff working.
	
* **role.lua** - this assigns roles to bots based on a not-fully filled out 
	concept of what hero belongs in what role. Roles are categorized into 
	7 buckets: HardCarry, Mid, Offlane, SemiSupport, HardSupport, Jungler, 
	and Roamer. This file implements a brute-force technique for minimizing 
	role overlap by attempting to not assign more than one hero to a bucket.
	I was going to implement the Hungarian Algorithm to do this, but brute-
	forcing 80,000 possibilities if faster than doing advanced matrix math.
	The concept of roles flows down into laning for purposes of last hitting 
	and denying.
	
* **enemy_data.lua** - this was my attempt to globally track information about 
	all of our enemies based on metered updates by our bots as we have 
	vision of the heroes. Intention here is be able to predict ganks and 
	enemy hero rotations based on noticing the disappearance of the heros 
	from vision while knowing what the last values of their location, health, 
	mana, etc. where. I am aware that the API exposes GetLastSeenLocation() 
	and GetTimeSinceLastSeen() - however these don't provide the values like 
	mana & health which will help us know probabilistic reasons for why the 
	bots disappeared (e.g., low health/mana -> probably went to heal at shrine 
	or fountain -> don't be as worried). Currently the information is just 
	stored and not used in any way. TO BE FIXED! I wasn't sure how Valve calls 
	multi-bot over-writes so I made it atomic via locks. I honestly think 
	that our bots are called by a single thread though and we won't have race 
	conditions every present.

* **global_hero_data.lua** - this is a global table that allows for per-hero 
	persistant storage of variables. It is saved based on the hero's playerID.
	If a variable is retrieved via getHeroVar(<strNameOfVar>) that does not 
	exist, nil is returned. 
	
* **decision_tree.lua** - this is a start... there will be lots of things that 
	need to be fixed here and actually implemented (many place holders). 
	For now laning is in and some item-swapping when dead and rudimentary 
	retreat functionality (read below) are implemented. This is the BIG 
	KAHUNA of the majority of the bot logic. Larger concepts, like laning, 
	will have their own files and states and be tied to this file and 
	transitioned between based on the bot's foremost ACTION in actionStack. 
	In a way I'm trying to re-implement what I think Valve's Think() is doing, 
	but I have no clue really, so I'm doing what I think should be done. It 
	would be very appreciated and useful to have more people fill placeholder 
	functions out.

* **laning_generic.lua** - an implementation for laning based on role. Some 
	aspects are still completely missing like: neutral pulling, camp stacking, 
	support enemy hero zoning for safelane, etc. Additionally, while last 
	hitting and denying seem "ok" for ranged heroes, they are rather bad for 
	melee. Need to improve and change logic based on utility.lua->IsMelee() 
	in the future.
	
* **retreat_generic.lua** - implementation of retreating when taking damage 
	from tower, creeps, or heroes/overall. Calculations regarding maximum damage
    bot could take when under a perfectly overlapping stun/slow combo from enemy
    is accounted for. Logic for proper "retreat" path is we are being flanked
    is still missing.
	
* **jungling_generic.lua** - implementation for jungling is in. Bot will rotate 
    across all camps on team's side of river based on what difficulty level he can
    handle as defined by code conditoins at the time. Support for up to two 
    simultaneous junglers is in. "Retreat" code for "creep damage reasons" is 
    over-written when jungling.

* **item_usage.lua** - this implements basic and generic use of items. It is very 
	limited for now to use of clarity, salve, bottle, TPs, arcane boots (not 
	efficiently -> doesn't care about allies being in range). Needs to be 
	largely implemented still.

* **generic_item_purchase_test.lua** - this is a generic class for all hero-specific 
	item purchase files (e.g., item_purchase_lina.lua) that actually does all 
	the work of buying the item when appropriate. It is named as such to not 
	interfere with "item_purchase_generic.lua" which if exists in the bots/ 
	will over-ride all bot purchases that don't have a named file for them 
	resulting in no items being bought for "ANY" bots that don't have a specific
	hero-named lua file for item purchasing present. The hero-specific LUA files 
	now only need to define the appropriate ROLE specific table for item purchase 
	order (i.e., Mid, HardCarry, Support, etc).
	
* **bot_\<heroName>.lua** - three exist for now - Lina, Viper and Antimage. Look, 
	they are hard-coded implmenetations for now that don't build according 
	to the game state, but rather to a hardcoded ordering. This will need to 
	be largely re-written in an intelligent fashion eventually so it makes 
	choices that respond to what's happening in the game and based on the 
	makeup of enemy heroes. These heroes require supporting lua files to 
	really function: item_purchase_\<heroName>.lua and ability_usage_\<heroName>.lua
	These exist for Lina only. The existing hero files were created to demo 
	some of the possibilities of decision_tree function over-loading.
	
* other files are in support of **bot_\<heroName>** files

TODOs/FIXMEs:
-------------

Lots, we need :
- **advanced** fighting logic
- ally defend logic
- tower defend logic
- bot 5-man assembly logic
- roshan logic, etc.
- **dynamic** item purchasing for heroes 
- implement lots more heroes

Some FIXMEs are commented in code - I add them as a tag to get back to with ideas.
