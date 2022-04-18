function Inspect-SecurityContact {
	Try {
        $results = @()

        foreach ($subscription in @($subscriptions)){
            $securityContacts = Get-AzSecurityContact 

            if ($null -eq $securityContacts){
                $results +=  "No Security Contacts Defined for $($subscription.Name)"
            }
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
		Write-Verbose "Write to log"
		Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
		Write-Verbose "Errors written to log"
	}
}

return Inspect-SecurityContact