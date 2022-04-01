function Inspect-ContainerACL {
    Try {
        $containers = @()
        
        $resourceGroups = (Get-AzResourceGroup).ResourceGroupName

        Foreach ($resource in $resourceGroups){
            $storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource
            $context = $storageAccounts.Context

            Foreach ($account in $storageAccounts){
                $container = Get-AzStorageContainerAcl -Context $context | Where-Object {$_.PublicAccess -eq "Container"}
                
                foreach ($item in $container) {
                    $result = New-Object psobject
                    $result | Add-Member -MemberType NoteProperty -name 'Resource Group' -Value $resource -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name 'Container' -Value $item.Name -ErrorAction SilentlyContinue

                    $containers += $result
                }
            }
        }

            
        If ($containers.Count -NE 0) {
            $findings = @()
            foreach ($x in $containers) {
                $findings += "Container Name: $($x.Container), Resource Group: $($x.'Resource Group')"
            }
            Return $findings
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