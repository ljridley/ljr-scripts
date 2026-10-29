# Set the location to the registry
Set-Location -Path 'HKLM:\Software\Microsoft'

# Create a new Key
Get-Item -Path 'HKLM:\Software\Microsoft' | New-Item -Name 'W10MigInfo\Diskspace Info' -Force

# Create new items with values
New-ItemProperty -Path 'HKLM:\Software\Microsoft\W10MigInfo\Diskspace Info' -Name 'usedDiskspaceCDrive' -Value "$usedDiskspaceCDrive" -PropertyType String -Force
New-ItemProperty -Path 'HKLM:\Software\Microsoft\W10MigInfo\Diskspace Info' -Name 'usedDiskSpaceDDrive' -Value "$usedDiskspaceDDrive" -PropertyType String -Force

# Get out of the Registry
Pop-Location
