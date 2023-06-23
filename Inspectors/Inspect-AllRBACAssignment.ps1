
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-AllRBACAssignment {
    Try {
        $results = @()

        $allResources = Get-AzResource

        Foreach ($AZresource in $allResources) {
            $rbac = Get-AzRoleAssignment -ResourceGroupName (($AZresource).ResourceId -split '/')[4] -ResourceName (($AZresource).ResourceId -split '/')[((($AZresource).ResourceId -split '/').length - 1)] -ResourceType "$((($AZresource).ResourceId -split '/')[((($AZresource).ResourceId -split '/').length -3)])/$((($AZresource).ResourceId -split '/')[((($AZresource).ResourceId -split '/').length -2)])"
            
            foreach ($member in $rbac) {
                $assignmentScope = ''
                $resource = ''

                If ($member.Scope -match '/providers/Microsoft.Management/managementGroups/') {
                    $assignmentScope = 'Azure Management Group (Inherited)'
                    $resource = "Tenant Root Group: $(($member.Scope -split '/')[4])"
                }
                ElseIf ($member.Scope -eq "/subscriptions/$((Get-AzContext).Subscription)") {
                    $assignmentScope = 'Subscription (Inherited)'
                    $sub = Get-AzSubscription -SubscriptionId ($member.Scope -split '/')[2]
                    $resource = "Subscription: $($sub.Name)"
                }
                ElseIf (($member.Scope -match "/subscriptions/$((Get-AzContext).Subscription)/resourceGroups/*") -and ($member.Scope -notmatch "/providers/Microsoft")) {
                    $assignmentScope = 'Resource Group (Inherited)'
                    $resource = "Resource Group: $($AZresource.ResourceGroupName)"
                }
                ElseIf (($member.Scope -match "/providers/Microsoft") -and ($member.Scope -notmatch "/providers/Microsoft.Management/managementGroups")) {
                    $assignmentScope = 'Resource'
                    $value = $member.Scope -split '/'
                    $resource = "Resource: $($AZresource.Name)"
                }

                $result = [PSCustomObject]@{
                    Name        = $member.DisplayName
                    Account     = $member.SignInName
                    Role        = $member.RoleDefinitionName
                    Scope       = $assignmentScope
                    Resource    = $resource
                    Type        = $AZresource.ResourceType
                    Permissions = ((Get-AzRoleDefinition -Id $member.RoleDefinitionId).Actions -join ",")
                }

                $results += $result
            }
        }

        $results | Export-Csv -Path "$(@($out_path))\All_Resource_RBAC_Assignment.csv" -NoTypeInformation

        return "$(($results | Measure-Object).Count) affected objects identified. See supplemental document <i>All_Resource_RBAC_Assignment.csv</i> for additional details."
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