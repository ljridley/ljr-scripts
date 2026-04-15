# =====================
# Dell Warranty Lookup
# =====================

# Dell TechDirect API credentials
$ClientID     = "REPLACE_WITH_CLIENT_ID"
$ClientSecret = "REPLACE_WITH_CLIENT_SECRET"

# Get Service Tag
try {
    $ServiceTag = (Get-CimInstance Win32_BIOS).SerialNumber
} catch {
    Write-Output "Not Dell"
    exit 0
}

# OAuth2 token request
$AuthUri  = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
$AuthBody = "grant_type=client_credentials"

$EncodedAuth = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes("${ClientID}:${ClientSecret}")
)

$AuthHeader = @{
    Authorization = "Basic $EncodedAuth"
}

try {
    $TokenResponse = Invoke-RestMethod `
        -Method POST `
        -Uri $AuthUri `
        -Headers $AuthHeader `
        -Body $AuthBody `
        -ContentType "application/x-www-form-urlencoded"

    $AccessToken = $TokenResponse.access_token
} catch {
    Write-Output "Dell API Auth Failed"
    exit 0
}

# Warranty lookup
$WarrantyUri = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements?servicetags=$ServiceTag"

$Headers = @{
    Authorization = "Bearer $AccessToken"
    Accept        = "application/json"
}

try {
    $WarrantyInfo = Invoke-RestMethod -Method GET -Uri $WarrantyUri -Headers $Headers

    $EndDate = (
        $WarrantyInfo.entitlements |
        Sort-Object endDate -Descending |
        Select-Object -First 1
    ).endDate
} catch {
    Write-Output "Warranty Lookup Failed"
    exit 0
}

# Final output (this is what CW RMM captures)
if ($EndDate) {
    Write-Output $EndDate
} else {
    Write-Output "Expired or Unknown"
}
