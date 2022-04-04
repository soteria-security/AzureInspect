
Function Inspect-SAKeyRotation {
    $storageAccounts = Get-AzStorageAccount
    $accounts = @()

    foreach ($sa in $storageAccounts){
        $keys = Get-AzStorageAccountKey -Name $sa.StorageAccountName -ResourceGroupName $sa.ResourceGroupName
        foreach ($key in $keys){
            $keyCreated = $key.CreationTime.ToShortDateString()
            $saCreated = $sa.CreationTime.ToShortDateString()
            if ($keyCreated -le $saCreated){
                $accounts += "Storage Account: $($sa.StorageAccountName), Resource Group: $($sa.ResourceGroupName), Key Name: $($key.KeyName)"
            }
        }
    }

    if ($accounts.count -gt 0){
        return $accounts
    }
    Return $null
}

Return Inspect-SAKeyRotation