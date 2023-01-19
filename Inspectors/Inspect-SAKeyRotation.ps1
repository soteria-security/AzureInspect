

$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-SAKeyRotation {
    Try {
        $storageAccounts = Get-AzStorageAccount
        $accounts = @()

        foreach ($sa in $storageAccounts){
            $keys = Get-AzStorageAccountKey -Name $sa.StorageAccountName -ResourceGroupName $sa.ResourceGroupName
            foreach ($key in $keys){
                $keyCreated = $key.CreationTime.ToShortDateString()
                $saCreated = $sa.CreationTime.ToShortDateString()
                if ($keyCreated -le $saCreated){
                    $accounts += "Storage Account: $($sa.StorageAccountName), Resource Group: $($sa.ResourceGroupName), Key Name: $($key.KeyName)"
                }
            }
        }

        if ($accounts.count -gt 0){
            return $accounts
        }
        Return $null
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

Return Inspect-SAKeyRotation