from imagesearch import imagesearch, imagesearch_loop, pyautogui, imagesearcharea, region_grabber
import win32gui
import time
import os
import sys
import logging
from pynput.keyboard import Key, Controller

TEMPLATE_PATH = "data/image_templates"

LEAGUES = {
    "TT test":"tt_test.png",
    "ReBBL Open Invitational":"OI1.png",
    "ReBBL Open Invitational 2":"OI2.png",
    "ReBBL Open Invitational 3":"OI3.png",
    "ReBBL Open Invitational 4":"OI4.png",
    "ReBBL Open Invitational 5":"OI5.png",
    "ReBBL Open Invitational 6":"OI6.png",
}

keyboard = Controller()

def windowEnumerationHandler(hwnd, top_windows):
    top_windows.append((hwnd, win32gui.GetWindowText(hwnd)))

def findAndActivateWindow(name):
    top_windows = []
    found = False
    
    win32gui.EnumWindows(windowEnumerationHandler, top_windows)
    for i in top_windows:
        if name in i[1].lower():
            found = True
            logging.info('%s found - switching'%(name))
            win32gui.ShowWindow(i[0],5)
            win32gui.SetForegroundWindow(i[0])
            break
    resetCursor()
    time.sleep(0.5)
    if isMainMenu()!=True:
        logging.error("Blood Bowl needs to be in main menu!!!")
        sys.exit()
    return found

def clickTeamManagement():
    pos = imagesearch(template("team_mgmt.png"))
    moveToAndClick(pos[0]+10,pos[1]+10)
    imagesearch_loop(template("my_leagues.png"),0.2)

def clickMyLeagues():
    pos = imagesearch(template("my_leagues.png"))
    moveToAndClick(pos[0]+10,pos[1]+10)
    imagesearch_loop(template("right.png"),0.2)

def selectLeague(name):
    if name not in LEAGUES:
        msg = f"League {name} is not defined in the list. Exiting!!!"
        pyautogui.alert(text=msg,title='',button="OK")
        logging.error(msg)
        sys.exit()
    image_file_name = LEAGUES[name]

    #move cursor to the corner so it cancels highlighting
    resetCursor()
    while True:
        imagesearch_loop(template("league_banner.png"),0.1,0.95)
        pos = imagesearch(template(image_file_name),0.99)
        if pos[0]!=-1:
            break
        left_arrow = imagesearch(template("right.png"))
        moveToAndClick(left_arrow[0]+10,left_arrow[1]+10)
    moveToAndClick(pos[0]+10,pos[1]+10)

def clickPosition(position):
    moveToAndClick(position[0]+10,position[1]+10)

# next competition generator, needs to be run inside selected league
def nextCompetition(direction="right"):
    i = 0
    #move cursor to the corner so it does not mess the center pics being taken
    resetCursor()
    # wait till league settings button is visible
    imagesearch_loop(template("league_settings.png"),0.2,0.95)
    # pick start image, it will be used to tell that we went full circle
    starting_image = region_grabber(region=(860,440,1050,480))
    starting_image.save(template("tmp_league.png"))

    while True:
        imagesearch_loop(template("comp_round.png"),0.1,0.95)
        image = pyautogui.screenshot()
        # ignore first competition as it is the starting one
        if i>1:
            comp = imagesearcharea(template("tmp_league.png"), 0,0,0,0,0.999, image)
            if comp[0]!=-1:
                break
        
        yield image
        i+=1
        right_arrow = imagesearch(template(f"{direction}.png"))
        moveToAndClick(right_arrow[0]+10,right_arrow[1]+10)

def isCompWaitingForStart(comp_image):
    comp = imagesearcharea(template("waiting_for_start.png"), 0,0,0,0,0.95, comp_image)
    if comp[0]==-1:
        return False, comp
    else:
        return True, comp

def isCompTemplate(comp_image):
    comp = imagesearcharea(template("comp_template2.png"), 0,0,0,0,0.95, comp_image)
    if comp[0]==-1:
        return False, comp
    else:
        return True, comp

def clickBack():
    clickWhenActive("back",0.99)

def clickYes():
    clickWhenActive("yes")

def startComp():
    clickWhenActive("schedule_button", 0.99)
    clickWhenActive("start_competition")

def createComp(compname,teams = []):
    clickWhenActive("new_season")
    
    # navigate to input
    inp = imagesearch_loop(template("new_season_comp_name_input.png"),0.1, 0.99)
    moveToAndClick(inp[0]+10,inp[1]+10)
    # clear it
    for _ in range(0, 24):
        pyautogui.press("backspace")

    keyboard.type(compname)
    time.sleep(1)
    
    clickYes()
    inp = imagesearch_loop(template("comp_created_msg.png"),0.1, 0.9)
    logging.info(f"Competition {compname} created")
    for team in teams:
        # navigate to teams
        clickWhenActive("teams_button")
    
        #wait till rendered
        found = False
        i = 0
        while not found:
            left_arrow = imagesearcharea(template("small_left.png"),0,0,500,500,0.9)
            if left_arrow[0]!=-1:
                found = True
        #        moveToAndClick(left_arrow[0]+1,left_arrow[1]+1)
            time.sleep(0.1)
            i+=1
            # sometimes the click is interupted by BB, if we do not get anything in 3 seconds then try it again
            if i == 30 and not found:
                clickWhenActive("teams_button")
                i = 0

        team_input = imagesearch(template("enter_team_name_text.PNG"), 0.99)
        coach_input = imagesearch(template("enter_coach_name_text.PNG"), 0.99)
        
        coach, teamname = team["coach"], team["team"]
        # fill the coach/team info while in member section

        moveToAndClick(team_input[0]+320,team_input[1])
        keyboard.type(f"%{teamname}"[0:25])
        time.sleep(1.1)
        moveToAndClick(coach_input[0]+320,coach_input[1])
        keyboard.type(coach)
        time.sleep(1.1)
        # navigate to All
        clickSmallLeft()

        # moving left to All initiates the search
        # search with coach is fast but lets wait 2 seconds just in case
        # time.sleep(2)
        
        # look for no result or invite button
        found = False

        i = 0
        while not found:
            time.sleep(0.1)
            #no_result = imagesearch(template("no_result_text.PNG"), 0.99)
            invite = imagesearcharea(template("invite_team_button.PNG"),0,0,900,550, 0.99)
            invite2 = imagesearcharea(template("invite_team_button.PNG"),900,470,1100,550, 0.99)

            if invite[0]!=-1:
                found = True
                # mutliple teams found
                if invite2[0]!=-1: 
                    logging.error(f"Found multiple teams for coach {coach} and team {teamname}")
                    break
                logging.info(f"Found team for coach {coach} and team {teamname}")
                pyautogui.moveTo(invite[0]+10,invite[1]+5)
                ns = imagesearch_loop(template("invite_team_button_active.png"),0.1, 0.99)
                moveToAndClick(ns[0]+10,ns[1]+5)
                ticket = imagesearch_loop(template("ticket_sent_msg.png"),0.1, 0.9)
                logging.info(f"Ticket sent")
                while ticket[0]!=-1:
                    ticket = imagesearch(template("ticket_sent_msg.png"), 0.9)

            else:
                i+=1

            if i == 50:
                logging.error(f"Team not found for coach {coach} and team {teamname}")
                break
            
        
        # naviagte to schedule to clear the inputs
        clickWhenActive("schedule_button")

def scanTeams(compname,teams = []):
    clickWhenActive("new_season")
    
    # navigate to input
    inp = imagesearch_loop(template("new_season_comp_name_input.png"),0.1, 0.99)
    moveToAndClick(inp[0]+10,inp[1]+10)
    # clear it
    for _ in range(0, 24):
        pyautogui.press("backspace")

    #pyautogui.typewrite(compname)
    keyboard.type(compname)
    time.sleep(1)

    clickYes()
    inp = imagesearch_loop(template("comp_created_msg.png"),0.1, 0.9)

    for team in teams:
        # navigate to teams
        clickWhenActive("teams_button")
    
        #wait till rendered
        found = False
        while not found:
            left_arrow = imagesearcharea(template("small_left.png"),0,0,500,500,0.9)
            if left_arrow[0]!=-1:
                found = True
        #        moveToAndClick(left_arrow[0]+1,left_arrow[1]+1)
            time.sleep(0.1)

        team_input = imagesearch(template("enter_team_name_text.PNG"), 0.99)
        coach_input = imagesearch(template("enter_coach_name_text.PNG"), 0.99)
        
        coach, teamname = team["coach"], team["team"]
        # fill the coach/team info while in member section

        moveToAndClick(team_input[0]+320,team_input[1])
        keyboard.type(f"%{teamname}"[0:25])
        time.sleep(1.1)
        moveToAndClick(coach_input[0]+320,coach_input[1])
        keyboard.type(coach)
        time.sleep(1.1)
        # navigate to All
        clickSmallLeft()

        # moving left to All initiates the search
        # search with coach is fast but lets wait 2 seconds just in case
        time.sleep(2)
        
        # look for no result or invite button
        found = False

        while not found:
            time.sleep(0.1)
            no_result = imagesearch(template("no_result_text.PNG"), 0.99)
            invite = imagesearcharea(template("invite_team_button.PNG"),0,0,900,600, 0.99)

            if no_result[0]!=-1:
                found = True
                #exit team loop
                print(f"Not Found: {coach}: {teamname}")
            elif invite[0]!=-1:
                found = True
                print(f"Found: {coach}: {teamname}")
        
        # naviagte to schedule to clear the inputs
        clickWhenActive("schedule_button")


def isMainMenu():
    campaign = imagesearch(os.path.join(TEMPLATE_PATH, "campaign.png"))
    if campaign[0]==-1:
        return False
    else:
        return True

def moveToAndClick(x,y):
    pyautogui.moveTo(x,y)
    click()

def click():
    pyautogui.mouseDown(); pyautogui.mouseUp()

def resetCursor():
    pyautogui.moveTo(1,1)

def template(img_file):
    return os.path.join(TEMPLATE_PATH, img_file)

def clickWhenActive(name,precision=0.99):
    # cannot user imagesearch_loop for this as the active button sometimes does nto appear after mouseover if the response from backed take a bit longer
    # finds base button
    pos1 = imagesearch(template(f"{name}.png"), precision)
    while pos1[0]==-1:
        time.sleep(0.1)
        pos1 = imagesearch(template(f"{name}.png"), precision)
    pyautogui.moveTo(pos1[0]+10,pos1[1]+10)
    # waits until the button tuns active
    pos2 = imagesearch(template(f"{name}_active.png"), precision)
    while pos2[0]==-1:
        # move mouse a bit, sometime the gui takes some time to load and the button stays inactive despite mouseover
        pyautogui.moveTo(pos1[0],pos1[1])
        pyautogui.moveTo(pos1[0]+10,pos1[1]+10)
        time.sleep(0.1)
        pos2 = imagesearch(template(f"{name}_active.png"), precision)
    moveToAndClick(pos2[0]+10,pos2[1]+10)

def clickSmallLeft():
    __clickWhenFound("small_left",0,0,750,500)

def clickSmallRight():
    __clickWhenFound("small_right",0,0,750,500)

def __clickWhenFound(name,x1=0,y1=0,x2=0,y2=0,precision=0.9):
    found = False
    while not found:
        pos = imagesearcharea(template(f"{name}.png"),x1,y1,x2,y2,precision)
        if pos[0]!=-1:
            found = True
            moveToAndClick(pos[0]+1,pos[1]+1)
        time.sleep(0.1)