
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

$domain = @($domain)

$out_path = @($subPath)

function Inspect-AllRBACAssignment {
    Try {
        $results = 0

        $tenantID = (((Invoke-WebRequest -Uri "https://login.microsoftonline.com/$domain/.well-known/openid-configuration" -UseBasicParsing).Content | ConvertFrom-Json).token_endpoint -split '/')[3]

        $rescourceTypes = @('Microsoft.Compute/virtualMachines/extensions', 'Microsoft.Resources/templateSpecs/versions', 'Microsoft.Automation/automationAccounts/runbooks')

        $allResources = Get-AzResource  | Where-Object { $_.ResourceType -notin $rescourceTypes }

        $allResources  | ForEach-Object -Begin {
            $total = $allResources.Count
            $counter = 0
        } -Process {
            $counter++

            $progress = ($counter / $total) * 100
            
            $progressMsg = "Processing Object $counter of $total"

            $global:Resource = $_

            Try {
                $rbac = Get-AzRoleAssignment -ResourceGroupName (($_).ResourceId -split '/')[4] -ResourceName (($_).ResourceId -split '/')[((($_).ResourceId -split '/').length - 1)] -ResourceType "$((($_).ResourceId -split '/')[((($_).ResourceId -split '/').length -3)])/$((($_).ResourceId -split '/')[((($_).ResourceId -split '/').length -2)])" -ErrorAction Stop
            }
            Catch {
                Write-Warning "Failed to process $(($global:Resource).Name). Skipping...`n$($_.Exception.Message)`n$(($global:Resource).Name)`n$(($global:Resource).ResourceType)`n`n"
            }
            
            foreach ($member in $rbac) {
                $assignmentScope = ''
                $resource = ''

                If ($member.Scope -match '/providers/Microsoft.Management/managementGroups/') {
                    $assignmentScope = 'Azure Management Group (Inherited)'
                    $resource = "Tenant Root Group: $(($member.Scope -split '/')[4])"
                }
                ElseIf ($member.Scope -eq "/subscriptions/$((Get-AzContext).Subscription)") {
                    $assignmentScope = 'Subscription (Inherited)'
                    $sub = Get-AzSubscription -TenantId $tenantID -SubscriptionId ($member.Scope -split '/')[2]
                    $resource = "Subscription: $($sub.Name)"
                }
                ElseIf (($member.Scope -match "/subscriptions/$((Get-AzContext).Subscription)/resourceGroups/*") -and ($member.Scope -notmatch "/providers/Microsoft")) {
                    $assignmentScope = 'Resource Group (Inherited)'
                    $resource = "Resource Group: $($_.ResourceGroupName)"
                }
                ElseIf (($member.Scope -match "/providers/Microsoft") -and ($member.Scope -notmatch "/providers/Microsoft.Management/managementGroups")) {
                    $assignmentScope = 'Resource'
                    $value = $member.Scope -split '/'
                    $resource = "Resource: $($value)"
                }

                $result = [PSCustomObject]@{
                    Name        = $member.DisplayName
                    Account     = $member.SignInName
                    Role        = $member.RoleDefinitionName
                    Scope       = $assignmentScope
                    Resource    = $resource
                    Type        = $_.ResourceType
                    Permissions = ((Get-AzRoleDefinition -Id $member.RoleDefinitionId).Actions -join ",")
                }

                $results += 1

                $result | Export-Csv -Path "$($out_path)\All_Resource_RBAC_Assignment.csv" -NoTypeInformation -Delimiter ';' -Append
            }

            Write-Progress -Activity "Processing Azure Objects" -Status $progressMsg -PercentComplete $progress
        } -End {
            Write-Progress -Activity "Processing AD Objects" -Completed
        }

        return "$results affected objects identified. See supplemental document <i>All_Resource_RBAC_Assignment.csv</i> for additional details."
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

return Inspect-AllRBACAssignment