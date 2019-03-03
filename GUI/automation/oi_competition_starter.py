from imagesearch import imagesearch, imagesearch_loop, pyautogui

import win32gui
import time

def windowEnumerationHandler(hwnd, top_windows):
    top_windows.append((hwnd, win32gui.GetWindowText(hwnd)))
 
if __name__ == "__main__":
    # Brings Blood Bowl to foreground and makes it active
    results = []
    top_windows = []
    found = False
    
    win32gui.EnumWindows(windowEnumerationHandler, top_windows)
    for i in top_windows:
        if "blood bowl 2" in i[1].lower():
            found = True
            print("Blood Bowl 2 found - switching")
            win32gui.ShowWindow(i[0],5)
            win32gui.SetForegroundWindow(i[0])
            break
    if found:
        #leagues
        oi_leagues = ["OI1.png","OI2.png","OI3.png","OI4.png","OI5.png","OI6.png"]
        for league in oi_leagues:
            time.sleep(0.5)
            #team mgmt
            pos = imagesearch("team_mgmt.png")
            pyautogui.moveTo(pos[0]+10,pos[1]+10)
            pyautogui.mouseDown(); pyautogui.mouseUp()
            time.sleep(1)
            #myleagues
            pos = imagesearch("my_leagues.png")
            pyautogui.moveTo(pos[0]+10,pos[1]+10)
            pyautogui.mouseDown(); pyautogui.mouseUp()

            time.sleep(0.2)
            # find OI1
            pos = imagesearch(league,0.99)
            while pos[0]==-1:
                left_arrow = imagesearch("left.png")
                pyautogui.moveTo(left_arrow[0]+10,left_arrow[1]+10)
                pyautogui.mouseDown(); pyautogui.mouseUp()
                time.sleep(0.25)
                pos = imagesearch(league,0.99)
                print(pos)

            pyautogui.moveTo(pos[0]+10,pos[1]+10)
            pyautogui.mouseDown(); pyautogui.mouseUp()

            #find comp to start
            create_comp = imagesearch("create_competition.png")
            while create_comp[0]==-1:
                wstart = imagesearch("waiting_for_start.png")
                while wstart[0]==-1:
                    right_arrow = imagesearch("right.png")
                    pyautogui.moveTo(right_arrow[0]+10,right_arrow[1]+10)
                    pyautogui.mouseDown(); pyautogui.mouseUp()
                    time.sleep(0.2)
                    create_comp = imagesearch("create_competition.png")
                    print(create_comp)
                    if create_comp[0]!=-1:
                        break
                    wstart = imagesearch("waiting_for_start.png")
                    print(wstart)
                if create_comp[0]!=-1:
                    break
                pyautogui.moveTo(wstart[0]+10,wstart[1]+10)
                pyautogui.mouseDown(); pyautogui.mouseUp()
                time.sleep(2)

                schedule = imagesearch_loop("schedule_button.png",0.3, 0.99)
                pyautogui.moveTo(schedule[0]+10,schedule[1]+10)
                pyautogui.mouseDown(); pyautogui.mouseUp()
                time.sleep(0.5)

                start = imagesearch_loop("start_competition.PNG",0.3, 0.99)
                pyautogui.moveTo(start[0]+10,start[1]+10)
                pyautogui.mouseDown(); pyautogui.mouseUp()
                time.sleep(3)

                back = imagesearch_loop("back.PNG",1, 0.99)
                pyautogui.moveTo(back[0]+10,back[1]+10)
                pyautogui.mouseDown(); pyautogui.mouseUp()
                time.sleep(0.5)

            back = imagesearch_loop("back.PNG",1, 0.99)
            pyautogui.moveTo(back[0]+10,back[1]+10)
            pyautogui.mouseDown(); pyautogui.mouseUp()
            time.sleep(0.5)
            
            back = imagesearch_loop("back.PNG",1, 0.99)
            pyautogui.moveTo(back[0]+10,back[1]+10)
            pyautogui.mouseDown(); pyautogui.mouseUp()
            time.sleep(0.5)
        