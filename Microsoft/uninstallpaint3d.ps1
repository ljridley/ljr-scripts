# Microsoft Paint 3D Vulnerability Remediation Script
# This script detects and removes Microsoft Paint 3D to address multiple RCE vulnerabilities

# Set strict error handling
$ErrorActionPreference = "Stop"

# Initialize log file
$logFile = "C:\Windows\Temp\Paint3D_Remediation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$successMsg = "SUCCESS: Successfully removed Microsoft Paint 3D."
$failureMsg = "FAILURE: Unable to remove Microsoft Paint 3D completely."

# Function to write to log file
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
    Write-Output $message
}

Write-Log "Starting Microsoft Paint 3D vulnerability remediation process"

# Check if Paint 3D is installed
try {
    $paint3dInstalled = $false
    
    # Method 1: Check via Get-AppxPackage (for store apps)
    $paint3dApp = Get-AppxPackage -Name "*Microsoft.MSPaint*" -ErrorAction SilentlyContinue
    if ($paint3dApp) {
        $paint3dInstalled = $true
        Write-Log "Microsoft Paint 3D detected via Get-AppxPackage. Version: $($paint3dApp.Version)"
    }
    
    # Method 2: Check via WMI query (similar to your detection method)
    $paint3dWMI = Get-CimInstance -Query "SELECT * FROM Win32_InstalledStoreProgram WHERE name='Microsoft.MSPaint'" -ErrorAction SilentlyContinue
    if ($paint3dWMI) {
        $paint3dInstalled = $true
        Write-Log "Microsoft Paint 3D detected via WMI. Version: $($paint3dWMI.Version)"
    }
    
    # If Paint 3D is installed, proceed with removal
    if ($paint3dInstalled) {
        Write-Log "Vulnerable Microsoft Paint 3D detected. Beginning removal process..."
        
        # Step 1: Remove via Get-AppxPackage (primary method)
        try {
            Write-Log "Removing Microsoft Paint 3D via Remove-AppxPackage..."
            $paint3dPackages = Get-AppxPackage -Name "*Microsoft.MSPaint*" -AllUsers -ErrorAction SilentlyContinue
            if ($paint3dPackages) {
                foreach ($package in $paint3dPackages) {
                    Write-Log "Removing package: $($package.Name) - $($package.Version)"
                    Remove-AppxPackage -Package $package.PackageFullName -ErrorAction SilentlyContinue
                    
                    # If we have admin rights, also try to remove it for all users
                    if ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) {
                        Write-Log "Removing package for all users..."
                        Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction SilentlyContinue
                    }
                }
            }
        } catch {
            Write-Log "Error removing Paint 3D via Remove-AppxPackage: $_"
        }
        
        # Step 2: Remove via DISM (backup method)
        try {
            Write-Log "Attempting removal via DISM..."
            $dismResult = Invoke-Expression "DISM /Online /Get-ProvisionedAppxPackages | findstr MSPaint" -ErrorAction SilentlyContinue
            if ($dismResult) {
                $packageName = ($dismResult -split ' ')[-1]
                if ($packageName -match "Microsoft.MSPaint") {
                    Write-Log "Removing provisioned package: $packageName"
                    $removeCmd = "DISM /Online /Remove-ProvisionedAppxPackage /PackageName:$packageName"
                    Invoke-Expression $removeCmd -ErrorAction SilentlyContinue
                }
            }
        } catch {
            Write-Log "Error removing Paint 3D via DISM: $_"
        }
        
        # Step 3: Remove via PowerShell (alternative method)
        try {
            Write-Log "Attempting PowerShell app removal..."
            $removeCmd = "Get-AppxProvisionedPackage -Online | Where-Object {`$_.DisplayName -like '*Microsoft.MSPaint*'} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue"
            Invoke-Expression $removeCmd -ErrorAction SilentlyContinue
        } catch {
            Write-Log "Error removing Paint 3D via PowerShell provisioned package removal: $_"
        }
        
        # Step 4: Clean up registry entries
        try {
            Write-Log "Cleaning up registry entries..."
            $registryPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications\*Microsoft.MSPaint*",
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications\*Microsoft.MSPaint*",
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FeatureUsage\AppBadgeUpdated\*Paint 3D*"
            )
            
            foreach ($path in $registryPaths) {
                $keys = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                if ($keys) {
                    Write-Log "Found registry keys matching $path"
                    Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
                }
            }
        } catch {
            Write-Log "Error cleaning registry: $_"
        }
        
        # Step 5: Remove shortcuts and Start menu entries (as in your original script)
        try {
            Write-Log "Removing Paint 3D shortcuts..."
            $StartMenuPaths = @(
                "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
                "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
            )
            foreach ($Path in $StartMenuPaths) {
                $Paint3DShortcuts = Get-ChildItem -Path $Path -Recurse -Filter "*Paint 3D*.lnk" -ErrorAction SilentlyContinue
                foreach ($Shortcut in $Paint3DShortcuts) {
                    Write-Log "Removing shortcut: $($Shortcut.FullName)"
                    Remove-Item -Path $Shortcut.FullName -Force -ErrorAction SilentlyContinue
                }
            }
            
            # Clean up Start menu tile cache
            Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue
            Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
            
            # Force Windows to rebuild Start menu cache
            Get-ScheduledTask -TaskName "StartComponentCleanup" | Start-ScheduledTask -ErrorAction SilentlyContinue
        } catch {
            Write-Log "Error removing shortcuts: $_"
        }
        
        # Step 6: Clean up application data
        try {
            Write-Log "Cleaning up application data..."
            $appDataPaths = @(
                "$env:LOCALAPPDATA\Packages\Microsoft.MSPaint*",
                "$env:ProgramData\Microsoft\Windows\AppRepository\*Microsoft.MSPaint*"
            )
            
            foreach ($path in $appDataPaths) {
                $folders = Get-Item -Path $path -ErrorAction SilentlyContinue
                if ($folders) {
                    foreach ($folder in $folders) {
                        Write-Log "Removing folder: $($folder.FullName)"
                        Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        } catch {
            Write-Log "Error cleaning application data: $_"
        }
        
        # Verify if Paint 3D is still installed
        $paint3dStillInstalled = $false
        $verifyApp = Get-AppxPackage -Name "*Microsoft.MSPaint*" -ErrorAction SilentlyContinue
        $verifyWMI = Get-CimInstance -Query "SELECT * FROM Win32_InstalledStoreProgram WHERE name='Microsoft.MSPaint'" -ErrorAction SilentlyContinue
        
        if ($verifyApp -or $verifyWMI) {
            $paint3dStillInstalled = $true
            if ($verifyApp) {
                Write-Log "Paint 3D is still installed. Version: $($verifyApp.Version)"
            }
            if ($verifyWMI) {
                Write-Log "Paint 3D is still detected via WMI. Version: $($verifyWMI.Version)"
            }
        }
        
        if ($paint3dStillInstalled) {
            Write-Log "Microsoft Paint 3D could not be completely removed."
            Write-Log $failureMsg
            $exitCode = 1
        } else {
            Write-Log "Microsoft Paint 3D was successfully removed."
            Write-Log $successMsg
            $exitCode = 0
        }
    } else {
        Write-Log "Microsoft Paint 3D not detected. No remediation needed."
        Write-Log $successMsg
        $exitCode = 0
    }
} catch {
    Write-Log "Error during remediation process: $_"
    Write-Log $failureMsg
    $exitCode = 1
}

# Output for RMM
if ($exitCode -eq 0) {
    Write-Output "Microsoft Paint 3D vulnerability remediation completed successfully. See log at $logFile"
} else {
    Write-Error "Microsoft Paint 3D vulnerability remediation encountered issues. See log at $logFile"
}

# Return exit code for RMM
exit $exitCode
