import bb2gui
import csv

assignmets = csv.DictReader(open("assignments.csv", encoding='utf-8'))
leagues = {}

for asgn in assignmets:
    leagues.setdefault(asgn["league"], {}).setdefault(asgn["competition"],[]).append({"coach":asgn["coach"], "team":asgn["team"]})

print(leagues)
def createComp(name,teams): 
    created = False
    for comp in bb2gui.nextCompetition():
        template, pos = bb2gui.isCompTemplate(comp) 
        if template:
            print("template - setting new competition")
            bb2gui.clickPosition(pos)
            bb2gui.createComp(name,teams)
            bb2gui.clickBack()
            created = True
            break
    return created

if __name__ == "__main__":    
    if bb2gui.findAndActivateWindow("blood bowl 2"):
        bb2gui.clickTeamManagement()
        bb2gui.clickMyLeagues()
        
        for league, data in leagues.items():
            bb2gui.selectLeague(league)

            for comp, teams in data.items():
                created = False
                while not created:
                    created = createComp(comp,teams)
            bb2gui.clickBack()
        bb2gui.clickBack()
    else:
        print("Blood Bowl 2 not started")