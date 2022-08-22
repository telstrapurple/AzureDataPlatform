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
        .\Add-PowerBIAdminFromCsv.ps1 -tenantId d8785ff2-f3f9-483f-bfe1-fda2433599c1 -path "C:\Users\jonat\Source\Agile-Enterprise-BI\workbooks\admin1.csv"

    .NOTES
        Pre-requisites: MicrosoftPowerBIMgmt module is installed. If not installed, then run `Install-Module -Name MicrosoftPowerBIMgmt`
#>

# THIS IS A TEMPORARY ONLY SCRIPT 

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
    # $workspaceCollectionType = $_."Workspace Collection Type"
    $objectId = $_."ObjectId"
    Write-Host $objectId
    # get workspace
    $workspace = Get-PowerBIWorkspace -Name $workspaceName
    $workspace
    if ($null -eq $workspace) {
        Write-Warning "Failed to add AAD Group '$objectId' to Power BI Workspace '$workspaceName'. Reason: Power BI Workspace '$workspaceName' does not exist."
    }
    # add user/group to workspace
    Add-PowerBIWorkspaceUser -Id $workspace.Id -AccessRight "Admin" -PrincipalType "App" -Identifier $objectId

    $devWorkspaceName = $workspaceName + "_Dev"
    $workspace = Get-PowerBIWorkspace -Name $devWorkspaceName
    if ($null -eq $workspace) {
        Write-Warning "Failed to add AAD Group '$objectId' to Power BI Workspace '$devWorkspaceName'. Reason: Power BI Workspace '$devWorkspaceName' does not exist."
    }
    # add user/group to workspace
    Add-PowerBIWorkspaceUser -Id $workspace.Id -AccessRight "Admin" -PrincipalType "App" -Identifier $objectId
    $uatWorkspaceName = $workspaceName + "_UAT"
    $workspace = Get-PowerBIWorkspace -Name $uatWorkspaceName
    if ($null -eq $workspace) {
        Write-Warning "Failed to add AAD Group '$objectId' to Power BI Workspace '$uatWorkspaceName'. Reason: Power BI Workspace '$uatWorkspaceName' does not exist."
    }
    # add user/group to workspace
    Add-PowerBIWorkspaceUser -Id $workspace.Id -AccessRight "Admin" -PrincipalType "App" -Identifier $objectId
    
    
}