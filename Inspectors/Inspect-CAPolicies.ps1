$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

$path = "$(@($subPath))"

function Inspect-CAPolicies {
    Try {
        $tenantLicense = (Get-MgSubscribedSku).ServicePlans
        
        If ($tenantLicense.ServicePlanName -match "AAD_PREMIUM*") {
            
            $conditionalAccess = Get-MgIdentityConditionalAccessPolicy  | Where-Object { ($_.conditions.applications.includeapplications -contains '797f4846-ba00-4fd7-ba43-dac1f8f63013') -or ($_.conditions.applications.includeapplications -eq 'All') }

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
                            Try {
                                $IncludedUsers += (Get-MgDirectoryObject -DirectoryObjectId $id -ErrorAction Stop).AdditionalProperties.displayName
                            }
                            Catch {
                                $exception = $_.Exception.Message
                                If ($exception -like "*404 (NotFound)*") {
                                    $IncludedUsers += "$id - User may no lnger exist."
                                }
                            }
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
                            Try {
                                $ExcludedUsers += (Get-MgDirectoryObject -DirectoryObjectId $id -ErrorAction Stop).AdditionalProperties.displayName
                            }
                            Catch {
                                $exception = $_.Exception.Message
                                If ($exception -like "*404 (NotFound)*") {
                                    $ExcludedUsers += "$id - User may no lnger exist."
                                }
                            }
                        }
                    }
                    
                    If ($policy.conditions.users.includegroups -eq "All") {
                        $IncludedGroups = "All"
                    }
                    Elseif ($policy.conditions.users.includegroups) {
                        Foreach ($id in ($policy.conditions.users.includegroups)) {
                            Try {
                                $IncludedGroups = (Get-MgDirectoryObject -DirectoryObjectId $id -ErrorAction Stop).AdditionalProperties.displayName
                            }
                            Catch {
                                $exception = $_.Exception.Message
                                If ($exception -like "*404 (NotFound)*") {
                                    $IncludedGroups += "$id - Group may no lnger exist."
                                }
                            }
                        }
                    }
                    
                    If ($policy.conditions.users.excludegroups -eq "All") {
                        $ExcludedGroups = "All"
                    }
                    Elseif ($policy.conditions.users.excludegroups) {
                        Foreach ($id in ($policy.conditions.users.excludegroups)) {
                            Try {
                                $ExcludedGroups = (Get-MgDirectoryObject -DirectoryObjectId $id -ErrorAction Stop).AdditionalProperties.displayName
                            }
                            Catch {
                                $exception = $_.Exception.Message
                                If ($exception -like "*404 (NotFound)*") {
                                    $ExcludedGroups += "$id - Group may no lnger exist."
                                }
                            }
                        }
                    }
                    
                    If ($policy.conditions.users.includeroles -eq "All") {
                        $IncludedRoles = "All"
                    }
                    Elseif ($policy.conditions.users.includeroles) {
                        Foreach ($id in ($policy.conditions.users.includeroles)) {
                            Try {
                                $IncludedRoles = (Get-MgDirectoryObject -DirectoryObjectId $id -ErrorAction Stop).AdditionalProperties.displayName
                            }
                            Catch {
                                $exception = $_.Exception.Message
                                If ($exception -like "*404 (NotFound)*") {
                                    $IncludedRoles += "$id - Role may no lnger exist."
                                }
                            }
                        }
                    }
                    
                    If ($policy.conditions.users.excluderoles -eq "All") {
                        $ExcludedRoles = "All"
                    }
                    Elseif ($policy.conditions.users.excluderoles) {
                        Foreach ($id in ($policy.conditions.users.excluderoles)) {
                            Try {
                                $ExcludedRoles = (Get-MgDirectoryObject -DirectoryObjectId $id -ErrorAction Stop).AdditionalProperties.displayName
                            }
                            Catch {
                                $exception = $_.Exception.Message
                                If ($exception -like "*404 (NotFound)*") {
                                    $ExcludedRoles += "$id - Role may no lnger exist."
                                }
                            }
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

                    $result = [PSCustomObject]@{
                        Name                     = $policy.DisplayName
                        State                    = $policy.State
                        IncludedApps             = $IncludedApps
                        ExcludedApps             = $ExcludedApps
                        IncludedUserActions      = $policy.conditions.includeuseractions
                        IncludedProtectionLevels = $policy.conditions.includeprotectionlevels
                        IncludedUsers            = $IncludedUsers
                        ExcludedUsers            = $ExcludedUsers
                        IncludedGroups           = $IncludedGroups
                        ExcludedGroups           = $ExcludedGroups
                        IncludedRoles            = $IncludedRoles
                        ExcludedRoles            = $ExcludedRoles
                        IncludedPlatforms        = $policy.conditions.platforms.includeplatforms
                        ExcludedPlatforms        = $policy.conditions.platforms.excludeplatforms
                        IncludedLocations        = $policy.conditions.locations.includelocations
                        ExcludedLocations        = $policy.conditions.locations.excludelocations
                        IncludedSignInRisk       = $policy.conditions.SignInRiskLevels
                        ClientAppTypes           = $policy.conditions.ClientAppTypes
                        GrantConditions          = $policy.grantcontrols.builtincontrols
                        ApplicationRestrictions  = $sessioncontrols.ApplicationEnforcedRestrictions
                        CloudAppSecurity         = $sessioncontrols.CloudAppSecurity
                        SessionLifetime          = $sessioncontrols.signinfrequency
                        PersistentBrowser        = $sessioncontrols.PersistentBrowser
                    }

                    $result | Convertto-Json -Depth 10 | Out-File -FilePath "$caPath\$($name)_Policy.json"
                }

                Return $null
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