
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-VMDiskEncryption {
	Try {
        $results = @()

        $virtualMachines = Get-AzVM

        foreach ($vm in $virtualMachines){
            $vmDisks = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name

            foreach ($disk in $vmDisks){
                If (($disk.OsVolumeEncrypted -eq 'NotEncrypted') -and ($disk.DataVolumesEncrypted -eq 'NotEncrypted')){
                    $results += "OS Volume and Data Volumes on VM $($vm.Name) are not encrypted."
                }
                ElseIf ($disk.OsVolumeEncrypted -eq 'NotEncrypted'){
                    $results += "OS Volume on VM $($vm.Name) is not encrypted."
                }
                ElseIf ($disk.DataVolumesEncrypted -eq 'NotEncrypted'){
                    $results += "Data Volumes on VM $($vm.Name) are not encrypted."
                }
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

return Inspect-VMDiskEncryption