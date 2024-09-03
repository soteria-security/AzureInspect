<#
    .SYNOPSIS
    Automated data collection to aid in the security assessment of Microsoft Azure environments.

    .DESCRIPTION
    Automated data collection to aid in the security assessment of Microsoft Azure environments and develop a risk-based remedation plan with step-by-step remediation guidance and best practice recommendations.

    .PARAMETER OutPath
    The path to a folder where the report generated by AzureInspect will be placed.

    .PARAMETER Auth
    REQUIRED - Switch that should be one of the literal values "MFA", "DEVICE", "APP", or "ALREADY_AUTHED". Auth controls how AzureInspect will authenticate to the necessary services.

    .PARAMETER SkipModuleCheck
    Intended for testing purposes, but may be used to avoid the script checking installation status for required PowerShell Modules.

    .PARAMETER SkipUpdateCheck
    Intended for testing purposes, but may be used to avoid the script checking for version updates to required PowerShell Modules.

    .PARAMETER SelectedInspectors
    The name or names of the inspector or inspectors you wish to run with AzureInspect. If multiple inspectors are selected they must be comma separated. Only the named inspectors will be run.

    .PARAMETER ExcludedInspectors
    The name or names of the inspector or inspectors you wish to prevent from running with AzureInspect. If multiple inspectors are selected they must be comma separated. All modules other included modules will be run.

    .INPUTS
    None. You cannot pipe objects to AzureInspect.ps1.

    .OUTPUTS
    None. AzureInspect.ps1 does not generate any output.

    .EXAMPLE
    PS> .\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA

    .EXAMPLE
    PS> .\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth DEVICE

    .EXAMPLE
    PS> .\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA -SelectedInspectors inspector1, inspector2

    .EXAMPLE
    PS> .\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA -ExcludedInspectors inspector1, inspector2

    .LINK
    https://github.com/soteria-security/AzureInspect
#>

param (
    [Parameter(Mandatory = $true,
        HelpMessage = 'Organization name')]
    [string] $OrgName,
    [Parameter(Mandatory = $true,
        HelpMessage = 'Organization Domain')]
    [string] $domain,
    [Parameter(Mandatory = $true,
        HelpMessage = 'Output path for report')]
    [string] $OutPath,
    [Parameter(Mandatory = $false,
        HelpMessage = 'Skip Required Module Check')] #Intended for testing and troubleshooting purposes only!
    [switch]$SkipModuleCheck,
    [Parameter(Mandatory = $false,
        HelpMessage = 'Retest Assessment. Uses Retest Template')]
    [switch]$retest,
    [Parameter(Mandatory = $true,
        HelpMessage = 'Auth type')]
    [ValidateSet('ALREADY_AUTHED', 'MFA', 'DEVICE', 'APP',
        IgnoreCase = $true)]
    [string] $Auth = "MFA",
    [string[]] $SelectedInspectors = @(),
    [string[]] $ExcludedInspectors = @(),
    [Parameter(Mandatory = $false,
        HelpMessage = 'Do not disconnect at the end of the run')] #Intended for testing and troubleshooting purposes only!
    [switch]$DoNotDisconnect
)

#$WarningPreference = 'SilentlyContinue'

# Import script used for Error logging
. .\Write-ErrorLog.ps1

$org_name = $OrgName
$out_path = $OutPath
$selected_inspectors = $SelectedInspectors
$excluded_inspectors = $ExcludedInspectors


Function Connect-Services {
    Try {
        # Log into the Azure service prior to the analysis.
        If ($auth -EQ "MFA") {
            If ($domain -like "*@*") {
                $domain = ($domain -split '@')[1]
            }

            $tenantID = (((Invoke-WebRequest -Uri "https://login.microsoftonline.com/$domain/.well-known/openid-configuration" -UseBasicParsing).Content | ConvertFrom-Json).token_endpoint -split '/')[3]

            Write-Output "Connecting to Azure Services"
            Connect-AzAccount -TenantId $tenantID -Scope Process
            # Connect to Microsoft Graph
            Write-Output "Connecting to Microsoft Graph"
            Connect-MgGraph -ContextScope Process -Scopes "AuditLog.Read.All", "Policy.Read.All", "Directory.Read.All", "IdentityProvider.Read.All", "Organization.Read.All", "User.Read.All", "UserAuthenticationMethod.Read.All"
            #Select-MgProfile -Name beta
            Write-Output "Connected via Graph to $((Get-MgOrganization).DisplayName)"
        }
        If ($auth -EQ "DEVICE") {
            If ($domain -like "*@*") {
                $domain = ($domain -split '@')[1]
            }

            $tenantID = (((Invoke-WebRequest -Uri "https://login.microsoftonline.com/$domain/.well-known/openid-configuration" -UseBasicParsing).Content | ConvertFrom-Json).token_endpoint -split '/')[3]

            Write-Output "Connecting to Azure Services"
            Connect-AzAccount -TenantId $tenantID -UseDeviceAuthentication
            # Connect to Microsoft Graph
            Write-Output "Connecting to Microsoft Graph"
            Connect-MgGraph -Scopes "AuditLog.Read.All", "Policy.Read.All", "Directory.Read.All", "IdentityProvider.Read.All", "Organization.Read.All", "User.Read.All", "UserAuthenticationMethod.Read.All"
            #Select-MgProfile -Name beta
            Write-Output "Connected via Graph to $((Get-MgOrganization).DisplayName)"
        }
        If ($auth -EQ "APP") {
            # Gather necessary information
            $email = Read-Host -Prompt "Enter your email address"
            $appID = Read-Host -Prompt "Enter the client/application Id"
            $thumbprint = Read-Host -Prompt "Enter the certificate thumbprint"

            # Get Tenant information
            If ($email -like "*@*") {
                $domain = ($email -split '@')[1]
            }

            Write-Output "Collecting Tenant ID and Authorization..."
            $tenantID = (((Invoke-WebRequest -Uri "https://login.microsoftonline.com/$domain/.well-known/openid-configuration" -UseBasicParsing).Content | ConvertFrom-Json).token_endpoint -split '/')[3]

            Write-Output "Connecting to Azure Services"
            Connect-AzAccount -ApplicationId $appID -CertificateThumbprint $thumbprint -Tenant $tenantID
            # Connect to Microsoft Graph
            Write-Output "Connecting to Microsoft Graph"
            Connect-MgGraph -ClientId $appID -TenantId $tenantID -CertificateThumbPrint $thumbprint | Out-Null
            #Select-MgProfile -Name beta
            Write-Output "Connected via Graph to $((Get-MgOrganization).DisplayName)"
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

# Function to change color of text on errors for specific messages
Function Colorize($ForeGroundColor) {
    $color = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForeGroundColor
  
    if ($args) {
        Write-Output $args
    }
  
    $Host.UI.RawUI.ForegroundColor = $color
}


Function Confirm-Close {
    Read-Host "Press Enter to Exit"
    Exit
}

Function Confirm-InstalledModules {
    #Check for required Modules and prompt for install if missing
    $modules = @("Az.Accounts", "Az.Advisor", "Az.Aks", "Az.AnalysisServices", "Az.ApiManagement", "Az.AppConfiguration", "Az.ApplicationInsights", "Az.Attestation", "Az.Automation", "Az.Batch", "Az.Billing", "Az.Cdn", "Az.CognitiveServices", "Az.Compute", "Az.ContainerInstance", "Az.ContainerRegistry", "Az.CosmosDB", "Az.DataBoxEdge", "Az.Databricks", "Az.DataFactory", "Az.DataLakeAnalytics", "Az.DataLakeStore", "Az.DataShare", "Az.DeploymentManager", "Az.DesktopVirtualization", "Az.DevTestLabs", "Az.Dns", "Az.EventGrid", "Az.EventHub", "Az.FrontDoor", "Az.Functions", "Az.HDInsight", "Az.HealthcareApis", "Az.IotHub", "Az.KeyVault", "Az.Kusto", "Az.LogicApp", "Az.MachineLearning", "Az.Maintenance", "Az.ManagedServices", "Az.MarketplaceOrdering", "Az.Media", "Az.Migrate", "Az.Monitor", "Az.Network", "Az.NotificationHubs", "Az.OperationalInsights", "Az.PolicyInsights", "Az.PowerBIEmbedded", "Az.PrivateDns", "Az.RecoveryServices", "Az.RedisCache", "Az.RedisEnterpriseCache", "Az.Relay", "Az.ResourceMover", "Az.Resources", "Az.Security", "Az.SecurityInsights", "Az.ServiceBus", "Az.ServiceFabric", "Az.SignalR", "Az.Sql", "Az.SqlVirtualMachine", "Az.Storage", "Az.StorageSync", "Az.StreamAnalytics", "Az.Support", "Az.Tools.Migration", "Az.TrafficManager", "Az.Websites")
    $count = 0
    $installed = Get-InstalledModule

    foreach ($module in $modules) {
        if ($installed.Name -notcontains $module) {
            $message = Write-Output "`n$module is not installed."
            $message1 = Write-Output 'The required modules may be installed en masse by running "Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -Confirm:$false" in an elevated PowerShell window.'
            Colorize Red ($message)
            Colorize Yellow ($message1)
            $install = Read-Host -Prompt "Would you like to attempt installation of the individual modules now? (Y|N)"
            If ($install -eq 'y') {
                Try {
                    Install-Module -Name $module -Scope CurrentUser -Repository PSGallery -Force -Confirm:$false
                    $count ++
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
        }
        Else {
            Write-Output "$module is installed."
            $count ++
        }
    }

    If ($count -lt $modules.Count) {
        Write-Output ""
        Write-Output ""
        $message = Write-Output "Dependency checks failed. Please install all missing modules before running this script."
        Colorize Red ($message)
        Confirm-Close
    }
    Else {
        Connect-Services
    }
}


If ($Auth -eq 'ALREADY_AUTHED') {
    Connect-Services
}
Else {
    # Start Script
    If (! $SkipModuleCheck.IsPresent) {
        Confirm-InstalledModules
    }
    Else {
        Connect-Services
    }
}

# Create Output Directory if required
Try {
    New-Item -ItemType Directory -Path $out_path -Force | Out-Null
    If ((Test-Path $out_path) -eq $true) {
        $out_path = Resolve-Path $out_path
        Write-Output "$($out_path.Path) created successfully."
    }
}
Catch {
    Write-Error "Directory not created. Please check permissions."
    Confirm-Close
}

$tenantID = (((Invoke-WebRequest -Uri "https://login.microsoftonline.com/$domain/.well-known/openid-configuration" -UseBasicParsing).Content | ConvertFrom-Json).token_endpoint -split '/')[3]

Try {
    $subscriptions = Get-AzSubscription -TenantId $tenantID
}
Catch {
    $exc = $_.Exception.Message
    If ($exc -like "*Run Connect-AzAccount to login*") {
        Write-Error "Connection to the tenant failed. Please verify Tenant and Account details and run AzureInspect again."
    }
}

$count = 0

$subPath = ''

If ($subscriptions) {
    Foreach ($subscription in $subscriptions) {
        $count += 1
        # Create a subfolder for each subscription
        $path = "$out_path\Subscription_$($count)"
        
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        
        If ((Test-Path $path) -eq $true) {
            $path = Resolve-Path $path
            Write-Output "$($path.Path) created successfully."
            $subPath = $path
        }

        # Set the context for the associated subscription
        Write-Output "Selecting subscription $($subscription.Name)"

        Try {
            Set-AzContext -Subscription $subscription.Id -Tenant $tenantID -ErrorAction Stop
        }
        Catch {
            $message = $_
            If ($message -match "WARNING: Unable to acquire token for tenant '' with error 'Authentication failed against tenant") {
                Write-Host "No access to subscription $($subscription.Name)`nSkipping..."
            }
        }

        # Get a list of every available detection module by parsing the PowerShell
        # scripts present in the .\inspectors folder. 
        # Exclude specified Inspectors
        If ($excluded_inspectors -and $excluded_inspectors.Count) {
            $excluded_inspectors = foreach ($inspector in $excluded_inspectors) { "$inspector.ps1" }
            If ($IsWindows) {
                $inspectors = (Get-ChildItem .\inspectors\*.ps1 -exclude $excluded_inspectors).Name | ForEach-Object { ($_ -split ".ps1")[0] }
            }
            ElseIf ($IsLinux) {
                $inspectors = (Get-ChildItem ./Inspectors/*.ps1 -exclude $excluded_inspectors).Name | ForEach-Object { ($_ -split ".ps1")[0] }
            }
            ElseIf ($IsMacOS) {
                $inspectors = (Get-ChildItem ./Inspectors/*.ps1 -exclude $excluded_inspectors).Name | ForEach-Object { ($_ -split ".ps1")[0] }
            }
        }
        else {
            If ($IsWindows) {
                $inspectors = (Get-ChildItem .\inspectors\*.ps1).Name | ForEach-Object { ($_ -split ".ps1")[0] }
            }
            ElseIf ($IsLinux) {
                $inspectors = (Get-ChildItem ./Inspectors/*.ps1).Name | ForEach-Object { ($_ -split ".ps1")[0] }
            }
            ElseIf ($IsMacOS) {
                $inspectors = (Get-ChildItem ./Inspectors/*.ps1).Name | ForEach-Object { ($_ -split ".ps1")[0] }
            }
        }

        # Use Selected Inspectors
        If ($selected_inspectors -AND $selected_inspectors.Count) {
            "The following inspectors were selected for use: "
            Foreach ($inspector in $selected_inspectors) {
                Write-Output $inspector
            }
        }
        elseif ($excluded_Inspectors -and $excluded_inspectors.Count) {
            $selected_inspectors = $inspectors
            Write-Output "Using inspectors:`n"
            Foreach ($inspector in $inspectors) {
                Write-Output $inspector
            }
        }
        Else {
            "Using all inspectors."
            $selected_inspectors = $inspectors
        }


        Try {
            # Maintain a list of all findings, beginning with an empty list.
            $findings = @()

            # For every inspector the user wanted to run...
            ForEach ($selected_inspector in $selected_inspectors) {
                # ...if the user selected a valid inspector...
                If ($inspectors.Contains($selected_inspector)) {
                    Write-Output "Invoking Inspector: $selected_inspector"
                    
                    # Get the static data (finding description, remediation etc.) associated with that inspector module.
                    If ($IsWindows) {
                        $finding = Get-Content .\inspectors\$selected_inspector.json | Out-String | ConvertFrom-Json
                    }
                    ElseIf ($IsLinux) {
                        $finding = Get-Content ./Inspectors/$selected_inspector.json | Out-String | ConvertFrom-Json
                    }
                    ElseIf ($IsMacOS) {
                        $finding = Get-Content ./Inspectors/$selected_inspector.json | Out-String | ConvertFrom-Json
                    }
                    
                    # Invoke the actual inspector module and store the resulting list of insecure objects.
                    $finding.AffectedObjects = Invoke-Expression ".\Inspectors\$selected_inspector.ps1"
                    
                    # Add the finding to the list of all findings.
                    $findings += $finding
                }
                Else {
                    Write-Output "$selected_inspector is not a valid inspector or could not be found. Please re-run the script and select valid inspectors."
                    Confirm-Close
                }
            }

            # Function that retrieves templating information from 
            function Parse-Template {
                If ($retest.IsPresent) {
                    $template = (Get-Content ".\AzureInspectRetestTemplate.html") -join "`n"
                }
                Else {
                    $template = (Get-Content ".\AzureInspectDefaultTemplate.html") -join "`n"
                }
                $template -match '\<!--BEGIN_FINDING_LONG_REPEATER-->([\s\S]*)\<!--END_FINDING_LONG_REPEATER-->'
                $findings_long_template = $matches[1]
                
                $template -match '\<!--BEGIN_FINDING_SHORT_REPEATER-->([\s\S]*)\<!--END_FINDING_SHORT_REPEATER-->'
                $findings_short_template = $matches[1]
                
                $template -match '\<!--BEGIN_AFFECTED_OBJECTS_REPEATER-->([\s\S]*)\<!--END_AFFECTED_OBJECTS_REPEATER-->'
                $affected_objects_template = $matches[1]
                
                $template -match '\<!--BEGIN_REFERENCES_REPEATER-->([\s\S]*)\<!--END_REFERENCES_REPEATER-->'
                $references_template = $matches[1]
                
                $template -match '\<!--BEGIN_EXECSUM_TEMPLATE-->([\s\S]*)\<!--END_EXECSUM_TEMPLATE-->'
                $execsum_template = $matches[1]
                
                return @{
                    FindingShortTemplate    = $findings_short_template;
                    FindingLongTemplate     = $findings_long_template;
                    AffectedObjectsTemplate = $affected_objects_template;
                    ReportTemplate          = $template;
                    ReferencesTemplate      = $references_template;
                    ExecsumTemplate         = $execsum_template
                }
            }

            $templates = Parse-Template

            # Maintain a running list of each finding, represented as HTML
            $short_findings_html = '' 
            $long_findings_html = ''

            $findings_count = 0

            #$sortedFindings1 = $findings | Sort-Object {$_.FindingName}
            $sortedFindings = $findings | Sort-Object { Switch -Regex ($_.Impact) { 'Critical' { 1 }	'High' { 2 }	'Medium' { 3 }	'Low' { 4 }	'Informational' { 5 } }; $_.FindingName } 
            ForEach ($finding in $sortedFindings) {
                # If the result from the inspector was not $null,
                # it identified a real finding that we must process.
                If ($null -NE $finding.AffectedObjects) {
                    # Increment total count of findings
                    $findings_count += 1
                    
                    # Keep an HTML variable representing the current finding as HTML
                    $short_finding_html = $templates.FindingShortTemplate
                    $long_finding_html = $templates.FindingLongTemplate
                    
                    # Insert finding name and number into template HTML
                    $short_finding_html = $short_finding_html.Replace("{{FINDING_NAME}}", $finding.FindingName)
                    $short_finding_html = $short_finding_html.Replace("{{FINDING_NUMBER}}", $findings_count.ToString())
                    $long_finding_html = $long_finding_html.Replace("{{FINDING_NAME}}", $finding.FindingName)
                    $long_finding_html = $long_finding_html.Replace("{{FINDING_NUMBER}}", $findings_count.ToString())
                    If ($retest.IsPresent) {
                        $short_finding_html = $short_finding_html.Replace("{{FINDING_STATUS}}", "")
                        $long_finding_html = $long_finding_html.Replace("{{FINDING_STATUS}}", "")
                    }
                    
                    # Finding Impact
                    If ($finding.Impact -eq 'Critical') {
                        $htmlImpact = '<span style="color:Crimson;"><strong>Critical</strong></span>'
                        $short_finding_html = $short_finding_html.Replace("{{IMPACT}}", $htmlImpact)
                        $long_finding_html = $long_finding_html.Replace("{{IMPACT}}", $htmlImpact)
                    }
                    ElseIf ($finding.Impact -eq 'High') {
                        $htmlImpact = '<span style="color:DarkOrange;"><strong>High</strong></span>'
                        $short_finding_html = $short_finding_html.Replace("{{IMPACT}}", $htmlImpact)
                        $long_finding_html = $long_finding_html.Replace("{{IMPACT}}", $htmlImpact)
                    }
                    Else {
                        $short_finding_html = $short_finding_html.Replace("{{IMPACT}}", $finding.Impact)
                        $long_finding_html = $long_finding_html.Replace("{{IMPACT}}", $finding.Impact)
                    }
                    
                    If ($finding.RiskRating -eq 'Critical') {
                        $htmlRisk = '<span style="color:Crimson;"><strong>Critical</strong></span>'
                        $short_finding_html = $short_finding_html.Replace("{{RISKRATING}}", $htmlRisk)
                        $long_finding_html = $long_finding_html.Replace("{{RISKRATING}}", $htmlRisk)
                    }
                    ElseIf ($finding.RiskRating -eq 'High') {
                        $htmlRisk = '<span style="color:DarkOrange;"><strong>High</strong></span>'
                        $short_finding_html = $short_finding_html.Replace("{{RISKRATING}}", $htmlRisk)
                        $long_finding_html = $long_finding_html.Replace("{{RISKRATING}}", $htmlRisk)
                    }
                    Else {
                        $short_finding_html = $short_finding_html.Replace("{{RISKRATING}}", $finding.RiskRating)
                        $long_finding_html = $long_finding_html.Replace("{{RISKRATING}}", $finding.RiskRating)
                    }

                    # Finding description
                    $long_finding_html = $long_finding_html.Replace("{{DESCRIPTION}}", $finding.Description)
                    
                    # Finding Remediation
                    If ($finding.Remediation.length -GT 300) {
                        $short_finding_text = "Complete remediation advice is provided in the body of the report. Clicking the link to the left will take you there."
                    }
                    Else {
                        $short_finding_text = $finding.Remediation
                    }
                    
                    $short_finding_html = $short_finding_html.Replace("{{REMEDIATION}}", $short_finding_text)
                    $long_finding_html = $long_finding_html.Replace("{{REMEDIATION}}", $finding.Remediation)
                    
                    # Affected Objects
                    If ($finding.AffectedObjects.Count -GT 30) {
                        $condensed = "<a href='{name}'>{count} Affected Objects Identified<a/>."
                        $condensed = $condensed.Replace("{count}", $finding.AffectedObjects.Count.ToString())
                        $condensed = $condensed.Replace("{name}", $finding.FindingName)
                        $affected_object_html = $templates.AffectedObjectsTemplate.Replace("{{AFFECTED_OBJECT}}", $condensed)
                        $fname = $finding.FindingName
                        $finding.AffectedObjects | Out-File -FilePath $path\$fname
                    }
                    Else {
                        $affected_object_html = ''
                        ForEach ($affected_object in $finding.AffectedObjects) {
                            $affected_object_html += $templates.AffectedObjectsTemplate.Replace("{{AFFECTED_OBJECT}}", $affected_object)
                        }
                    }
                    
                    $long_finding_html = $long_finding_html.Replace($templates.AffectedObjectsTemplate, $affected_object_html)
                    
                    # References
                    $reference_html = ''
                    ForEach ($reference in $finding.References) {
                        $this_reference = $templates.ReferencesTemplate.Replace("{{REFERENCE_URL}}", $reference.Url)
                        $this_reference = $this_reference.Replace("{{REFERENCE_TEXT}}", $reference.Text)
                        $reference_html += $this_reference
                    }
                    
                    $long_finding_html = $long_finding_html.Replace($templates.ReferencesTemplate, $reference_html)
                    
                    # Add the completed short and long findings to the running list of findings (in HTML)
                    $short_findings_html += $short_finding_html
                    $long_findings_html += $long_finding_html
                }
            }

            # Insert command line execution information. This is coupled kinda badly, as is the Affected Objects html.
            $flags = "<b>Prepared for organization:</b><br/>" + $org_name + "<br/><br/>"
            $flags = $flags + "<b>Subscription Information</b>:<br/> <b>" + "</b> Subscription Name: <b>" + $subscription.Name + "</b> Subscription ID: <b>" + $subscription.Id + "</b>.<br/><br/>"
            $flags = $flags + "<b>Stats</b>:<br/> <b>" + $findings_count + "</b> out of <b>" + $inspectors.Count + "</b> executed inspector modules identified possible opportunities for improvement in subscription <b>" + $subscription.Name + "</b>.<br/><br/>"  
            $flags = $flags + "<b>Inspector Modules Executed</b>:<br/>" + "<br/>" + $selected_inspectors

            $output = $templates.ReportTemplate.Replace($templates.FindingShortTemplate, $short_findings_html)
            $output = $output.Replace($templates.FindingLongTemplate, $long_findings_html)
            $output = $output.Replace($templates.ExecsumTemplate, $templates.ExecsumTemplate.Replace("{{CMDLINEFLAGS}}", $flags))

            Try {
                $output | Out-File -FilePath "$path\Report_Subscription$($count)_$($org_name)_$(Get-Date -Format "yyyy-MM-dd").html"
            }
            Catch {
                If ($_.Exception.Message -like "*Could not find a part of the path*") {
                    Write-Host "Report path failed. Check Reports folder at Script Root."
                    $output | Out-File -FilePath ".\Reports\Report_$($org_name)_Subscription$($count)_$(Get-Date -Format "yyyy-MM-dd_hh-mm-ss").html"
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
}
Else {
    Write-Warning "No Subscription Access. Exiting..."
    Break
}

$compress = @{
    Path             = $out_path
    CompressionLevel = "Fastest"
    DestinationPath  = "$out_path\$($org_name)_Report.zip"
}

Compress-Archive @compress

function Disconnect {
    Write-Output "Disconnect from Azure Services"
    Disconnect-AzAccount
}

if (!$DoNotDisconnect) {
    $removeSession = Read-Host -Prompt "Do you wish to disconnect your session? (Y|N)"

    If ($removeSession -ne 'n') {
        Disconnect
    }
}

#$WarningPreference = 'Continue'

return