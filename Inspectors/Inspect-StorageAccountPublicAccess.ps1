
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

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
			$findings = @()
            foreach ($x in $storageAccts_with_public_access){
                $findings += "Storage Account: $($x.StorageAccountName), Resource Group: $($x.ResourceGroupName)"
			}
			return $findings
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
        Write-Warning $message
        Write-Verbose "Write to log"
        Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
        Write-Verbose "Errors written to log"
	}
}

return Inspect-StorageAccountPublicAccess