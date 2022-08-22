<#
    .SYNOPSIS 
        Creates Power BI Workspace by passing in a CSV file
    .DESCRIPTION
        The CSV file must contain the following column(s):
            - Power BI Workspace Name
            - Development Environment - 1 or 0 
            - UAT Environment - 1 or 0 

        .PARAMETER path is the path to the CSV file
    
    .EXAMPLE
        .\New-PowerBIWorkspacesFromCsv.ps1 -path "C:\Users\jonat\Source\Agile-Enterprise-BI\workbooks\level2Workspaces.csv"

    .NOTES
        Pre-requisites: MicrosoftPowerBIMgmt module is installed. If not installed, then run `Install-Module -Name MicrosoftPowerBIMgmt`
#>

[CmdletBinding()]
param (
    # [parameter(Mandatory = $true)][String]$tenantId, # add tenent if required
    [parameter(Mandatory = $true)][String]$path
)

Import-Module MicrosoftPowerBIMgmt

# Connect to power bi
# $credential = Get-Credential
# Connect-PowerBIServiceAccount -Credential $credential -TenantId $tenantId -Environment "Public" -ServicePrincipal
Connect-PowerBIServiceAccount # connect with a service account 

$table = Import-Csv -Path $path
# $table | Format-Table
$table | ForEach-Object {
    $workspaceName = $_."Power BI Workspace Name"
    $development = $_."Development Environment"
    $UAT = $_."UAT Environment"
    
    # create production workspace
    $existingWorkspace = Get-PowerBIWorkspace -Name $workspaceName
    if ($null -eq $existingWorkspace) {
        New-PowerBIWorkspace -Name $workspaceName
    }
    else { 
        Write-Warning "Power BI Workspace Name '$workspaceName' already exists. Skipped creation."
    }

    # create development workspace
    if ($development) {
        $devWorkspaceName = $workspaceName + "_Dev"
        Write-Host $devWorkspaceName
        $existingWorkspace = Get-PowerBIWorkspace -Name $devWorkspaceName
        if ($null -eq $existingWorkspace) {
            New-PowerBIWorkspace -Name $devWorkspaceName
        }
    }
    else { 
        Write-Warning "Power BI Workspace Name '$workspaceName' already exists. Skipped creation."
    }

    # create UAT workspace
    if ($UAT) {
        $uatWorkspaceName = $workspaceName + "_UAT"
        $existingWorkspace = Get-PowerBIWorkspace -Name $uatWorkspaceName
        if ($null -eq $existingWorkspace) {
            New-PowerBIWorkspace -Name $uatWorkspaceName
        }
    }
    else { 
        Write-Warning "Power BI Workspace Name '$workspaceName' already exists. Skipped creation."
    }
}