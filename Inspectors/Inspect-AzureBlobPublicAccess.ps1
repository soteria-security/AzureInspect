function Inspect-AzureBlobPublicAccess {
	$blobs_with_public_access = @()
	
	$resourceGroups = (Get-AzResourceGroup).ResourceGroupName

	Foreach ($resource in $resourceGroups){
		$storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource

		Foreach ($account in $storageAccounts){
			$blobs_with_public_access += Get-AzStorageAccount -ResourceGroupName $resource -Name $account.name | Where-Object {$_.AllowBlobPublicAccess -eq $true}
		}
	}

		
	If ($blobs_with_public_access.Count -NE 0) {
		return $blobs_with_public_access
	}
	
	return $null
}

return Inspect-AzureBlobPublicAccess