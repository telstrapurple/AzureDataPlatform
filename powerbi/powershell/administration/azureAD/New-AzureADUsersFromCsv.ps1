<#
    .SYNOPSIS 
        Creates AAD Users by passing in a CSV file which contains a list of AAD Group Names
    .DESCRIPTION
        The CSV file must contain the following column(s):
            - User Display Name : cannot contain any spaces or special characters
            - User Principal Name : email address of the user. must belong to the domain. 
        .PARAMETER tenantId is the tenant Id of the Azure Active Directory
        .PARAMETER path is the path to the CSV file
    
    .EXAMPLE
        .\New-AzureADUsersFromCsv.ps1 -tenantId d8785ff2-f3f9-483f-bfe1-fda2433599c1 -path "C:\Users\jonat\Source\Agile-Enterprise-BI\workbooks\users.csv"

    .NOTES
        Pre-requisites: AzureAD module is installed. If not installed, then run `Install-Module AzureAD`

        Note that you may have to execute the following PowerShell command first in order to make the `Microsoft.Open.AzureAD.Model.PasswordProfile` type available: 
        `Add-Type -Path "C:\Program Files\WindowsPowerShell\Modules\AzureAD\2.0.2.52\Microsoft.Open.AzureAD16.Graph.Client.dll"`. Please use path where the `Microsoft.Open.AzureAD16.Graph.Client.dll` is located at. 
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

# import table
$table = Import-Csv -Path $path
# $table | Format-Table # uncomment to print table

# use default password for demo
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = "Password123"

# create user
$table | ForEach-Object {
    $userDisplayName = $_."User Display Name" # cannot contain special characters or spaces
    $userPrincipalName = $_."User Principal Name"
    $mailNickName = $userDisplayName
    New-AzureADUser -DisplayName $userDisplayName -PasswordProfile $PasswordProfile -UserPrincipalName $userPrincipalName -AccountEnabled $true -mailNickname $mailNickName
}