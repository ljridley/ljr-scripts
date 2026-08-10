# Change the ... in the brackets to your screenconnect instance code, can be found in list of apps in control panel > uninstall programs
wmic product where name="ScreenConnect Client (...)" call uninstall /nointeractive
