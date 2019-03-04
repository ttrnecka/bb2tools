from imagesearch import imagesearch, imagesearch_loop, pyautogui, imagesearcharea, region_grabber
import win32gui
import time
import os
import sys

TEMPLATE_PATH = "data/image_templates"

def windowEnumerationHandler(hwnd, top_windows):
    top_windows.append((hwnd, win32gui.GetWindowText(hwnd)))

def findAndActivateWindow(name):
    top_windows = []
    found = False
    
    win32gui.EnumWindows(windowEnumerationHandler, top_windows)
    for i in top_windows:
        if name in i[1].lower():
            found = True
            print('%s found - switching'%(name))
            win32gui.ShowWindow(i[0],5)
            win32gui.SetForegroundWindow(i[0])
            break
    resetCursor()
    time.sleep(0.5)
    if isMainMenu()!=True:
        print("Blood Bowl needs to be in main menu!!!")
        sys.exit()
    return found

def clickTeamManagement():
    pos = imagesearch(os.path.join(TEMPLATE_PATH, "team_mgmt.png"))
    moveToAndClick(pos[0]+10,pos[1]+10)
    imagesearch_loop(os.path.join(TEMPLATE_PATH, "my_leagues.png"),0.2)

def clickMyLeagues():
    pos = imagesearch(os.path.join(TEMPLATE_PATH, "my_leagues.png"))
    moveToAndClick(pos[0]+10,pos[1]+10)
    imagesearch_loop(os.path.join(TEMPLATE_PATH, "right.png"),0.2)

def selectLeague(image_file_name):
    #move cursor to the corner so it cancels highlighting
    resetCursor()
    while True:
        imagesearch_loop(os.path.join(TEMPLATE_PATH, "league_banner.png"),0.1,0.95)
        pos = imagesearch(os.path.join(TEMPLATE_PATH, image_file_name),0.99)
        if pos[0]!=-1:
            break
        left_arrow = imagesearch(os.path.join(TEMPLATE_PATH, "right.png"))
        moveToAndClick(left_arrow[0]+10,left_arrow[1]+10)
    moveToAndClick(pos[0]+10,pos[1]+10)

def clickPosition(position):
    moveToAndClick(position[0]+10,position[1]+10)

def nextCompetition():
    i = 0
    #move cursor to the corner so it does not mess the center pics being taken
    resetCursor()
    # wait till league settings button is visible
    imagesearch_loop(os.path.join(TEMPLATE_PATH, "league_settings.png"),0.2,0.95)
    # pick start image, it will be used to tell that we went full circle
    starting_image = region_grabber(region=(860,440,1050,480))
    starting_image.save(os.path.join(TEMPLATE_PATH, "tmp_league.png"))

    while True:
        imagesearch_loop(os.path.join(TEMPLATE_PATH, "comp_round.png"),0.1,0.95)
        image = pyautogui.screenshot()
        # ignore first competition as it is the starting one
        if i>1:
            comp = imagesearcharea(os.path.join(TEMPLATE_PATH, "tmp_league.png"), 0,0,0,0,0.999, image)
            if comp[0]!=-1:
                break
        
        yield image
        i+=1
        right_arrow = imagesearch(os.path.join(TEMPLATE_PATH, "right.png"))
        moveToAndClick(right_arrow[0]+10,right_arrow[1]+10)

def isCompWaitingForStart(comp_image):
    comp = imagesearcharea(os.path.join(TEMPLATE_PATH, "waiting_for_start.png"), 0,0,0,0,0.95, comp_image)
    if comp[0]==-1:
        return False, comp
    else:
        return True, comp

def clickBack():
    back = imagesearch_loop(os.path.join(TEMPLATE_PATH, "back.PNG"),0.1, 0.99)
    pyautogui.moveTo(back[0]+10,back[1]+10)
    back = imagesearch_loop(os.path.join(TEMPLATE_PATH, "back_active.PNG"),0.1, 0.99)
    moveToAndClick(back[0]+10,back[1]+10)

def waitUntilBackIsActive():
    imagesearch_loop(os.path.join(TEMPLATE_PATH, "start_competition_active.PNG"),0.1, 0.99)

def startComp():
    schedule = imagesearch_loop(os.path.join(TEMPLATE_PATH, "schedule_button.png"),0.1, 0.99)
    pyautogui.moveTo(schedule[0]+10,schedule[1]+10)
    schedule = imagesearch_loop(os.path.join(TEMPLATE_PATH, "schedule_button_active.png"),0.1, 0.99)
    moveToAndClick(schedule[0]+10,schedule[1]+10)

    start = imagesearch_loop(os.path.join(TEMPLATE_PATH, "start_competition.PNG"),0.1, 0.99)
    pyautogui.moveTo(start[0]+10,start[1]+10)
    start = imagesearch_loop(os.path.join(TEMPLATE_PATH, "start_competition_active.PNG"),0.1, 0.99)
    moveToAndClick(start[0]+10,start[1]+10)
    waitUntilBackIsActive()

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