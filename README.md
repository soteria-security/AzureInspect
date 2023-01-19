# Purpose

Further the state of Azure security by authoring a PowerShell script that automates the security assessment of Microsoft Office Azure environments.

# Setup

AzureInspect requires the administrative PowerShell modules for Azure administration. 

The AzureInspect.ps1 PowerShell script will validate the installed modules.

If you do not have these modules installed, you will be prompted to install them, and with your approval, the script will attempt installation. Otherwise, you should be able to install them with the following commands in an administrative PowerShell prompt, or by following the instructions at the references below:

	Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -Confirm:$false

[Install the Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-7.3.2)

Once the modules are installed, download the AzureInspect source code folder from Github using your browser or by using *git clone*.

As you will run AzureInspect with administrative privileges, you should place it in a logical location and make sure the contents of the folder are readable and writable only by the administrative user. This is especially important if you intend to install AzureInspect in a location where it will be executed frequently or used as part of an automated process.

# Usage

To run AzureInspect, open a PowerShell console and navigate to the folder you downloaded AzureInspect into:

	cd AzureInspect

You will interact with AzureInspect by executing the main script file, AzureInspect.ps1, from within the PowerShell command prompt. 

All AzureInspect requires to inspect your Azure tenant is access via an Azure account with proper permissions, so most of the command line parameters relate to the organization being assessed and the method of authentication.

Execution of AzureInspect looks like this:

	.\AzureInspect.ps1 -OrgName <value> -OutPath <value> -Auth <MFA|ALREADY_AUTHED|DEVICE|APP>

For example, to log in by entering your credentials in a browser with MFA support:

	.\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA

We recommend using the DEVICE authentication switch, as this will work across the majority of environments and supports SSO, where the MFA option does not.

	.\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth DEVICE

AzureInspect can be run with only specified Inspector modules, or conversely, by excluding specified modules.

For example, to log in by entering your credentials in a browser with MFA support:

	.\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA -SelectedInspectors inspector1, inspector2

or

	.\AzureInspect.ps1 -OrgName mycompany -OutPath ..\Azure_report -Auth MFA -ExcludedInspectors inspector1, inspector2, inspector3

To break down the parameters further:

* *OrgName* is the name of the core organization or "company" of your Azure instance, which will be inspected. 
* *OutPath* is the path to a folder where the report generated by AzureInspect will be placed.
* *Auth* is a selector that should be one of the literal values "MFA", "CMDLINE", or "ALREADY_AUTHED". 
	* *Auth* controls how AzureInspect will authenticate to all of the Office Azure services. 
	* *Auth MFA* will produce a graphical popup in which you can type your credentials and even enter an MFA code for MFA-enabled accounts. 
	* *Auth DEVICE* will produce a Device Code in the terminal with instructions to navigate to https://microsoft.com/devicelogin and enter the code to authenticate the session. This is the recommended option to run AzureInspect.
	* *Auth APP* will prompt for the Azure Active Directory registered application information necessary to run. Azure*Inspect* will use the application to perform the assessment in place of a user account. Ensure the correct permissions have been granted to the application prior to using this option. 
	* *Auth ALREADY_AUTHED* instructs AzureInspect not to authenticate before scanning. This may be preferable if you are executing AzureInspect from a PowerShell prompt where you already have valid sessions for all of the described services, such as one where you have already executed AzureInspect.
* *SelectedInspectors* is the name or names of the inspector or inspectors you wish to run with AzureInspect. If multiple inspectors are selected they must be comma separated. Only the named inspectors will be run.
* *ExcludedInspectors*  is the name or names of the inspector or inspectors you wish to prevent from running with AzureInspect. If multiple inspectors are selected they must be comma separated. All modules other included modules will be run.

When you execute AzureInspect with *-Auth MFA*, it may produce one or more graphical login prompts that you must sequentially log into. This is normal behavior. If you simply log in the requested number of times, AzureInspect should begin to execute.

As AzureInspect executes, it will steadily print status updates indicating which inspection task is running.

AzureInspect may take some time to execute. This time scales with the size and complexity of the environment under test. For example, some inspection tasks involve scanning the configuration of all Azure machine assets. This may occur near-instantly for an organization with a handful of assets, or could take entire minutes (!) for an organization with 10000. 

# Output

AzureInspect creates the directory specified in the out_path parameter. This directory is the result of the entire AzureInspect inspection. It contains three items of note:

* *Report.html*: graphical report that describes the Azure security issues identified by AzureInspect, lists Azure objects that are misconfigured, and provides remediation advice.
* *Various text files named [Inspector-Name]*: these are raw output from inspector modules and contain a list (one item per line) of misconfigured Azure objects that contain the described security flaw. For example, if a module Inspect-FictionalMFASettings were to detect all users who do not have MFA set up, the file "Inspect-FictionalMFASettings" in the report ZIP would contain one user per line who does not have MFA set up. This information is only dumped to a file in cases where more than 15 affected objects are discovered. If less than 15 affected objects are discovered, the objects are listed directly in the main HTML report body.
* *Report.zip*: zipped version of this entire directory, for convenient distribution of the results in cases where some inspector modules generated a large amount of findings.

# Necessary Privileges

AzureInspect can't run properly unless the Azure account you authenticate with has appropriate privileges. AzureInspect requires, at minimum, the following:

Azure Roles:
* Reader and Data Access - Required to allow the tool to query storage accounts. Must be granted on all subscriptions.

Azure Active Directory Roles:
* Security Reader
* Global Reader

# Developing Inspector Modules

AzureInspect is designed to be easy to expand, with the hope that it enables individuals and organizations to either utilize their own AzureInspect modules internally, or publish those modules for the Azure community.

All of AzureInspect's inspector modules are stored in the .\inspectors folder. 

It is simple to create an inspector module. Inspectors have two files:

* *ModuleName.ps1*: the PowerShell source code of the inspector module. Should return a list of all Azure objects affected by a specific issue, represented as strings.
* *ModuleName.json*: metadata about the inspector itself. For example, the finding name, description, remediation information, and references.

The PowerShell and JSON file names must be identical for AzureInspect to recognize that the two belong together. There are numerous examples in AzureInspect's built-in suite of modules, but we'll put an example here too.

Example .ps1 file, Inspect-ContainerACL.ps1:
```
# Define a function that we will later invoke.
# AzureInspect's built-in modules all follow this pattern.
$ErrorActionPreference = "Stop"

$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

. $errorHandling

function Inspect-ContainerACL {
    Try {
        $containers = @()
        
        $resourceGroups = (Get-AzResourceGroup).ResourceGroupName

        Foreach ($resource in $resourceGroups){
            $storageAccounts = Get-AzStorageAccount -ResourceGroupName $resource
            $context = $storageAccounts.Context

            Foreach ($account in $storageAccounts){
                $container = Get-AzStorageContainerAcl -Context $context | Where-Object {$_.PublicAccess -eq "Container"}
                
                foreach ($item in $container) {
                    $result = New-Object psobject
                    $result | Add-Member -MemberType NoteProperty -name 'Resource Group' -Value $resource -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name 'Container' -Value $item.Name -ErrorAction SilentlyContinue
                    $result | Add-Member -MemberType NoteProperty -name 'PublicAccess' -Value $item.PublicAccess -ErrorAction SilentlyContinue

                    $containers += $result
                }
            }
        }

            
        If ($containers.Count -NE 0) {
            $findings = @()
            foreach ($x in $containers) {
                $findings += "Container Name: $($x.Container), Resource Group: $($x.'Resource Group'), Public Access Level: $($x.PublicAccess)"
            }
            Return $findings
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
        Write-Verbose "Write to log"
        Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
        Write-Verbose "Errors written to log"
    }
}

return Inspect-ContainerACL
```

Example .json file, Inspect-ContainerACL.json:
```
{
	"FindingName": "Containers allow public access",
	"Description": "Public access allows for anonymous, public read access to a container and its blobs. The storage accounts context configuration specifies the level of public access to this container. By default, the container and any blobs in it can be accessed only by the owner of the storage account. To grant anonymous users read permissions to a container and its blobs, you can set the container permissions to enable public access. Anonymous users can read blobs in a publicly available container without authenticating the request.\nThe acceptable values for this parameter are:\n--Container. Provides full read access to a container and its blobs. Clients can enumerate blobs in the container through anonymous request, but cannot enumerate containers in the storage account.\n--Blob. Provides read access to blob data in a container through anonymous request, but does not provide access to container data. Clients cannot enumerate blobs in the container by using anonymous request.\n--Off. Restricts access to only the storage account owner.",
	"Remediation": "Disable public access for storage accounts, unless it is a business requirement. If public access is required, monitor anonymous requests using Azure Metrics Explorer.\nTo change access levels:\nGo to \"Storage Accounts\" > select the affected storage account, select Containers under \"Data Storage\" > select the resources and select \"change access level\" at the top of the page > change the Public access level drop down to \"Private (no anonymous access)\"\nAlternatively, the following PowerShell commands can be run on each of the affected blobs:\nSet-AzStorageAccount -ResourceGroupName \"$ResourceGroupName\" -Name \"$StorageAccountName\" -AllowBlobPublicAccess $false",
	"Impact": "High",
	"AffectedObjects": "",
	"References": [
		{
			"Url": "https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=powershell#set-the-public-access-level-for-a-container",
			"Text": "Configure anonymous public read access for containers and blobs"
		},
        {
            "Url":"https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-prevent",
            "Text":"Prevent anonymous public read access to containers and blobs"
        }
	]
}
```

Once you drop these two files in the .\inspectors folder, they are considered part of AzureInspect's module inventory and will run the next time you execute AzureInspect.

You have just created the Inspect-ContainerACL Inspector module. That's all!

AzureInspect will log all errors if something in your module doesn't work or doesn't follow AzureInspect conventions, so monitor the command line output.

# About Security

AzureInspect is a script harness that runs other inspector script modules stored in the .\inspectors folder. As with any other script you may run with elevated privileges, you should observe certain security hygiene practices:

* No untrusted user should have write access to the AzureInspect folder/files, as that user could then overwrite scripts or templates therein and induce you to run malicious code.
* No script module should be placed in .\inspectors unless you trust the source of that script module.
