function Inspect-ContainerACL {
    Try {
        $containers = @()
        
        $resourceGroups = (Get-AzResourceGroup).ResourceGroupName

        Foreach ($resource in $resourceGroups){
            $storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource
            $context = $storageAccounts.Context

            Foreach ($account in $storageAccounts){
                $containers += Get-AzStorageContainerAcl -Context $context | Where-Object {$_.PublicAccess -eq "Container"}
            }
        }

            
        If ($containers.Count -NE 0) {
            return $containers.Name
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

return Inspect-ContainerACL