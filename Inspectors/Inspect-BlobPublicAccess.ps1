function Inspect-BlobContext {
    Try {
        $blobs = @()
        
        $resourceGroups = (Get-AzResourceGroup).ResourceGroupName

        Foreach ($resource in $resourceGroups){
            $storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource
            $context = $storageAccounts.Context

            Foreach ($account in $storageAccounts){
                $blob = Get-AzStorageContainerAcl -Context $context | Where-Object {$_.PublicAccess -eq "Blob"}

                $result = New-Object psobject
                $result | Add-Member -MemberType NoteProperty -name 'Resource Group' -Value $resource -ErrorAction SilentlyContinue
                $result | Add-Member -MemberType NoteProperty -name 'Blob' -Value $blob.Name -ErrorAction SilentlyContinue

                $blobs += $result
            }
        }

            
        If ($blobs.Count -NE 0) {
            return $blobs
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

return Inspect-BlobContext