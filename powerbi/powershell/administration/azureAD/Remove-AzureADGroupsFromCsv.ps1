<#
    .SYNOPSIS 
        Removes AAD Groups by passing in a CSV file which contains a list of AAD Group Names
    .DESCRIPTION
        The CSV file must contain the following column(s):
            - AAD Group
        .PARAMETER tenantId is the tenant Id of the Azure Active Directory
        .PARAMETER path is the path to the CSV file
    
    .EXAMPLE
        .\Remove-AzureADGroupsFromCsv.ps1 -tenantId d8785ff2-f3f9-483f-bfe1-fda2433599c1 -path "C:\Users\jonat\Source\Agile-Enterprise-BI\workbooks\aadGroups.csv"

    .NOTES
        Pre-requisites: AzureAD module is installed. If not installed, then run `Install-Module AzureAD`
#>

[CmdletBinding()]
param (
    [parameter(Mandatory = $true)][String]$tenantId,
    [parameter(Mandatory = $true)][String]$path
)
# Use Windows PowerShell because AzureAD module is not compatible with PowerShell 7 at the moment.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_windows_powershell_compatibility?view=powershell-7
Import-Module AzureAD -UseWindowsPowerShell 
# Connect azureAD
$output = Get-AzureADTenantDetail -ErrorAction SilentlyContinue
if ($null -eq $output) {
    Connect-AzureAD -Confirm -TenantId $tenantId
}
$table = Import-Csv -Path $path
$table | ForEach-Object {
    $aadGroup = Get-AzureADGroup -SearchString $_."AAD Group"
    Remove-AzureADGroup -ObjectId $aadGroup.ObjectId
}