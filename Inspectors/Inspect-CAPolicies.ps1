$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

$path = "$(@($out_path))\Subscription_$((Get-AZContext).Subscription.Name)"
function Inspect-CAPolicies {
    Try {
        $tenantLicense = (Get-MgSubscribedSku).ServicePlans
        
        If ($tenantLicense.ServicePlanName -match "AAD_PREMIUM*") {
            
            $conditionalAccess = Get-MgIdentityConditionalAccessPolicy  | Where-Object {($_.conditions.applications.includeapplications -contains '797f4846-ba00-4fd7-ba43-dac1f8f63013') -or ($_.conditions.applications.includeapplications -eq 'All')}

            If ($conditionalAccess.count -eq 0) {
                return "No Conditional Access Policies that restrict access to Azure Management API"
            }
            else {
                $caPath = New-Item -ItemType Directory -Force -Path "$path\ConditionalAccess-JSON"

                If (Test-Path $caPath) {
                    Write-Host "$caPath created successfully."
                }
                Else {
                    Write-Host "$caPath was not created."
                    Break
                }
                
                Foreach ($policy in $conditionalAccess) {

                    $name = $policy.DisplayName

                    $pattern = '[\\\[\]\{\}/():;\*\"#<>\$&+!`|=\?@\s'']'

                    $name = $name -replace $pattern, '-'

                    $IncludedUsers = @()

                    $ExcludedUsers = @()

                    $IncludedGroups = @()

                    $ExcludedGroups = @()

                    $IncludedRoles = @()

                    $ExcludedRoles = @()
                    
                    $IncludedApps = @()

                    $ExcludedApps = @()

                    If ($policy.conditions.users.includeusers -eq "All") {
                        $IncludedUsers = "All"
                        }
                    Elseif ($policy.conditions.users.includeusers -eq "None") {
                        $IncludedUsers = "None"
                        }
                    Elseif ($policy.conditions.users.includeusers -eq "GuestsOrExternalUsers") {
                        $IncludedUsers = "GuestsOrExternalUsers"
                        }
                    Elseif ($policy.conditions.users.includeusers) {
                        Foreach ($id in ($policy.conditions.users.includeusers)) {
                            $IncludedUsers += (Get-MgDirectoryObject -DirectoryObjectId $id).AdditionalProperties.displayName
                        }
                    }

                    If ($policy.conditions.users.excludeusers -eq "All") {
                        $ExcludedUsers = "All"
                        }
                    Elseif ($policy.conditions.users.excludeusers -eq "None") {
                        $ExcludedUsers = "None"
                        }
                    Elseif ($policy.conditions.users.excludeusers -eq "GuestsOrExternalUsers") {
                        $ExcludedUsers = "GuestsOrExternalUsers"
                        }
                    Elseif ($policy.conditions.users.excludeusers) {
                        Foreach ($id in ($policy.conditions.users.excludeusers)) {
                            $ExcludedUsers += (Get-MgDirectoryObject -DirectoryObjectId $id).AdditionalProperties.displayName
                        }
                    }
                    
                    If ($policy.conditions.users.includegroups -eq "All") {
                        $IncludedGroups = "All"
                        }
                    Elseif ($policy.conditions.users.includegroups) {
                        Foreach ($id in ($policy.conditions.users.includegroups)) {
                            $IncludedGroups = (Get-MgDirectoryObject -DirectoryObjectId $id).AdditionalProperties.displayName
                        }
                    }
                    
                    If ($policy.conditions.users.excludegroups -eq "All") {
                        $ExcludedGroups = "All"
                        }
                    Elseif ($policy.conditions.users.excludegroups) {
                        Foreach ($id in ($policy.conditions.users.excludegroups)) {
                            $ExcludedGroups = (Get-MgDirectoryObject -DirectoryObjectId $id).AdditionalProperties.displayName
                        }
                    }
                    
                    If ($policy.conditions.users.includeroles -eq "All") {
                        $IncludedRoles = "All"
                        }
                    Elseif ($policy.conditions.users.includeroles) {
                        Foreach ($id in ($policy.conditions.users.includeroles)) {
                            $IncludedRoles = (Get-MgDirectoryObject -DirectoryObjectId $id).AdditionalProperties.displayName
                        }
                    }
                    
                    If ($policy.conditions.users.excluderoles -eq "All") {
                        $ExcludedRoles = "All"
                        }
                    Elseif ($policy.conditions.users.excluderoles) {
                        Foreach ($id in ($policy.conditions.users.excluderoles)) {
                            $ExcludedRoles = (Get-MgDirectoryObject -DirectoryObjectId $id).AdditionalProperties.displayName
                        }
                    }

                    If ($policy.conditions.applications.includeapplications) {
                        $IncludedApps = "All"
                    }
                    Elseif ($policy.conditions.applications.includeapplications) {
                        $IncludedApps = (Get-MgServicePrincipal -All:$true -filter "AppId eq '$($policy.conditions.applications.includeapplications)'").DisplayName
                    }

                    If ($policy.conditions.applications.includeapplications) {
                        $ExcludedApps = "All"
                    }
                    Elseif ($policy.conditions.applications.includeapplications) {
                        $ExcludedApps = (Get-MgServicePrincipal -All:$true -filter "AppId eq '$($policy.conditions.applications.excludeapplications)'").DisplayName
                    }

                    $sessionControls = $policy.sessioncontrols

                    $result = New-Object psobject
                    $result | Add-Member -MemberType NoteProperty -name Name -Value $policy.DisplayName -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name State -Value $policy.State -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedApps -Value $IncludedApps -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name ExcludedApps -Value $ExcludedApps -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedUserActions -Value $policy.conditions.includeuseractions -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedProtectionLevels -Value $policy.conditions.includeprotectionlevels -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedUsers -Value $IncludedUsers -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name ExcludedUsers -Value $ExcludedUsers -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedGroups -Value $IncludedGroups -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name ExcludedGroups -Value $ExcludedGroups -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedRoles -Value $IncludedRoles -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name ExcludedRoles -Value $ExcludedRoles -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedPlatforms -Value $policy.conditions.platforms.includeplatforms -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name ExcludedPlatforms -Value $policy.conditions.platforms.excludeplatforms -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedLocations -Value $policy.conditions.locations.includelocations -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name ExcludedLocations -Value $policy.conditions.locations.excludelocations -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name IncludedSignInRisk -Value $policy.conditions.SignInRiskLevels -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name ClientAppTypes -Value $policy.conditions.ClientAppTypes -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name GrantConditions -Value $policy.grantcontrols.builtincontrols -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name ApplicationRestrictions -Value $sessioncontrols.ApplicationEnforcedRestrictions -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name CloudAppSecurity -Value $sessioncontrols.CloudAppSecurity -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name SessionLifetime -Value $sessioncontrols.signinfrequency -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name PersistentBrowser -Value $sessioncontrols.PersistentBrowser -ErrorAction SilentlyContinue

                    $result | Out-File -FilePath "$caPath\$($name)_Policy.json"
                }

                Return "Conditional Access Policies were exported for review"
            }
        }
        Else {
            Return "Tenant is not licensed for Conditional Access."
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

return Inspect-CAPolicies