
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-VMExtensions {
    Try {
        $results = @()

        $virtualMachines = Get-AzVM

        foreach ($vm in $virtualMachines) {
            $vmExtensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name

            If ($vmExtensions) {
                $result = [PSCustomObject]@{
                    VMName    = $vm.Name
                    Extension = If (($vmExtensions | Measure-Object).Count -gt 1) { $vmExtensions.Name -join ',' }Else { $vmExtensions.Name }
                }
                $results += "Virtual Machine: $($result.VMName), Extensions: $($result.Extension)"
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

return Inspect-VMExtensions