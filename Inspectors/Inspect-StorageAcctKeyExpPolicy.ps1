
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-StorageAcctKeyExpPolicy {
    Try {
        $results = @()
        
        $resourceGroups = (Get-AzResourceGroup).ResourceGroupName

        Foreach ($resource in $resourceGroups) {
            $storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource
            #$context = $storageAccounts.Context

            Foreach ($account in $storageAccounts) {
                $sAcct = Get-AzStorageAccount -ResourceGroupName $resource -Name $account.StorageAccountName

                If ($null -ne $sAcct.KeyPolicy) {
                    $keys = Get-AzStorageAccountKey -Name $account.StorageAccountName -ResourceGroupName $account.ResourceGroupName

                    $KeyExpirationPeriodInDays = $sAcct.KeyPolicy.KeyExpirationPeriodInDays

                    $expiredKeys = @()

                    foreach ($key in $keys) {
                        $keyCreated = $key.CreationTime.ToShortDateString()

                        If ($keyCreated -ge ((Get-Date).AddDays(-$KeyExpirationPeriodInDays))) {
                            $expiredKeys += "$($Key.KeyName) is expired."
                        }
                    }

                    $result = @{
                        AccountName               = $sAcct.StorageAccountName
                        KeyExpirationPeriodInDays = $sAcct.KeyPolicy.KeyExpirationPeriodInDays
                    }

                    $results += $result

                    If ($null -ne $expiredKeys) {
                        Foreach ($expKey in $expiredKeys) {
                            $results += $expKey
                        }
                    }
                }
            }
        }

            
        If ($null -ne $results) {
            return $results
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

return Inspect-StorageAcctKeyExpPolicy