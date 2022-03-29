function Inspect-ContainerACL {
	$containers = @()
	
	$resourceGroups = (Get-AzResourceGroup).ResourceGroupName

	Foreach ($resource in $resourceGroups){
		$storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource
        $context = $storageAccounts.Context

		Foreach ($account in $storageAccounts){
			$containers += Get-AzStorageContainerAcl | Where-Object {$_.Context -notlike "Off"}
		}
	}

		
	If ($blobs_with_public_access.Count -NE 0) {
		return $containers
	}
	
	return $null
}

return Inspect-ContainerACL