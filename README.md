# Purpose

Further the state of Azure security by authoring a PowerShell script that automates the security assessment of Microsoft Office Azure environments.

# Setup

AzureInspect requires the administrative PowerShell modules for Microsoft Online, Azure AD (We recommend installing the AzureADPreview module), Exchange administration, Microsoft Graph, Microsoft Intune, Microsoft Teams, and Sharepoint administration. 

The AzureInspect.ps1 PowerShell script will validate the installed modules.

If you do not have these modules installed, you will be prompted to install them, and with your approval, the script will attempt installation. Otherwise, you should be able to install them with the following commands in an administrative PowerShell prompt, or by following the instructions at the references below:

	Install-Module -Name MSOnline

	Install-Module -Name AzureADPreview

	Install-Module -Name ExchangeOnlineManagement

	Install-Module -Name Microsoft.Online.SharePoint.PowerShell

	Install-Module -Name Microsoft.Graph

	Install-Module -Name MicrosoftTeams

	Install-Module -Name Microsoft.Graph.Intune

[Install MSOnline PowerShell](https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-msonlinev1?view=azureadps-1.0)

[Install Azure AD PowerShell](https://docs.microsoft.com/en-us/powershell/module/azuread/?view=azureadps-2.0)

[Install Exchange Online PowerShell](https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps)

[Install SharePoint](https://docs.microsoft.com/en-us/powershell/sharepoint/sharepoint-online/connect-sharepoint-online?view=sharepoint-ps)

[Install Microsoft Graph SDK](https://docs.microsoft.com/en-us/graph/powershell/installation)

[Install Microsoft Teams PowerShell Module](https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install)

[Install Microsoft Intune PowerShell SDK](https://github.com/microsoft/Intune-PowerShell-SDK)

Once the above are installed, download the AzureInspect source code folder from Github using your browser or by using *git clone*.

As you will run AzureInspect with administrative privileges, you should place it in a logical location and make sure the contents of the folder are readable and writable only by the administrative user. This is especially important if you intend to install AzureInspect in a location where it will be executed frequently or used as part of an automated process.

# Usage

To run AzureInspect, open a PowerShell console and navigate to the folder you downloaded AzureInspect into:

	cd AzureInspect

You will interact with AzureInspect by executing the main script file, AzureInspect.ps1, from within the PowerShell command prompt. 

All AzureInspect requires to inspect your Azure tenant is access via an Azure account with proper permissions, so most of the command line parameters relate to the organization being assessed and the method of authentication.

Execution of AzureInspect looks like this:

	.\AzureInspect.ps1 -OrgName <value> -OutPath <value> -Auth <MFA|ALREADY_AUTHED>

For example, to log in by entering your credentials in a browser with MFA support:

	.\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA

AzureInspect can be run with only specified Inspector modules, or conversely, by excluding specified modules.

For example, to log in by entering your credentials in a browser with MFA support:

	.\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA -SelectedInspectors inspector1, inspector2

or

	.\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA -ExcludedInspectors inspector1, inspector2, inspector3

To break down the parameters further:

* *OrgName* is the name of the core organization or "company" of your Azure instance, which will be inspected. 
	* If you do not know your organization name, you can navigate to the list of all Exchange domains in Azure. The topmost domain should be named *domain_name*.onmicrosoft.com. In that example, *domain_name* is your organization name and should be used when executing AzureInspect.
* *OutPath* is the path to a folder where the report generated by AzureInspect will be placed.
* *Auth* is a selector that should be one of the literal values "MFA", "CMDLINE", or "ALREADY_AUTHED". 
	* *Auth* controls how AzureInspect will authenticate to all of the Office Azure services. 
	* *Auth MFA* will produce a graphical popup in which you can type your credentials and even enter an MFA code for MFA-enabled accounts. 
	* *Auth ALREADY_AUTHED* instructs AzureInspect not to authenticate before scanning. This may be preferable if you are executing AzureInspect from a PowerShell prompt where you already have valid sessions for all of the described services, such as one where you have already executed AzureInspect.
* *SelectedInspectors* is the name or names of the inspector or inspectors you wish to run with AzureInspect. If multiple inspectors are selected they must be comma separated. Only the named inspectors will be run.
* *ExcludedInspectors*  is the name or names of the inspector or inspectors you wish to prevent from running with AzureInspect. If multiple inspectors are selected they must be comma separated. All modules other included modules will be run.

When you execute AzureInspect with *-Auth MFA*, it may produce several graphical login prompts that you must sequentially log into. This is normal behavior as Exchange, SharePoint etc. have separate administration modules and each requires a different login session. If you simply log in the requested number of times, AzureInspect should begin to execute. This is the opposite of fun and we're seeking a workaround, but needless to say we feel the results are worth the minute spent looking at MFA codes.

As AzureInspect executes, it will steadily print status updates indicating which inspection task is running.

AzureInspect may take some time to execute. This time scales with the size and complexity of the environment under test. For example, some inspection tasks involve scanning the account configuration of all users. This may occur near-instantly for an organization with 50 users, or could take entire minutes (!) for an organization with 10000. 

# Output

AzureInspect creates the directory specified in the out_path parameter. This directory is the result of the entire AzureInspect inspection. It contains three items of note:

* *Report.html*: graphical report that describes the Azure security issues identified by AzureInspect, lists Azure objects that are misconfigured, and provides remediation advice.
* *Various text files named [Inspector-Name]*: these are raw output from inspector modules and contain a list (one item per line) of misconfigured Azure objects that contain the described security flaw. For example, if a module Inspect-FictionalMFASettings were to detect all users who do not have MFA set up, the file "Inspect-FictionalMFASettings" in the report ZIP would contain one user per line who does not have MFA set up. This information is only dumped to a file in cases where more than 15 affected objects are discovered. If less than 15 affected objects are discovered, the objects are listed directly in the main HTML report body.
* *Report.zip*: zipped version of this entire directory, for convenient distribution of the results in cases where some inspector modules generated a large amount of findings.

# Necessary Privileges

AzureInspect can't run properly unless the Azure account you authenticate with has appropriate privileges. AzureInspect requires, at minimum, the following:

* Global Administrator
* SharePoint Administrator

We realize that these are extremely permissive roles, unfortunately due to the use of Microsoft Graph, we are restricted from using lesser prileges by Microsoft. Application and Cloud Application Administrator roles (used to grant delegated and application permissions) are restricted from granting permissions for Microsoft Graph or Azure AD PowerShell modules. [https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#application-administrator](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#application-administrator) 

# Developing Inspector Modules

AzureInspect is designed to be easy to expand, with the hope that it enables individuals and organizations to either utilize their own AzureInspect modules internally, or publish those modules for the Azure community.

All of AzureInspect's inspector modules are stored in the .\inspectors folder. 

It is simple to create an inspector module. Inspectors have two files:

* *ModuleName.ps1*: the PowerShell source code of the inspector module. Should return a list of all Azure objects affected by a specific issue, represented as strings.
* *ModuleName.json*: metadata about the inspector itself. For example, the finding name, description, remediation information, and references.

The PowerShell and JSON file names must be identical for AzureInspect to recognize that the two belong together. There are numerous examples in AzureInspect's built-in suite of modules, but we'll put an example here too.

Example .ps1 file, BypassingSafeAttachments.ps1:
```
# Define a function that we will later invoke.
# AzureInspect's built-in modules all follow this pattern.
function Inspect-BypassingSafeAttachments {
	# Query some element of the Azure environment to inspect. Note that we did not have to authenticate to Exchange
	# to fetch these transport rules within this module; assume main AzureInspect harness has logged us in already.
	$safe_attachment_bypass_rules = (Get-TransportRule | Where { $_.SetHeaderName -eq "X-MS-Exchange-Organization-SkipSafeAttachmentProcessing" }).Identity
	
	# If some of the parsed Azure objects were found to have the security flaw this module is inspecting for,
	# return a list of strings representing those objects. This is what will end up as the "Affected Objects"
	# field in the report.
	If ($safe_attachment_bypass_rules.Count -ne 0) {
		return $safe_attachment_bypass_rules
	}
	
	# If none of the parsed Azure objects were found to have the security flaw this module is inspecting for,
	# returning $null indicates to AzureInspect that there were no findings for this module.
	return $null
}

# Return the results of invoking the inspector function.
return Inspect-BypassingSafeAttachments
```

Example .json file, BypassingSafeAttachments.json:
```
{
	"FindingName": "Do Not Bypass the Safe Attachments Filter",
	"Description": "In Exchange, it is possible to create mail transport rules that bypass the Safe Attachments detection capability. The rules listed above bypass the Safe Attachments capability. Consider revie1wing these rules, as bypassing the Safe Attachments capability even for a subset of senders could be considered insecure depending on the context or may be an indicator of compromise.",
	"Remediation": "Navigate to the Mail Flow -> Rules screen in the Exchange Admin Center. Look for the offending rules and begin the process of assessing who created them and whether they are necessary to the continued function of your organization. If they are not, remove the rules.",
	"AffectedObjects": "",
	"References": [
		{
			"Url": "https://docs.microsoft.com/en-us/exchange/security-and-compliance/mail-flow-rules/manage-mail-flow-rules",
			"Text": "Manage Mail Flow Rules in Exchange Online"
		},
		{
			"Url": "https://www.undocumented-features.com/2018/05/10/atp-safe-attachments-safe-links-and-anti-phishing-policies-or-all-the-policies-you-can-shake-a-stick-at/#Bypass_Safe_Attachments_Processing",
			"Text": "Undocumented Features: Safe Attachments, Safe Links, and Anti-Phishing Policies"
		}
	]
}
```

Once you drop these two files in the .\inspectors folder, they are considered part of AzureInspect's module inventory and will run the next time you execute AzureInspect.

You have just created the BypassingSafeAttachments Inspector module. That's all!

AzureInspect will throw a pretty loud and ugly error if something in your module doesn't work or doesn't follow AzureInspect conventions, so monitor the command line output.

# About Security

AzureInspect is a script harness that runs other inspector script modules stored in the .\inspectors folder. As with any other script you may run with elevated privileges, you should observe certain security hygiene practices:

* No untrusted user should have write access to the AzureInspect folder/files, as that user could then overwrite scripts or templates therein and induce you to run malicious code.
* No script module should be placed in .\inspectors unless you trust the source of that script module.