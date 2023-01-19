
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-K8httpApplicationRouting {
    Try {
        $results = @()
        
        $clusters = Get-AzAksCluster -WarningAction SilentlyContinue

        Foreach ($cluster in $clusters){
            If ($cluster.addonprofiles.keys -contains "httpApplicationRouting"){
                $result = New-Object psobject
                $result | Add-Member -MemberType NoteProperty -name 'Cluster' -Value $cluster.Name -ErrorAction SilentlyContinue
                $result | Add-Member -MemberType NoteProperty -name 'Location' -Value $Cluster.Location -ErrorAction SilentlyContinue

                $results += $result
            }
        }

            
        If ($results.Count -NE 0) {
            $findings = @()
            foreach ($x in $results){
                $findings += "Cluster Name: $($x.Cluster), Location: $($x.Location)"
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

return Inspect-K8httpApplicationRouting