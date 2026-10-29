$RegPath = "HKLM:\SOFTWARE\"
$Name    = "Key Name"
$Value   = "1"

# Create the registry key if it doesn't exist
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# Create or update the registry value
New-ItemProperty `
    -Path $RegPath `
    -Name $Name `
    -Value $Value `
    -PropertyType DWord `
    -Force | Out-Null

Write-Output "Registry value configured successfully."
