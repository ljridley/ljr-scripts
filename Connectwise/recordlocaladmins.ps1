try {
    $excluded = @(
    #Put entries here for any specific accounts/groups to exclude from the output
        "DOMAIN\example",
        "Administrator"
    )

    $users = Get-LocalGroupMember -Group "Administrators" |
        Where-Object {
            ($excluded -notcontains $_.Name) -and
            ($_.Name -notmatch "Admin") -and
            ($_.Name -notmatch "^(NT AUTHORITY|NT SERVICE)")
        } |
        Select-Object -ExpandProperty Name

    # Output as single line (best for custom field)
    $output = $users -join ","
    Write-Output $output
}
catch {
    Write-Output ""
}
