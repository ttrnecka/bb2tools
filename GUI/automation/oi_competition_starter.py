import bb2gui


def findAndStartComp():
    found = False
    for comp in bb2gui.nextCompetition():
        waiting, pos = bb2gui.isCompWaitingForStart(comp)
        if waiting:
            found = True
            print("starting")
            bb2gui.clickPosition(pos) 
            bb2gui.startComp()
            bb2gui.clickBack()
    return found

if __name__ == "__main__":
    
    if bb2gui.findAndActivateWindow("blood bowl 2"):
        #leagues
        oi_leagues = [
            "ReBBL Open Invitational",
            "ReBBL Open Invitational 2",
            "ReBBL Open Invitational 3",
            "ReBBL Open Invitational 4",
            "ReBBL Open Invitational 5",
            "ReBBL Open Invitational 6"
        ]
        #oi_leagues = ["TT test"]
        bb2gui.clickTeamManagement()
        bb2gui.clickMyLeagues()
        for league in oi_leagues:
            found = True
            while found:
                bb2gui.selectLeague(league)
                found = findAndStartComp()
                bb2gui.clickBack()
        bb2gui.clickBack()
    else:
        print("Blood Bowl 2 not started")