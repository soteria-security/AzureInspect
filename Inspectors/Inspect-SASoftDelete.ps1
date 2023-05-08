
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-SASoftDelete {
    Try {
        $containers = @()
        
        $resourceGroups = (Get-AzResourceGroup).ResourceGroupName

        Foreach ($resource in $resourceGroups) {
            $storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource
            #$context = $storageAccounts.Context

            Foreach ($account in $storageAccounts) {
                Try {
                    $container = Get-AzStorageServiceProperty -ServiceType Blob -Context $account.Context -ErrorAction Stop | Where-Object { $_.DeleteRetentionPolicy.Enabled -eq $false }
                }
                Catch {
                    
                }
                
                foreach ($item in $container) {
                    $result = New-Object psobject
                    $result | Add-Member -MemberType NoteProperty -Name 'Account Name' -Value $account.StorageAccountName
                    $result | Add-Member -MemberType NoteProperty -name 'Resource Group' -Value $resource -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name 'Soft Delete Retention' -Value $item.DeleteRetentionPolicy.Enabled -ErrorAction SilentlyContinue

                    $containers += $result
                }
            }
        }

            
        If ($containers.Count -NE 0) {
            $findings = @()
            foreach ($x in $containers) {
                $findings += "Container Name: $($x.'Account Name'), Resource Group: $($x.'Resource Group'), Soft Delete Enabled: $($x.'Soft Delete Retention')"
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
        Write-Warning $message
        Write-Verbose "Write to log"
        Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
        Write-Verbose "Errors written to log"
    }
}

return Inspect-SASoftDelete