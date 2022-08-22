<#
    .SYNOPSIS 
        Adds Power BI Users/Groups by passing in a CSV file
    .DESCRIPTION
        The CSV file must contain the following column(s):
            - Power BI Workspace Name : Power BI workspace name
            - Workspace Collection Type : one of the following ["Workspace", "App"]. However, we do not add App to workspaces. That has to be configured manually as Power BI doesn't support APIs for Apps. 
            - AAD Group : AAD Group Name

        .PARAMETER tenantId is the tenant Id of the Azure Active Directory
        .PARAMETER path is the path to the CSV file
    
    .EXAMPLE
        .\Add-PowerBIUsersFromCsv.ps1 -tenantId d8785ff2-f3f9-483f-bfe1-fda2433599c1 -path "C:\Users\jonat\Source\Agile-Enterprise-BI\workbooks\Level3AADGroupWorkspaceMap.csv"

    .NOTES
        Pre-requisites: MicrosoftPowerBIMgmt module is installed. If not installed, then run `Install-Module -Name MicrosoftPowerBIMgmt`
#>

[CmdletBinding()]
param (
    [parameter(Mandatory = $true)][String]$tenantId,
    [parameter(Mandatory = $true)][String]$path
)

Import-Module MicrosoftPowerBIMgmt
# Use Windows PowerShell because AzureAD module is not compatible with PowerShell 7 at the moment.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_windows_powershell_compatibility?view=powershell-7
Import-Module AzureAD -UseWindowsPowerShell 

# Connect azureAD
$output = Get-AzureADTenantDetail -ErrorAction SilentlyContinue
if ($null -eq $output) {
    Connect-AzureAD -Confirm -TenantId $tenantId
}

# Connect to power bi
# $credential = Get-Credential
# Connect-PowerBIServiceAccount -Credential $credential -TenantId $tenantId -Environment "Public" -ServicePrincipal
Connect-PowerBIServiceAccount # connect with a service account 

$table = Import-Csv -Path $path
# $table | Format-Table
$table | ForEach-Object {
    $workspaceName = $_."Power BI Workspace Name"
    $workspaceCollectionType = $_."Workspace Collection Type"
    $aadGroupName = $_."AAD Group"
    
    if ($workspaceCollectionType -eq "Workspace") {
        # get AAD Group
        $aadGroup = Get-AzureADGroup -SearchString $aadGroupName
        Write-Host $aadGroupName
        Write-Host $aadGroup
        if ($null -eq $aadGroup) {
            Write-Warning "Failed to add AAD Group '$aadGroupName' to Power BI Workspace '$workspaceName'. Reason: AAD Group '$aadGroupName' does not exist."
        }
        # get workspace
        $workspace = Get-PowerBIWorkspace -Name $workspaceName
        if ($null -eq $workspace) {
            Write-Warning "Failed to add AAD Group '$aadGroupName' to Power BI Workspace '$workspaceName'. Reason: Power BI Workspace '$workspace' does not exist."
        }
        # add user/group to workspace
        Add-PowerBIWorkspaceUser -Id $workspace.Id -AccessRight "Contributor" -PrincipalType "Group" -Identifier $aadGroup.ObjectId
    }
}