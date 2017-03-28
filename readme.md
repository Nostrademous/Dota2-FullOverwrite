This is a full bot over-write implementation. This means that for each hero
(eventually all of them, but we start with small sample) we will implement
a bot_&lt;heroName&gt;.lua file with an implementation of the Think() function.

This is a **WORK IN PROGRESS**. I share it in the hope that other developers will
find it useful and potentially contribute by commiting pull requests against
this code base building a better community bot framework.

**Contributors**
The code representing this bot codebase is largely comprised of work of the
author and many contributors of the "Dota 2 Bot Scripting Forums" which can be
found here: [Dota2 Dev Forum](http://dev.dota2.com/forumdisplay.php?f=497)

These include: lenLRX, Platinum_dota2, ironmano, Keithen, and many others
that I have lost track of.

Please drop me a message if you believe I have used your code and have not
given the appropriate credit.


**Getting Going:**
------------
To get going please visit [this wiki page](https://github.com/Nostrademous/Dota2-FullOverwrite/wiki/Workflow-for-Debugging-Bots) and the wiki in general.

If you want to contribute feel free to implement new heroes or improve existing code. You might want to file an issue first to make sure no one else is working on the exact same topic.

Make sure you checkout the next section (Code Layout and Common Patterns).

**We'll appreciate any contributions!**

Also: **Lua is not hard to learn, and we'll gladly help if you're stuck. You *can* dot it!**


**Code Layout and Common Patterns**
------------

The design intention was to largely leverage the concept of class-based
inheritance as existant in Object Oriented Programming languagues, but in LUA.

There are files for each hero, and at least one file for each mode (for details, see below).

If you want to store some data for a bot, do so by using `bot.<modeName>_<variableName>`.

There are not many stub files as of yet. Just copy the file that is closest to what you need and modify it.
A stub file exists for ability use at: `abilityUse/abilityUse_template.lua`

*Heroes*
-------

While every hero has some files for itself, most of the logic is defined by generic modes (see below).

**`bot_<heroName>.lua`**:
-   defines the hero's abilities (not how to use them), the skillbuild, and general stuff
-   links the heroes `abilityUse/abilityUse_<heroName>.lua`
-   calls a generic Think method, that will take care of everything.
-   overwrites some methods if needed (e.g. a specific way of clearing camps in the early game)

**`abilityUse/abilityUse_<heroName>.lua`**:
-   checks conditions ands cast spells
-   item usage is generic, no need to reimplement these

**`itemPurchase/<heroName>.lua`**:
-   defines some items the hero can buy
-   defines what items should be sold as inventory fills up
-   items after the `core` section will be updated based on how the game progresses (in the works)

*Modes*
-------
Modes contain generic concepts that can be used by every hero.

**`modes/<modeName>.lua`**:
-   `mode:Desire(bot)` is called every frame, and determines the desire of the mode to go active. If it is higher than every other modes desire, it'll become the active mod.
-   `mode:Think(bot)` is called every frame for the active mode. This is where the logic happens.
-   `mode:OnStart(bot)` and `mode:OnEnd()` are called if the active mode changes.

`modes/<modeName>_<heroName>.lua`:
-   if this file is present, it is used instead of the generic mode file. If you just need a partial overwrite, you can call the generic modes functions where needed.

Files of Interest:
--------------

*   **constants.lua** - constants that allow for easy use of our defined values
	across all files

*   **utility.lua** - many utility functions that are used by other files which
	implement generic logic and behaviors of the bots. These are separated 
	into `math functions`, `hero generic functions`, `creep functions`, 
	`courier & item related functions`, `team fight functions`, etc. Chances
	are that if we need a function to calculate something, it already exist.

*   **hero_selection.lua** - basic and very simple hero selection and lane
	assignment for the bots. The lane assignment is only useful for not
	implemented heroes as the ones that are implemented have
	their lane assignment controlled by the ROLE they are assigned. This
	whole file will eventually be scrapped I think for a better counter-
	picker implementation based on hero choices made by opposing team. For
	now it's just a stepping stool to get other stuff working.

*   **role.lua** - this assigns roles to bots based on a not-fully filled out
	concept of what hero belongs in what role. Roles are categorized into
	7 buckets: HardCarry, Mid, Offlane, SemiSupport, HardSupport, Jungler,
	and Roamer. This file implements a brute-force technique for minimizing
	role overlap by attempting to not assign more than one hero to a bucket.
	I was going to implement the Hungarian Algorithm to do this, but brute-
	forcing 80,000 possibilities if faster than doing advanced matrix math.
	The concept of roles flows down into laning for purposes of last hitting
	and denying.

*   **enemy_data.lua** - this was my attempt to globally track information about
	all of our enemies based on metered updates by our bots as we have
	vision of the heroes. Intention here is be able to predict ganks and
	enemy hero rotations based on noticing the disappearance of the heros
	from vision while knowing what the last values of their location, health,
	mana, etc. where. I am aware that the API exposes GetLastSeenLocation()
	and GetTimeSinceLastSeen() - however these don't provide the values like
	mana & health which will help us know probabilistic reasons for why the
	bots disappeared (e.g., low health/mana -> probably went to heal at shrine
	or fountain -> don't be as worried).
	
	Currently the information is just stored and not used much. TO BE FIXED!

*   **global_hero_data.lua** - this file holds custom versions of many 
    bot:GetNearby*() and bot:Action_*() that are easier to use.

    This file also defines a way to persistantly store hero-specific variables.
    This method is still in use, but not encouraged (use `bot.<variable>` instead).
    
    Previously, information was saved based on the hero's playerID using `setHeroVar("<strNameOfVar>", "<Value>")`. 
    If a variable is retrieved via `getHeroVar("<strNameOfVar>")` that does not exist, `nil` is returned.

*   **decision.lua** - this contains the core Think function for every hero. However, most of the time it'll just call a mode for the hard work.

*   **item_usage.lua** - this implements generic use of items.

*   **team_think.lua** - this is the TEAM's brain. Map control, pushing, defending, .. - it's in here. Eventually.

*   **global_game_state.lua**, **fighting.lua**, **building_status.lua** - these files are trying to keep track of team wide tasks and provide some utility functions for team wide actions

*   **debugging.lua** - this is not part of the production code, but it might come in handy if something is not working the way it's supposed to be.

TODOs/FIXMEs:
-------------
Lots, we need :
-   **advanced** fighting logic
-   bot 5-man assembly logic, general map movement
-   roshan logic, etc.
-   **dynamic** item purchasing for heroes
-   **dynamic** skill builds for heroes
-   **dynamic** hero selection for synergy and countering the opposition
-   implement lots more heroes
-   implement dealing with disappearing heroes (b/c they go invis for example)

A lot of FIXMEs/TODOs are commented in code - I add them as a tag to get back to with ideas.
