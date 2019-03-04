import bb2gui

 
if __name__ == "__main__":
    
    if bb2gui.findAndActivateWindow("blood bowl 2"):
        #leagues
        oi_leagues = ["OI1.png","OI2.png","OI3.png","OI4.png","OI5.png","OI6.png"]
        #oi_leagues = ["tt_test.png"]
        bb2gui.clickTeamManagement()
        bb2gui.clickMyLeagues()
        for league in oi_leagues:
            bb2gui.selectLeague(league)

            #find comp to start
            for comp in bb2gui.nextCompetition():
                waiting, pos = bb2gui.isCompWaitingForStart(comp)
                if waiting:
                    print("starting")
                    bb2gui.clickPosition(pos) 
                    bb2gui.startComp()
                    bb2gui.clickBack()
                else:
                    print("not waiting for start")
            bb2gui.clickBack()
        bb2gui.clickBack()
    else:
        print("Blood Bowl 2 not started")