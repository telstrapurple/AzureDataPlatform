Param (
    [Parameter(Mandatory = $true)]
    [string]
    $EnvironmentCode,

    [Parameter(Mandatory = $true)]
    [string]
    $EnvironmentName,

    [Parameter(Mandatory = $true)]
    [string]
    $Location,

    [Parameter(Mandatory = $true)]
    [string]
    $LocationCode,

    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,

    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]
    $ConfigFileName,

    [Parameter(Mandatory = $true)]
    [string]
    $DatabasesLocation,

    [Parameter(Mandatory = $true)]
    [string]
    $InfrastructureScriptsLocation,
    
    [Parameter(Mandatory = $true)]
    [string]
    $MigratorLocation
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

try {
    # Get config information
    $configFilePath = Join-Path -Path $InfrastructureScriptsLocation -ChildPath $ConfigFileName
    Import-Module (Join-Path -Path $InfrastructureScriptsLocation -ChildPath './functions/adp.psm1') -Force -Verbose:$false
    Import-Module (Join-Path -Path $InfrastructureScriptsLocation -ChildPath './functions/sql.psm1') -Force -Verbose:$false
    Import-Module (Join-Path -Path $InfrastructureScriptsLocation -ChildPath './functions/storage.psm1') -Force -Verbose:$false

    $context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath $configFilePath -outputTag:$false

    $deploymentKeyVaultName = Get-ResourceName -context $Context -resourceCode 'AKV' -suffix '002'
    $databaseServerName = (Get-ResourceName -context $Context -resourceCode "SQL" -suffix "001").ToLowerInvariant()
    $databaseServerResourceGroupName = $context.resourceGroupNames.data

    $sqlServerAdminUsername = $context.sqlUsernames.admin
    $sqlServerAdminPassword = (Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'SqlServerAdminPassword').SecretValue | ConvertFrom-SecureString -AsPlainText

    #Get all the values to populate the SQL migration variables
    [string]$logicAppSendEmailUrl = (Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'logicAppSendEmailUrl').SecretValue | ConvertFrom-SecureString -AsPlainText
    [string]$logicAppScaleVMUrl = (Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'logicAppScaleVMUrl').SecretValue | ConvertFrom-SecureString -AsPlainText
    [string]$logicAppScaleSQLUrl = (Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'logicAppScaleSQLUrl').SecretValue | ConvertFrom-SecureString -AsPlainText
    [string]$keyVaultName = Get-ResourceName -context $Context -resourceCode 'KV' -suffix '03'
    [string]$dataLakeStorageEndpoint = (Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'dataLakeStorageEndpoint').SecretValue | ConvertFrom-SecureString -AsPlainText
    [string]$dataLakeDateMask = $context.dataLakeDateMask
    [string]$databricksWorkspaceUrl = (Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'DatabricksWorkspaceUrl').SecretValue | ConvertFrom-SecureString -AsPlainText
    [string]$databricksStandardClusterId = (Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'databricksStandardClusterId').SecretValue | ConvertFrom-SecureString -AsPlainText
    [string]$webAppAdminUPN = $context.webAppAdminUPN
    [string]$stageDatabaseName = $context.stageDatabase.databaseName

    if (!([string]::IsNullOrEmpty($webAppAdminUPN))) {
        $webAppAdminUser = Get-AzADUser -UserPrincipalName $webAppAdminUPN
        [string]$webAppAdminUserId = $webAppAdminUser.Id
        [string]$webAppAdminUsername = $webAppAdminUser.DisplayName
        [string]$webAppAdminUPN = $webAppAdminUPN
    }
    else {
        [string]$webAppAdminUserId = ""
        [string]$webAppAdminUsername = ""
        [string]$webAppAdminUPN = ""
    }

    $configDatabaseName = $context.configDatabase.databaseName
    $stageDatabaseName = $context.stageDatabase.databaseName

    # Get migration variables
    $configMigrationVariables = @{
        "LogicAppSendEmailUrl"        = $logicAppSendEmailUrl;
        "LogicAppScaleVMUrl"          = $logicAppScaleVMUrl;
        "LogicAppScaleSQLUrl"         = $logicAppScaleSQLUrl;
        "KeyVaultName"                = $keyVaultName;
        "DataLakeStorageEndpoint"     = $dataLakeStorageEndpoint;
        "DataLakeDateMask"            = $dataLakeDateMask;
        "DatabricksWorkspaceURL"      = $databricksWorkspaceUrl;
        "DatabricksStandardClusterID" = $databricksStandardClusterId;
        "WebAppAdminUserID"           = $webAppAdminUserId;
        "WebAppAdminUsername"         = $webAppAdminUsername;
        "WebAppAdminUPN"              = $webAppAdminUPN;
        "StageDatabaseName"           = $stageDatabaseName;
    }

    # Temporarily grant access to get through the SQL firewall from the current IP address
    Invoke-WithTemporarySqlServerFirewallAllowance -ipToAllow (Get-CurrentIP) `
        -serverName $databaseServerName -resourceGroupName $databaseServerResourceGroupName `
        -temporaryFirewallName "Azure DevOps" `
        -codeToExecute `
    {
        Add-Type -Path (Join-Path $MigratorLocation "Migrator.dll")

        # Migrate ADP_Config
        Write-Host "Migrating $configDatabaseName database"
        $connectionString = "Server=tcp:" + $databaseServerName + ".database.windows.net,1433;Database=" + $configDatabaseName + ";Trusted_Connection=False;Encrypt=True;" `
            + "User ID=" + $sqlServerAdminUsername + ";Password='" + $sqlServerAdminPassword.Replace("'", "''") + "'"
        $databaseRootFolder = Join-Path $DatabasesLocation "ADP_Config"
        [Migrator.Migrator]::Migrate($databaseRootFolder, $connectionString, $configMigrationVariables)

        # Migrate ADP_Stage
        Write-Host "Migrating $stageDatabaseName database"
        $connectionString = "Server=tcp:" + $databaseServerName + ".database.windows.net,1433;Database=" + $stageDatabaseName + ";Trusted_Connection=False;Encrypt=True;" `
            + "User ID=" + $sqlServerAdminUsername + ";Password='" + $sqlServerAdminPassword.Replace("'", "''") + "'"
        $databaseRootFolder = Join-Path $DatabasesLocation "ADP_Stage"
        [Migrator.Migrator]::Migrate($databaseRootFolder, $connectionString, $null)
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
