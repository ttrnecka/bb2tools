# scans teams in teams.csv anr returns if they are found or not in BB2 api
# tt_test league is used for that

import bb2gui
import csv

teams = csv.DictReader(open("teams.csv", encoding='utf-8'))
teams_processed = []

for team in teams:
    teams_processed.append([team["coach"],team["team"]])

matchup = {
    "league": "tt_test.png",
    "competition": "team_scanner",
    "teams": teams_processed
}

def createComp(matchup): 
    created = False
    for comp in bb2gui.nextCompetition():
        template, pos = bb2gui.isCompTemplate(comp) 
        if template:
            print("template - setting scanning competition")
            bb2gui.clickPosition(pos)
            bb2gui.scanTeams(matchup["competition"],matchup["teams"])
            bb2gui.clickBack()
            created = True
            break
    return created

if __name__ == "__main__":
    
    if bb2gui.findAndActivateWindow("blood bowl 2"):
        league = "tt_test.png"
        bb2gui.clickTeamManagement()
        bb2gui.clickMyLeagues()
        bb2gui.selectLeague(league)
        #
        created = False
        while not created:
            created = createComp(matchup)
        bb2gui.clickBack()
        bb2gui.clickBack()
    else:
        print("Blood Bowl 2 not started")