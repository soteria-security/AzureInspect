
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-AzureVMManagement {
    Try {
        $results = @()

        $roles = Get-AzRoleDefinition | Where-Object { $_.Actions -contains 'Microsoft.Compute/virtualMachines/*' } 
        
        foreach ($role in $roles) {
            $assignees = Get-AzRoleAssignment -RoleDefinitionId $role.Id
            If (($assignees | measure-object).count -gt 0) {
                foreach ($assignee in $assignees) {
                    $results += "Role: $($role.Name); Member: $($assignee.SignInName); Resource: $($assignee.Scope)"
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

return Inspect-AzureVMManagement