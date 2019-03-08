import bb2gui
import csv

matchups = csv.DictReader(open("matchups.csv", encoding='utf-8'))

def createComp(matchup): 
    created = False
    for comp in bb2gui.nextCompetition():
        template, pos = bb2gui.isCompTemplate(comp) 
        if template:
            print("template - setting new competition")
            bb2gui.clickPosition(pos)
            bb2gui.createComp(matchup["competition"],matchup["teams"])
            bb2gui.clickBack()
            created = True
            break
    return created

if __name__ == "__main__":    
    if bb2gui.findAndActivateWindow("blood bowl 2"):
        bb2gui.clickTeamManagement()
        bb2gui.clickMyLeagues()
        
        for matchup in matchups:
            matchup["teams"] = matchup["teams"].split("<>") 
            matchup["teams"] = list(map(lambda x: x.split(":"),matchup["teams"]))
            bb2gui.selectLeague(matchup["league"])
            created = False
            while not created:
                created = createComp(matchup)
            bb2gui.clickBack() 
        bb2gui.clickBack()
    else:
        print("Blood Bowl 2 not started")