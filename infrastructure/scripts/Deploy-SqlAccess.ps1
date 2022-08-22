[CmdletBinding(SupportsShouldProcess = $true)]
Param (
    [ValidatePattern("[a-zA-Z0-9\-]{3,24}")]
    [Parameter(Mandatory = $true)]
    [string] $EnvironmentName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9]{1,5}")]
    [string] $EnvironmentCode,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9]{1,5}")]
    [string] $Location,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9\-]{3,24}")]
    [string] $LocationCode,

    [Parameter(Mandatory = $true)]
    [string] $TenantId,

    [Parameter(Mandatory = $true)]
    [string] $SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string] $ConfigFile = "config.$($EnvironmentCode.ToLower()).json",

    [Parameter(Mandatory = $true)]
    [string] $sqlServerName,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $databasesObject,

    [Parameter(Mandatory = $true)]
    [string] $functionAppServicePrincipalId,

    [Parameter(Mandatory = $true)]
    [string] $webAppServicePrincipalId,

    [Parameter(Mandatory = $true)]
    [string] $dataFactoryPrincipalId,

    [Parameter(Mandatory = $true)]
    [string] $keyVaultName,

    [Parameter(Mandatory = $false)]
    [string] $deploymentKeyVaultName,

    [Parameter(Mandatory = $true)]
    [string] $keyVaultResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerManagedIdentity,

    [Parameter(Mandatory = $false)]
    [string] $synapseWorkspaceName
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/sql.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/azuread.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$databases = ConvertFrom-JsonToHash -Object $databasesObject

try {

    if ($VerbosePreference -eq "SilentlyContinue" -and $Env:SYSTEM_DEBUG) {
        $VerbosePreference = "Continue"
    }

    if (-not $pscmdlet.ShouldProcess("Deploy with powershell")) {
        Write-Verbose "-WhatIf is set, will not execute deployment."

        Write-Host "Deploy would proceed with the following parameters"
        $Context | Format-Table | Out-String | Write-Host
    }
    else {
        $Context | Format-Table | Out-String | Write-Verbose

        ###############################################################################
        ## Azure AD Directory Readers Role for SQL Server Managed Identity
        ###############################################################################

        if ($Context.sqlAccess.azureADDirectoryReadersRoleADGroup) {

            $azureGraphApiAadToken = Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com' | Select-Object -ExpandProperty Token

            Write-Host "$(Get-Date -Format FileDateTimeUniversal) Ensuring SQL Server Managed Identity has permissions to perform SQL Access task"

            if (-not (Assert-Guid $Context.sqlAccess.azureADDirectoryReadersRoleADGroup)) {
                Write-Host "Obtaining GUID for Azure AD Directory Readers Role Group."
                $group = Get-OrNewAzureADGroup -azureGraphApiAadToken $azureGraphApiAadToken `
                    -displayName $Context.sqlAccess.azureADDirectoryReadersRoleADGroup -isAssignableToRole -isSecurityEnabled `
                    -description "This group is assigned to Directory built-in role of Azure AD."
                $groupId = $group.id
            }
            else {
                Write-Host "Azure AD Directory Readers Role Group is a GUID. Assuming the GUID is a valid group."
                $groupId = $Context.sqlAccess.azureADDirectoryReadersRoleADGroup
            }

            if (Assert-Guid $groupId) {
                Write-Host "Validating if Azure AD Group has role assignment 'Directory Readers'."
                if (Get-OrAddAzureADRoleAssignment -azureGraphApiAadToken $azureGraphApiAadToken -principalId $groupId -roledisplayName "Directory Readers") {
                    Write-Host "Azure AD Group has role assignement 'Directory Readers'. Checking/addding SQL Managed Identity to this group."
                    $group = Get-AzADGroup -ObjectId $groupId -ErrorAction SilentlyContinue
                    $userisAlreadyAddedtoGroup = $group | Get-AzADGroupMember | Where-Object { $_.Id -eq $sqlServerManagedIdentity }
                    if (-not $userisAlreadyAddedtoGroup) {
                        Add-AzADGroupMember -MemberObjectId $sqlServerManagedIdentity -TargetGroupObjectId $groupId -ErrorAction SilentlyContinue
                        $userisNowAddedtoGroup = $group | Get-AzADGroupMember | Where-Object { $_.Id -eq $sqlServerManagedIdentity }
                        if (-not $userisNowAddedtoGroup) {
                            throw ("Cannot add the SQL Server Managed Identity (" + $sqlServerManagedIdentity + ") to Azure AD group " + $group.DisplayName + " (" + $group.Id + "). Please do this manaully and rerun this script.")
                        }
                        else {
                            Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Added SQL Server Managed Identity as a member of the Azure AD group $($group.DisplayName) ($($group.Id))`r`n"
                        }
                    }
                    else {
                        Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) SQL Server Managed Identity is already a member of the Azure AD group $($group.DisplayName) ($($group.Id))`r`n"
                    }
                }
                else {
                    Write-Warning "⚠️  An Azure AD Group exists but the script could not assign it Azure AD Directory Readers Role rights. Please visit https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-directory-readers-role-tutorial#directory-readers-role-assignment-using-powershell and run the PowerShell cmdlets with a suitably authorised account (E.g. Global Administrator or Privileged Roles Administrator). Note: `r`n-Use the existing Azure AD Group ""$($Context.sqlAccess.azureADDirectoryReadersRoleADGroup)"" ($groupId)`r`n-Set `$miIdentity as `"$sqlServerManagedIdentity`" `r`n-Change subsequent lines `$miIdentity.ObjectId to be `$miIdentity`r`n"
                }
            }
            else {
                Write-Warning "⚠️  Can't create Azure AD Group for Azure AD Directory Readers Role assignment. Please visit https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-directory-readers-role-tutorial#directory-readers-role-assignment-using-powershell and run the PowerShell cmdlets with a suitably authorised account (E.g. Global Administrator or Privileged Roles Administrator). Note: `r`n-Set `$miIdentity as `"$sqlServerManagedIdentity`" `r`n-Change subsequent lines `$miIdentity.ObjectId to be `$miIdentity`r`n"
            }

        }

        ###############################################################################
        ## Sql Access
        ###############################################################################

        Write-Host "$(Get-Date -Format FileDateTimeUniversal) Ensuring SQL Server and Database access permissions are correct."

        $datafactoryUser = (Get-AzADServicePrincipal -ObjectId $dataFactoryPrincipalId).DisplayName
        $functionsUser = (Get-AzADServicePrincipal -ObjectId $functionAppServicePrincipalId).DisplayName
        $webAppUser = (Get-AzADServicePrincipal -ObjectId $webAppServicePrincipalId).DisplayName

        if (-not $Context.sqlAccess.azureADDirectoryReadersRoleADGroup) {
            $datafactoryUserApplicationId = (Get-AzADServicePrincipal -ObjectId $dataFactoryPrincipalId).ApplicationId
            $functionsUserApplicationId = (Get-AzADServicePrincipal -ObjectId $functionAppServicePrincipalId).ApplicationId
            $webAppUserApplicationId = (Get-AzADServicePrincipal -ObjectId $webAppServicePrincipalId).ApplicationId
        }
        else {
            $datafactoryUserApplicationId = $null
            $functionsUserApplicationId = $null
            $webAppUserApplicationId = $null
        }

        # Databricks doesn't support service principal auth to SQL yet
        $databricksUser = $Context.sqlUserNames.databricks

        Invoke-WithTemporaryKeyVaultFirewallAllowance -ipToAllow (Get-CurrentIP) -keyVaultName $keyVaultName -resourceGroup $keyVaultResourceGroupName `
            -codeToExecute `
        {
            Write-Host "Getting databricks sql user password"
            $global:databricksSqlPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "databricksSqlPassword" | Select-Object -ExpandProperty SecretValue
        }

        Invoke-WithTemporarySqlServerFirewallAllowance -ipToAllow (Get-CurrentIP) `
            -serverName $sqlServerName -resourceGroupName $sqlServerResourceGroupName `
            -temporaryFirewallName "Azure DevOps" `
            -codeToExecute `
        {
            Invoke-WithTemporarySqlServerAdmin -objectId ([guid](Get-CurrentUserAzureAdObjectId)) -displayName (Get-CurrentUserAzureAdName) `
                -servicePrincipalApplicationIdToAllow (Get-CurrentServicePrincipalAzureAdApplicationId) `
                -serverName $sqlServerName -resourceGroupName $sqlServerResourceGroupName `
                -codeToExecute `
            {
                param($sqlDatabaseAadToken)

                # master
                Write-Host "----- Granting access permissions to master database"
                $masterConnection = Get-SqlConnection -server "$sqlServerName.database.windows.net" -database "master" -token $sqlDatabaseAadToken
                Write-Host "Ensuring $databricksUser login exists for server"
                Set-SqlLogin -connection $masterConnection -username $databricksUser -password $global:databricksSqlPassword

                Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Successfully ran SQL call to set login for $sqlServerName/$databricksUser`r`n"

                # ADP_Config
                $configDatabaseName = $databases.Config
                Write-Host "----- Granting access permissions to $configDatabaseName database"
                $configConnection = Get-SqlConnection -server "$sqlServerName.database.windows.net" -database $configDatabaseName -token $sqlDatabaseAadToken

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter to $webAppUser"
                if ($webAppUserApplicationId) {
                    Set-SqlPermissions -connection $configConnection -username $webAppUser -azureADId $webAppUserApplicationId -isAzureADPrincipalApplicationId -permissions @("EXECUTE", "db_datareader", "db_datawriter")
                }
                else {
                    Set-SqlPermissions -connection $configConnection -username $webAppUser -isAzureADPrincipalName -permissions @("EXECUTE", "db_datareader", "db_datawriter")
                }

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter, BypassRLS Role to $datafactoryUser"
                if ($datafactoryUserApplicationId) {
                    Set-SqlPermissions -connection $configConnection -username $datafactoryUser -azureADId $datafactoryUserApplicationId -isAzureADPrincipalApplicationId -permissions @("EXECUTE", "db_datareader", "db_datawriter", "BypassRLS")
                }
                else {
                    Set-SqlPermissions -connection $configConnection -username $datafactoryUser -isAzureADPrincipalName -permissions @("EXECUTE", "db_datareader", "db_datawriter", "BypassRLS")
                }

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter, BypassRLS Role to $databricksUser"
                Set-SqlPermissions -connection $configConnection -username $databricksUser -isLocalSqlUser -permissions @("EXECUTE", "db_datareader", "db_datawriter", "BypassRLS")

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter, BypassRLS Role to $functionsUser"
                if ($functionsUserApplicationId) {
                    Set-SqlPermissions -connection $configConnection -username $functionsUser -azureADId $functionsUserApplicationId -isAzureADPrincipalApplicationId -permissions @("EXECUTE", "db_datareader", "db_datawriter", "BypassRLS")
                }
                else {
                    Set-SqlPermissions -connection $configConnection -username $functionsUser -isAzureADPrincipalName -permissions @("EXECUTE", "db_datareader", "db_datawriter", "BypassRLS")
                }

                Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Successfully ran SQL calls to update access on $sqlServerName/$configDatabaseName`r`n"

                # ADP_Stage
                $stageDatabaseName = $databases.Stage
                Write-Host "----- Granting access permissions to $stageDatabaseName database"
                $stageConnection = Get-SqlConnection -server "$sqlServerName.database.windows.net" -database $stageDatabaseName -token $sqlDatabaseAadToken

                Write-Host "Granting db_owner to $datafactoryUser"
                if ($datafactoryUserApplicationId) {
                    Set-SqlPermissions -connection $stageConnection -username $datafactoryUser -azureADId $datafactoryUserApplicationId -isAzureADPrincipalApplicationId -permissions @("db_owner")
                }
                else {
                    Set-SqlPermissions -connection $stageConnection -username $datafactoryUser -isAzureADPrincipalName -permissions @("db_owner")
                }

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter, db_ddladmin to $functionsUser"
                if ($functionsUserApplicationId) {
                    Set-SqlPermissions -connection $stageConnection -username $functionsUser -azureADId $functionsUserApplicationId -isAzureADPrincipalApplicationId -permissions @("EXECUTE", "db_datareader", 'CREATE TABLE', 'CONTROL SCHEMA:tempstage', 'CONTROL SCHEMA:sap')
                }
                else {
                    Set-SqlPermissions -connection $stageConnection -username $functionsUser -isAzureADPrincipalName -permissions @("EXECUTE", "db_datareader", 'CREATE TABLE', 'CONTROL SCHEMA:tempstage', 'CONTROL SCHEMA:sap')
                }

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter, db_ddladmin to $databricksUser"
                Set-SqlPermissions -connection $stageConnection -username $databricksUser -isLocalSqlUser -permissions @("EXECUTE", "db_datareader", "db_datawriter", "db_ddladmin")

                Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Successfully ran SQL calls to update access on $sqlServerName/$stageDatabaseName`r`n"
            }
        }

        if ($Context.create.synapse) {
            Invoke-WithTemporaryKeyVaultFirewallAllowance -ipToAllow (Get-CurrentIP) -keyVaultName $deploymentKeyVaultName -resourceGroup $keyVaultResourceGroupName `
                -codeToExecute `
            {
                Write-Host "Getting Syanpse sql user password"
                $global:synapseSqlPassword = Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name "SynapseSqlAdminPassword" | Select-Object -ExpandProperty SecretValue
            }

            Invoke-WithTemporarySynapseFirewallAllowance -ipToAllow (Get-CurrentIP) `
                -workspaceName $synapseWorkspaceName -resourceGroupName $sqlServerResourceGroupName `
                -temporaryFirewallName "Azure DevOps" `
                -codeToExecute `
            {
                # master
                Write-Host "----- Granting access permissions to master database"
                $masterConnection = Get-SqlConnection -server "$synapseWorkspaceName.sql.azuresynapse.net" -database "master" -username $Context.sqlUsernames.synapseAdmin -password $global:synapseSqlPassword
                Write-Host "Ensuring $databricksUser login exists for server"
                Set-SqlLogin -connection $masterConnection -username $databricksUser -password $global:databricksSqlPassword

                Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Successfully ran SQL call to set login for $sqlServerName/$databricksUser`r`n"

                # SQL Pool
                $sqlPoolName = $Context.synapse.sqlPoolName
                Write-Host "----- Granting access permissions to $sqlPoolName database"
                $sqlPoolConnection = Get-SqlConnection -server "$synapseWorkspaceName.sql.azuresynapse.net" -database $sqlPoolName -username $Context.sqlUsernames.synapseAdmin -password $global:synapseSqlPassword

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter to $webAppUser"
                if ($webAppUserApplicationId) {
                    Set-SqlPermissions -connection $sqlPoolConnection -username $webAppUser -azureADId $webAppUserApplicationId -isAzureADPrincipalApplicationId -permissions @("EXECUTE", "db_datareader", "db_datawriter")
                }
                else {
                    Set-SqlPermissions -connection $sqlPoolConnection -username $webAppUser -isAzureADPrincipalName -permissions @("EXECUTE", "db_datareader", "db_datawriter")
                }

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter to $datafactoryUser"
                if ($datafactoryUserApplicationId) {
                    Set-SqlPermissions -connection $sqlPoolConnection -username $datafactoryUser -azureADId $datafactoryUserApplicationId -isAzureADPrincipalApplicationId -permissions @("EXECUTE", "db_datareader", "db_datawriter")
                }
                else {
                    Set-SqlPermissions -connection $sqlPoolConnection -username $datafactoryUser -isAzureADPrincipalName -permissions @("EXECUTE", "db_datareader", "db_datawriter")
                }

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter, db_ddladmin, CONTROL to $databricksUser"
                Set-SqlPermissions -connection $sqlPoolConnection -username $databricksUser -isLocalSqlUser -permissions @("EXECUTE", "db_datareader", "db_datawriter", "db_ddladmin", "CONTROL")

                Write-Host "Granting EXECUTE, db_datareader, db_datawriter to $functionsUser"
                if ($functionsUserApplicationId) {
                    Set-SqlPermissions -connection $sqlPoolConnection -username $functionsUser -azureADId $functionsUserApplicationId -isAzureADPrincipalApplicationId -permissions @("EXECUTE", "db_datareader", "db_datawriter")
                }
                else {
                    Set-SqlPermissions -connection $sqlPoolConnection -username $functionsUser -isAzureADPrincipalName -permissions @("EXECUTE", "db_datareader", "db_datawriter")
                }

                Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) Successfully ran SQL calls to update access on $synapseWorkspaceName/$sqlPoolName`r`n"
            }
        }

    }
}
catch {
    Write-Host -ForegroundColor Red "Caught an exception of type $($_.Exception.GetType())"
    Write-Host -ForegroundColor Red $_.Exception.Message

    if ($_.ScriptStackTrace) {
        Write-Host -ForegroundColor Red $_.ScriptStackTrace
    }

    if ($_.Exception.InnerException) {
        Write-Host -ForegroundColor Red "Caused by: $($_.Exception.InnerException.Message)"
    }

    throw
}
