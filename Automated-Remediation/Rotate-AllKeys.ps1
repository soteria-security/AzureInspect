Funtcion Rotate-AllKeys {
    $storageAccounts = Get-AzStorageAccount

    foreach ($sa in $storageAccounts){
        $keys = Get-AzStorageAccountKey -Name $sa.StorageAccountName -ResourceGroupName $sa.ResourceGroupName
        foreach ($key in $keys){
            New-AzStorageAccountKey -ResourceGroupName $sa.ResourceGroupName -Name $sa.StorageAccountName -KeyName $key.KeyName
        }
    }
}

return Rotate-AllKeys