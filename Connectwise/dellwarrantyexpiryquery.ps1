# Enter client ID and client secret, you need to get this via Dell TechDirect API access.
$ClientID     = "YOUR_CLIENT_ID"
$ClientSecret = "YOUR_CLIENT_SECRET"

$AuthUri = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
$AuthBody = "grant_type=client_credentials"

$AuthHeader = @{
    Authorization = "Basic " + :ToBase64String(
        [Text.Encoding]::ASCII.GetBytes("$ClientID:$ClientSecret")
    )
}

$TokenResponse = Invoke-RestMethod `
    -Method POST `
    -Uri $AuthUri `
    -Headers $AuthHeader `
    -Body $AuthBody `
    -ContentType "application/x-www-form-urlencoded"

$AccessToken = $TokenResponse.access_token

$ServiceTag = (Get-CimInstance Win32_BIOS).SerialNumber

$Headers = @{
    Authorization = "Bearer $AccessToken"
    Accept        = "application/json"
}

$WarrantyUri = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements?servicetags=$ServiceTag"

$WarrantyInfo = Invoke-RestMethod -Method GET -Uri $WarrantyUri -Headers $Headers

$EndDate = (
    $WarrantyInfo.entitlements |
    Sort-Object endDate -Descending |
    Select-Object -First 1
).endDate

Write-Output $EndDate
