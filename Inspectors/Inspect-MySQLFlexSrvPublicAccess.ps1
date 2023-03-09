
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-MySQLFlexSrvPublicAccess {
    Try {
        $results = @()
        
        $resourceGroups = (Get-AzResourceGroup).ResourceGroupName

        $privateIPRanges = '(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)'

        Foreach ($resource in $resourceGroups) {
            $servers = Get-AzMySqlFlexibleServer -ResourceGroupName $resource

            Foreach ($server in $Servers) {
                $firewallRules = Get-AzMySqlFlexibleServerFirewallRule -ResourceGroupName $resource -ServerName $server.Name

                Foreach ($rule in $firewallRules) {
                    If (($_.StartIPAddress -eq '0.0.0.0') -and ($_.EndIPAdddress -eq '255.255.255.255')) {
                        $results += "Server $($server.Name) allows ALL public IP addresses via Firewall Rule: $($rule.FirewallRuleName)"
                    }
                    Elseif (($_.StartIPAddress -notmatch $privateIPRanges) -and ($_.EndIPAdddress -notmatch $privateIPRanges)) {
                        $results += "Server $($server.Name) allows public IP addresses via Firewall Rule: $($rule.FirewallRuleName) to range $($rule.StartIPAddress) - $($rule.EndIPAdddress)"
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

return Inspect-MySQLFlexSrvPublicAccess