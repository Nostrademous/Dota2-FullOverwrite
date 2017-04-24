import os
import string

heroName = ''
shiftCount = 0
heroCount = 0
lineCount = 0
botDataProcessing = False
botLaningInfo = False

heroes = {}

def writeHeroDataLua(obj):
    f = open('C:\\Program Files (x86)\\Steam\\steamapps\\common\\dota 2 beta\\game\\dota\\scripts\\vscripts\\bots\\hero_data.lua', 'w')
    f.write('local X = {}\n')

    st = ''
    for heroName in heroes:
        try:
            st = '\nX.%s = {}\n' % heroName
            try:
                st = st + 'X.%s.%s = "%s"\n' % (heroName, 'Type', heroes[heroName]['Type'])
            except KeyError as e:
                print 'Error dumping [Type]: ', heroName

            indx = 0
            for ability in heroes[heroName]['Abilities']:
                st = st + 'X.%s.SKILL_%d = "%s"\n' % (heroName, indx, ability)
                indx += 1

            indx = 0
            for ability in heroes[heroName]['Talents']:
                st = st + 'X.%s.TALENT_%d = "%s"\n' % (heroName, indx, ability)
                indx += 1

            try:
                roles = heroes[heroName]['Role'].split(',')
                rolevals = heroes[heroName]['Rolelevels'].split(',')
                st = st + 'X.%s.Role = {}\n' % (heroName)
                for i in range(0, len(roles)):
                    st = st + 'X.%s.Role.%s = %s\n' % (heroName, roles[i], rolevals[i])
            except KeyError as e:
                print 'Error dumping [Role]: ', heroName

            try:
                st = st + 'X.%s.LaneInfo = {}\n' % (heroName)
                for key in heroes[heroName]['LaneInfo']:
                    st = st + 'X.%s.LaneInfo.%s = %s\n' % (heroName, key, heroes[heroName]['LaneInfo'][key])
            except KeyError as e:
                print 'Error dumping [LaneInfo]: ', heroName

            f.write(st)
        except KeyError as e:
            print 'Generic Error: ', heroName

    f.write('\nreturn X\n')
    f.close()

badHeroNames = ['npc_dota_hero_base', 'npc_dota_hero_target_dummy']

if __name__ == "__main__":
    fName = open('C:\\Program Files (x86)\\Steam\\steamapps\\common\\dota 2 beta\\game\\dota\\scripts\\npc\\npc_heroes.txt', 'r')

    content = fName.readlines()
    content = [x.strip() for x in content]
    print len(content)

    fName.close()

    for line in content:
        lineCount += 1
        name = string.find(line, "npc_dota_hero_")
        
        if name > -1 and heroName == '' and line.strip('"') not in badHeroNames and shiftCount == 1:
            heroName = line[name+14:-1]
            #print lineCount, 'Starting with', heroName
            heroCount += 1
            heroes[heroName] = {}
            heroes[heroName]['Abilities'] = []
            heroes[heroName]['Talents'] = []
            continue

        if line == '{':
            shiftCount += 1
            continue

        if line == '}':
            shiftCount -= 1

        if shiftCount == 1 and heroName != '':
            #print lineCount, 'Done with', heroName
            heroName = ''

        if shiftCount == 2 and heroName != '':

            if line[1:11] == 'Rolelevels':
                key, val = line.split()
                heroes[heroName]['Rolelevels'] = val[1:-1]
            elif line[1:5] == 'Role':
                key, val = line.split()
                heroes[heroName]['Role'] = val[1:-1]

            if line[1:8] == 'Ability' and line[1:14] != 'AbilityLayout' and line[1:15] != 'AbilityPreview' and line[1:21] != 'AbilityDraftDisabled':
                try:
                    key, val = line.split()
                    if string.find(val, "special_bonus_") >= 0:
                        heroes[heroName]['Talents'].append(val.strip('"'))
                    else:
                        heroes[heroName]['Abilities'].append(val.strip('"'))
                except ValueError as e:
                    print 'Error: ', line
                    break

            if line == '"Bot"':
                botDataProcessing = True
                continue

            if botDataProcessing:
                botDataProcessing = False

        if shiftCount == 3 and botLaningInfo:
            botLaningInfo = False

        if shiftCount == 3 and botDataProcessing:
            if line[1:9] == 'HeroType':
                heroes[heroName]['Type'] = line.split("\t",1)[1][2:-1]

            if line[1:11] == 'LaningInfo':
                heroes[heroName]['LaneInfo'] = {}
                botLaningInfo = True

        if shiftCount == 4 and botDataProcessing and botLaningInfo:
            try:
                key, val = line.split()
                heroes[heroName]['LaneInfo'][key.strip('"')] = val.strip('"')
            except ValueError as e:
                print 'Error: ', lineCount, line
                raise e

    print 'Processed %d heroes' % (heroCount)

    writeHeroDataLua(heroes)
