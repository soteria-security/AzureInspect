function Inspect-StorageAccountPublicAccess {
	Try {
		$storageAccts_with_public_access = @()
		
		$resourceGroups = (Get-AzResourceGroup).ResourceGroupName

		Foreach ($resource in $resourceGroups){
			$storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource

			Foreach ($account in $storageAccounts){
				$storageAccts_with_public_access += Get-AzStorageAccount -ResourceGroupName $resource -Name $account.StorageAccountName | Where-Object {$_.AllowBlobPublicAccess -eq $true}
			}
		}

			
		If ($storageAccts_with_public_access.Count -NE 0) {
			return "Storage Account: $($storageAccts_with_public_access.StorageAccountName), Resource Group: $($storageAccts_with_public_access.ResourceGroupName)"
		}
		
		return $null
	}
	Catch {
		Write-Warning "Error message: $_"
	
		$message = $_.ToString()
		$exception = $_.Exception
		$strace = $_.ScriptStackTrace
		$failingline = $_.InvocationInfo.Line
		$positionmsg = $_.InvocationInfo.PositionMessage
		$pscommandpath = $_.InvocationInfo.PSCommandPath
		$failinglinenumber = $_.InvocationInfo.ScriptLineNumber
		$scriptname = $_.InvocationInfo.ScriptName
		Write-Verbose "Write to log"
		Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
		Write-Verbose "Errors written to log"
	}
}

return Inspect-StorageAccountPublicAccess