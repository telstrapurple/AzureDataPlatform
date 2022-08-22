[CmdletBinding()]
param(
    [parameter(Mandatory = $true)][string]$KEYVAULT_DEPLOY,
    [parameter(Mandatory = $true)][string]$RESOURCE_GROUP_POWERBI,
    [parameter(Mandatory = $true)][AllowEmptyString()][string]$KEYVAULT_EXISTING_NAME,
    [parameter(Mandatory = $true)][string]$sqlServerName,
    [parameter(Mandatory = $true)][string]$SQL_DATABASE_NAME,
    [parameter(Mandatory = $true)][string]$SQL_ADMINISTRATOR_USERNAME,
    [parameter(Mandatory = $true)][string]$SQL_ADMINISTRATOR_PASSWORD,
    [parameter(Mandatory = $true)][string]$PBI_ADMIN_USERNAME,
    [parameter(Mandatory = $true)][string]$PBI_ADMIN_PASSWORD
)

if ($KEYVAULT_DEPLOY -eq "true") {
    $lgaWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName "$RESOURCE_GROUP_POWERBI" -ErrorAction SilentlyContinue
    if ($null -eq $lgaWorkspace) {
        Write-Warning ("Could not get LGA Workspace contained in the following resource group" + "$RESOURCE_GROUP_POWERBI" + ". Please correct this before proceeding with KeyVault deployment.")
    }
    else {
        $keyVault_secret_lgaWorkspaceId = $lgaWorkspace.CustomerId
        Write-Host "keyVault_secret_lgaWorkspaceId equal " $keyVault_secret_lgaWorkspaceId
        Write-Output "##vso[task.setvariable variable=keyVault_secret_lgaWorkspaceId]$keyVault_secret_lgaWorkspaceId" 
        # Get LGA shared key 
        $lgaWorkspaceName = $lgaWorkspace.Name
        $lgaWorkspaceSharedKey = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName "$RESOURCE_GROUP_POWERBI" -Name "$lgaWorkspaceName" -ErrorAction SilentlyContinue
        if ($null -eq $lgaWorkspaceSharedKey) {
            Write-Warning ("Could not get the shared key for the following LGA Workspace " + "$lgaWorkspaceName" + ". Please correct this before proceeding with KeyVault deployment.")
        }
        else { 
            $keyVault_secret_lgaWorkspaceSharedKey = $lgaWorkspaceSharedKey.PrimarySharedKey
            Write-Output "##vso[task.setvariable variable=keyVault_secret_lgaWorkspaceSharedKey]$keyVault_secret_lgaWorkspaceSharedKey" 
        }
    }
}
else { 
    $lgaWorkspace = Get-AzOperationalInsightsWorkspace -Name "$KEYVAULT_EXISTING_NAME" -ErrorAction SilentlyContinue
    $lgaWorkspaceSharedKey = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName "$RESOURCE_GROUP_POWERBI" -Name "$KEYVAULT_EXISTING_NAME" -ErrorAction SilentlyContinue
    if (($null -eq $lgaWorkspace) -or ($null -eq $lgaWorkspaceSharedKey)) {
        Write-Warning ("Could not get the following LGA Workspace " + "$KEYVAULT_EXISTING_NAME" + ". Please correct this before proceeding with KeyVault deployment.")
    }
    else {
        # LGA workspace id 
        $keyVault_secret_lgaWorkspaceId = $lgaWorkspace.CustomerId
        Write-Host "keyVault_secret_lgaWorkspaceId equal " $keyVault_secret_lgaWorkspaceId
        Write-Output "##vso[task.setvariable variable=keyVault_secret_lgaWorkspaceId]$keyVault_secret_lgaWorkspaceId" 
        # LGA Shared key 
        $keyVault_secret_lgaWorkspaceSharedKey = $lgaWorkspaceSharedKey.PrimarySharedKey
        Write-Output "##vso[task.setvariable variable=keyVault_secret_lgaWorkspaceSharedKey]$keyVault_secret_lgaWorkspaceSharedKey" 
    }
}

# sql connection string
$keyVault_secret_sqlConnectionString = "Server =$sqlServerName.database.windows.net; Database =$SQL_DATABASE_NAME; User ID =$SQL_ADMINISTRATOR_USERNAME; Password =$SQL_ADMINISTRATOR_PASSWORD;"
Write-Output "##vso[task.setvariable variable=keyVault_secret_sqlConnectionString]$keyVault_secret_sqlConnectionString"

# power bi username and password
$keyVault_secret_pbiUsername = $PBI_ADMIN_USERNAME
$keyVault_secret_pbiPwd = $PBI_ADMIN_PASSWORD
Write-Output "##vso[task.setvariable variable=keyVault_secret_pbiUsername]$keyVault_secret_pbiUsername"
Write-Output "##vso[task.setvariable variable=keyVault_secret_pbiPwd]$keyVault_secret_pbiPwd"