
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-SubscriptionHijacking {
    Try {
        $results = @()

        $token = ((Get-AzAccessToken -AsSecureString).token) | ConvertFrom-SecureString -AsPlainText

        $header = @{Authorization = "Bearer $($token)" }
        
        $response = (Invoke-RestMethod -Method Get -Uri 'https://management.azure.com/providers/Microsoft.Subscription/policies/default?api-version=2021-10-01' -Headers $header).Properties

        $leaveTenant = $($response.blockSubscriptionsLeavingTenant)

        $enterTenant = $($response.blockSubscriptionsIntoTenant)
        
        If (! $leaveTenant) {
            $results += "Subscription leaving AAD directory blocked: $($leaveTenant)"
        }

        If (! $enterTenant) {
            $results += "Subscription entering AAD directory blocked: $($enterTenant)"
        }

        If ((! $leaveTenant) -or (! $enterTenant)) {
            if ($response.exemptedPrincipals) {
                $results += "Exempted Users: $($response.exemptedPrincipals)"
            }
            Else {
                $results += "Exempted Users: None"
            }
        }

        If ($results) {
            return $results
        }
        Else {
            return $null
        }
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

return Inspect-SubscriptionHijacking