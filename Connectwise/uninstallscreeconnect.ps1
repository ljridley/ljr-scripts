# Change the ... in the brackets to your screenconnect instance code, can be found in list of apps in control panel > uninstall programs
# Or remove brackets and put * instead to target all screenconnect instances
Get-Package -Name "ScreenConnect Client (...)" | Uninstall-Package
