## Up Front Setup (Enable console and console logging):
### This will allow a hotkey (default `\`) to activate the console and will log all console output to a special file in the dota 2 directory
* Go to Steam Library
* Right click Dota 2
* Select properties
* On the General Tab, select Set Launch Options.
* Add the text inside the quotes to the options: `-console -condebug`

### Checking out your own Fork of the Repo
* [From This Link](https://github.com/Nostrademous/Dota2-FullOverwrite) Click the "Fork" Icon in the upper right.
    * This will create a clone of the repo in your own github instance (the one you are logged in as)
* Install Git for Windows (or other OS as you use)
    * [Git for Windows](https://github.com/git-for-windows/git/releases/tag/v2.12.2.windows.1) - pick appropriate architecture
    * Make sure you install the `bash` package/module as well
* Open the `bash` git application and change directory to the following location (note: this assume default install location for Dota 2): `C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\scripts\vscripts`
* Checkout from your forked repo directly into bots directory inside the `vscripts` directory you are in.
    * command: `git clone git@github.com:<YOUR GIT USERNAME>/Dota2-FullOverwrite.git bots`
    * this should create a `bots` directory inside `vscripts\` with all the files
    * at this point you are able to edit any of the *.lua files there to make changes to the bot and when you play them in the game it will have your changes

### Committing Changes & Doing Pull Requests
* If you followed the `Checking out your own Fork of the Repo` step above ...
* All your `git add`, `git commit`, `git push` commands will be against your own Fork of the repo
* Once you have a working and tested improvement/enhancement please contribute by doing a Pull Request
    * Go to [This Link](https://github.com/Nostrademous/Dota2-FullOverwrite/compare?expand=1)
    * Change the `compare:master` dropdown to your repo
    * If no conflicts exist, click the `Create pull request` button and write a comment describing it

### Staying Synced With Our Code
* If you followed all the steps thus far, you will know you have your own `fork`, but how do you get latest changes from our repo as we make improvements without having to create a new fork?
    * Create a remote upstream: [READ THIS PAGE](https://help.github.com/articles/configuring-a-remote-for-a-fork/)
    * Sync with remote upstream: [READ THIS PAGE](https://help.github.com/articles/syncing-a-fork/)

## Setting up a bot game to test your bots
* Start a lobby
* Set server location to Local Host
* Make it private (give it a name and a password and set lobby visibility to unlisted)
* Allow cheats by clicking the box
* Under Advanced Lobby Settings
    * Change Radiant and Dire Difficulty to Unfair
    * Select Fill Empty Slots with Bots
    * Select your bots "Local dev script" under Radiant or Dire bots and Select whatever the other bots are that you want to use.
* Unassign yourself from a team
* Start the game

## In Game Testing Quality of Life Adjustments
* With Console Open (`\`)
    * enable cheats by typing `sv_cheats 1`
    * use `host_timescale x.y` to speed up or slow down gameplay so you don't have to watch it all at normal speed
    * use `restart` to remake a game without having to create a new lobby
    * for other cheats in console see: [Console Cheat Commands](http://dota2.gamepedia.com/Cheats#Cheat_Commands)

## Code modules for debugging
* The "debugging.lua" module simplifies the usage of the API's DebugDraw* functions, by saving the debug data and calling the needed API functions every frame.
    * `SetBotState(name, line, text)`: writes `text` in `line` (1<=`line`<=2) of the bot's status field. `name` should be the bot's hero name.
    * `SetTeamState(category, line, text)`: writes `text` in `line` (1<=`line`<=6) of the `category`'s status field. `category` can be any string.
    * `SetCircle(name, center, r, g, b, radius)`: draws a _filled_ circle at the `center` vector and size `radius`. Color will be rgb(`r`,`g`,`b`). The name is used for updating/deleting.
    * `DeleteCircle(name)`: deletes the circle with the given `name`