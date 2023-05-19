
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

Function Inspect-NSGRules {
    Try {
        $results = @()
        Foreach ($NSG in (Get-AzNetworkSecurityGroup)) {
            $resourceRules = @()
            If ($null -ne ($NSG | Get-AzNetworkSecurityRuleConfig)) {
                $rules = ($NSG | Get-AzNetworkSecurityRuleConfig)
                foreach ($rule in $rules) {
                    $resourceRules += "Name: $($rule.Name); Access: $($rule.Access); Direction: $($rule.Direction); SourcePorts: $($rule.SourcePortRange); DestinationPorts: $($rule.DestinationPortRange); SourceIP: $($rule.SourceAddressPrefix); DestinationIP: $($rule.DestinationAddressPrefix)"
                }
                $result = [pscustomobject]@{
                    Name  = $NSG.Name
                    Rules = $resourceRules
                }
                $results += $result
            }
        }
    
        $allRules = @()
    
        Foreach ($value in $results) {
            $allRules += "Resource: $($value.Name); Non-default Firewall Rules: $($value.Rules)"
        }
    
        Return $allRules
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
        
Return Inspect-NSGRules