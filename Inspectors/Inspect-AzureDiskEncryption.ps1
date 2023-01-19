
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-AzureDiskEncryption {
	Try {
        $results = @()

        $vmDisks = Get-AzDisk | Select-Object Name, @{n="VirtualMachine";e={($_.ManagedBy).split('/')[-1]}}, @{n="EncryptionType";e={$_.Encryption.Type}} 
        
        foreach ($disk in $vmDisks){
            If ($disk.EncryptionType -eq 'EncryptionAtRestWithPlatformKey'){
                $results += "Disk $($disk.Name) on VM $($disk.VirtualMachine) using encryption type $($disk.EncryptionType)"
            }
        }

        return $results
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

return Inspect-AzureDiskEncryption