
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-SubscriptionHijacking {
	Try {
        $results = @()

        $header = @{Authorization= "Bearer $((Get-AzAccessToken).token)"}
        
        $response = (Invoke-RestMethod -Uri 'https://management.azure.com/providers/Microsoft.Subscription/policies/default?api-version=2021-10-01' -Headers $header).Properties
        
        $results += "Subscription leaving AAD directory: $($response.blockSubscriptionsLeavingTenant)"

        $results += "Subscription entering AAD directory: $($response.blockSubscriptionsIntoTenant)"

        if ($response.exemptedPrincipals) {
            $results += "Exempted Users: $($response.exemptedPrincipals)"
        }
        Else {
            $results += "Exempted Users: None"
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
		Write-Verbose "Write to log"
		Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
		Write-Verbose "Errors written to log"
	}
}

return Inspect-SubscriptionHijacking