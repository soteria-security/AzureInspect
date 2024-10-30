
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-KeyVaultMonitoring {
    Try {
        $results = @()
        
        $keyVaults = Get-AzKeyVault -WarningAction SilentlyContinue

        Foreach ($vault in $keyVaults) {
            $vault = Get-AzKeyVault -VaultName $vault.VaultName -WarningAction SilentlyContinue
            
            If ($null -eq (Get-AzDiagnosticSetting -ResourceId $vault.ResourceId -WarningAction SilentlyContinue)) {
                $result = [PSCustomObject]@{
                    Vault    = $vault.VaultName
                    Location = $vault.Location
                }

                $results += $result
            }
            ElseIf (((($diagnosticSettings.Log | ConvertFrom-Json) | Where-Object { $_.categoryGroup -eq 'audit' }).enabled -eq $false) -and ((($diagnosticSettings.Log | ConvertFrom-Json) | Where-Object { $_.categoryGroup -eq 'allLogs' }).enabled -eq $false)) {
                $result = [PSCustomObject]@{
                    Vault    = $vault.VaultName
                    Location = $vault.Location
                }

                $results += $result
            }
        }

            
        If ($results.Count -NE 0) {
            $findings = @()
            foreach ($x in $results) {
                $findings += "Vault Name: $($x.Vault), Location: $($x.Location)"
            }
            return $findings
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

return Inspect-KeyVaultMonitoring