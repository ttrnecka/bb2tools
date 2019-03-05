import bb2gui
import csv

matchups = csv.DictReader(open("matchups.csv"))

if __name__ == "__main__":    
    if bb2gui.findAndActivateWindow("blood bowl 2"):
        bb2gui.clickTeamManagement()
        bb2gui.clickMyLeagues()

        for matchup in matchups:
            bb2gui.selectLeague(matchup["league"])
            
            for comp in bb2gui.nextCompetition():
                template, pos = bb2gui.isCompTemplate(comp) 
                if template:
                    print("template - setting new competition")
                    bb2gui.clickPosition(pos)
                    bb2gui.createComp(matchup["competition"],matchup["teams"])
                    bb2gui.clickBack() 
                    break
            bb2gui.clickBack() 
        bb2gui.clickBack()
    else:
        print("Blood Bowl 2 not started")