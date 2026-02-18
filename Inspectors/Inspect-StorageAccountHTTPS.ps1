# Check if Storage Accounts enforce HTTPS-only traffic
$findings = @()
Get-AzStorageAccount | Where-Object { -not $_.EnableHttpsTrafficOnly } | ForEach-Object {
    $findings += [PSCustomObject]@{
        Severity = "High"
        Resource = $_.StorageAccountName
        Finding = "Storage account does not enforce HTTPS-only traffic"
    }
}
$findings
