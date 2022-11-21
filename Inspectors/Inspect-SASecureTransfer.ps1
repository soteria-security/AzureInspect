
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-SASecureTransfer {
    $storageAccounts = Get-AzStorageAccount
    $accounts = @()

    foreach ($sa in $storageAccounts){
        if ($keyCreated -le $saCreated){
            $accounts += "Storage Account: $($sa.StorageAccountName), Resource Group: $($sa.ResourceGroupName), Key Name: $($key.KeyName)"
        }
    }

    if ($accounts.count -gt 0){
        return $accounts
    }
    Return $null
}

Return Inspect-SASecureTransfer