function Invoke-WithTemporarySqlServerFirewallAllowance (
    [Parameter(Mandatory = $true)] [string] $ipToAllow,
    [Parameter(Mandatory = $true)] [string] $serverName,
    [Parameter(Mandatory = $true)] [string] $resourceGroupName,
    [Parameter(Mandatory = $true)] [string] $temporaryFirewallName,
    [Parameter(Mandatory = $true)] [scriptblock] $codeToExecute
) {

    Write-Host "Adding temporary firewall rule '$temporaryFirewallName' to SQL server '$serverName' for '$ipToAllow'"
    if (Get-AzSqlServerFirewallRule -FirewallRuleName $temporaryFirewallName -ResourceGroupName $resourceGroupName -ServerName $serverName -ErrorAction SilentlyContinue) {
        Set-AzSqlServerFirewallRule -FirewallRuleName $temporaryFirewallName -ResourceGroupName $resourceGroupName -ServerName $serverName `
            -StartIpAddress $ipToAllow -EndIpAddress $ipToAllow | Out-Null
    }
    else {
        New-AzSqlServerFirewallRule -FirewallRuleName $temporaryFirewallName -ResourceGroupName $resourceGroupName -ServerName $serverName `
            -StartIpAddress $ipToAllow -EndIpAddress $ipToAllow | Out-Null
    }


    try {
        & $codeToExecute
    }
    finally {
        $existingLocks = Get-AzResourceLock -ResourceGroupName $resourceGroupName -AtScope
        $existingLocks | ForEach-Object {
            Write-Host "Temporarily removing resource lock '$($_.Name)' on resource group '$resourceGroupName'"
            Remove-AzResourceLock -LockId $_.LockId -Confirm:$false -Force | Out-Null
        }
        do {
            Start-Sleep 5
        } until ($null -eq (Get-AzResourceLock -ResourceGroupName $resourceGroupName -AtScope))
        try {
            Write-Host "Removing temporary firewall rule '$temporaryFirewallName' from SQL server '$serverName'"
            Remove-AzSqlServerFirewallRule -FirewallRuleName $temporaryFirewallName -ResourceGroupName $resourceGroupName -ServerName $serverName -Confirm:$false -Force | Out-Null
        }
        finally {
            $existingLocks | ForEach-Object {
                Write-Host "Adding back resource lock '$($_.Name)' on resource group '$resourceGroupName'"
                New-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $_.Name -LockLevel $_.Properties.level -LockNotes $_.Properties.notes -Confirm:$false -Force | Out-Null
            }
        }
    }
}

function Invoke-WithTemporarySynapseFirewallAllowance (
    [Parameter(Mandatory = $true)] [string] $ipToAllow,
    [Parameter(Mandatory = $true)] [string] $workspaceName,
    [Parameter(Mandatory = $true)] [string] $resourceGroupName,
    [Parameter(Mandatory = $true)] [string] $temporaryFirewallName,
    [Parameter(Mandatory = $true)] [scriptblock] $codeToExecute
) {
    Import-Module -Name 'Az.Synapse' -RequiredVersion '0.17.0' -Force -Verbose:$false

    Write-Host "Adding temporary firewall rule '$temporaryFirewallName' to Synapse Workspace '$workspaceName' for '$ipToAllow'"
    if (Get-AzSynapseFirewallRule -Name $temporaryFirewallName -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -ErrorAction SilentlyContinue) {
        Update-AzSynapseFirewallRule -Name $temporaryFirewallName -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName `
            -StartIpAddress $ipToAllow -EndIpAddress $ipToAllow | Out-Null
    }
    else {
        New-AzSynapseFirewallRule -Name $temporaryFirewallName -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName `
            -StartIpAddress $ipToAllow -EndIpAddress $ipToAllow | Out-Null
    }

    try {
        & $codeToExecute
    }
    finally {
        $existingLocks = Get-AzResourceLock -ResourceGroupName $resourceGroupName -AtScope
        $existingLocks | ForEach-Object {
            Write-Host "Temporarily removing resource lock '$($_.Name)' on resource group '$resourceGroupName'"
            Remove-AzResourceLock -LockId $_.LockId -Confirm:$false -Force | Out-Null
        }
        do {
            Start-Sleep 5
        } until ($null -eq (Get-AzResourceLock -ResourceGroupName $resourceGroupName -AtScope))
        try {
            Write-Host "Removing temporary firewall rule '$temporaryFirewallName' from Synapse Workspace '$workspaceName'"
            Remove-AzSynapseFirewallRule -Name $temporaryFirewallName -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Confirm:$false -Force | Out-Null
        }
        finally {
            $existingLocks | ForEach-Object {
                Write-Host "Adding back resource lock '$($_.Name)' on resource group '$resourceGroupName'"
                New-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $_.Name -LockLevel $_.Properties.level -LockNotes $_.Properties.notes -Confirm:$false -Force | Out-Null
            }
        }
    }
}

function Invoke-WithTemporarySynapseSqlAdmin (
    [Parameter(Mandatory = $true)] [guid] $objectIdToAllow,
    # If we are allowing a service principal then we need to add it via its application id
    # We still need the object id though in case we are adding it to a group
    [Parameter(Mandatory = $false)] [guid] $servicePrincipalApplicationIdToAllow,
    [Parameter(Mandatory = $true)] [string] $displayNameToAllow,
    [Parameter(Mandatory = $true)] [string] $workspaceName,
    [Parameter(Mandatory = $true)] [string] $resourceGroupName,
    [Parameter(Mandatory = $true)] [scriptblock] $codeToExecute
) {
    Import-Module -Name 'Az.Synapse' -RequiredVersion '0.17.0' -Force -Verbose:$false

    $existingSqlAzureAdAdmin = Get-AzSynapseSqlActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName
    $currentUserIsSqlAdmin = $existingSqlAzureAdAdmin.ObjectId -eq $objectIdToAllow -or ($servicePrincipalApplicationIdToAllow -and $existingSqlAzureAdAdmin.ObjectId -eq $servicePrincipalApplicationIdToAllow)

    try {
        if (-not $currentUserIsSqlAdmin) {
            Write-Host "Temporarily setting group $displayNameToAllow ($objectIdToAllow) as the Azure AD admin on the Synapse SQL"
            Set-AzSynapseSqlActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -ObjectId $objectIdToAllow | Out-Null
        }

        $sqlDatabaseAadToken = (Get-AzAccessToken -ResourceUrl "https://sql.azuresynapse.net" | Select-Object -ExpandProperty Token)
        Invoke-Command $codeToExecute -ArgumentList $sqlDatabaseAadToken

    }
    finally {
        # set synapse admin back
        Write-Host "Setting $($existingSqlAzureAdAdmin.DisplayName) back as the Azure AD admin on the SQL Server."
        Set-AzSynapseSqlActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -ObjectId $existingSqlAzureAdAdmin.ObjectId | Out-Null
    }
}

function Invoke-WithTemporarySqlServerAdmin (
    [Parameter(Mandatory = $true)] [guid] $objectIdToAllow,
    # If we are allowing a service principal then we need to add it via its application id
    # We still need the object id though in case we are adding it to a group
    [Parameter(Mandatory = $false)] [guid] $servicePrincipalApplicationIdToAllow,
    [Parameter(Mandatory = $true)] [string] $displayNameToAllow,
    [Parameter(Mandatory = $true)] [string] $serverName,
    [Parameter(Mandatory = $true)] [string] $resourceGroupName,
    [Parameter(Mandatory = $true)] [scriptblock] $codeToExecute
) {

    $existingSqlAzureAdAdmin = Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -ServerName $serverName
    $currentUserIsSqlAdmin = $existingSqlAzureAdAdmin.ObjectId -eq $objectIdToAllow -or ($servicePrincipalApplicationIdToAllow -and $existingSqlAzureAdAdmin.ObjectId -eq $servicePrincipalApplicationIdToAllow)
    $currentSqlAdminGroup = Get-AzADGroup -ObjectId $existingSqlAzureAdAdmin.ObjectId -ErrorAction SilentlyContinue

    try {
        if (-not $currentUserIsSqlAdmin) {
            if ($currentSqlAdminGroup) {
                Write-Host "Temporarily adding user / service principal $displayNameToAllow ($objectIdToAllow) to the Azure AD group $($currentSqlAdminGroup.DisplayName) ($($existingSqlAzureAdAdmin.ObjectId)) that is admin on the SQL Server."
                $userisAlreadyAddedToGroup = $currentSqlAdminGroup | Get-AzADGroupMember | Where-Object { $_.Id -eq $objectIdToAllow }
                if (-not $userisAlreadyAddedToGroup) {
                    Add-AzADGroupMember -MemberObjectId $objectIdToAllow -TargetGroupObjectId $existingSqlAzureAdAdmin.ObjectId -ErrorAction SilentlyContinue
                    Write-Host "Sleeping for 5s to allow group membership to propagate"
                    Start-Sleep -Seconds 5
                    $userisNowAddedtoGroup = $currentSqlAdminGroup | Get-AzADGroupMember | Where-Object { $_.Id -eq $objectIdToAllow }
                    if (-not $userisNowAddedtoGroup) {
                        Write-Warning ("⚠️  Cannot add the user / service principal $displayNameToAllow ($objectIdToAllow) to Azure AD group $($currentSqlAdminGroup.DisplayName) ($($existingSqlAzureAdAdmin.ObjectId)). Instead temporarily changing the admin to this user.")
                        $currentSqlAdminGroup = $null
                    }
                }
                else {
                    Write-Host "User / service principal $displayNameToAllow ($objectIdToAllow) is already a member of Azure AD group $($currentSqlAdminGroup.DisplayName) ($($existingSqlAzureAdAdmin.ObjectId)) that is admin on the SQL Server."
                }
            }
            if (-not $currentSqlAdminGroup) {
                Write-Host "Temporarily setting user / service principal $displayNameToAllow ($objectIdToAllow) as the Azure AD admin on the SQL Server"
                if ($servicePrincipalApplicationIdToAllow -and $servicePrincipalApplicationIdToAllow -ne [guid]::Empty) {
                    $objectIdToAllow = $servicePrincipalApplicationIdToAllow
                }
                Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -ServerName $serverName -DisplayName $displayNameToAllow -ObjectId $objectIdToAllow | Out-Null
            }
        }

        $sqlDatabaseAadToken = Get-AzAccessToken -ResourceUrl "https://database.windows.net/" | Select-Object -ExpandProperty Token

        Invoke-Command $codeToExecute -ArgumentList $sqlDatabaseAadToken

    }
    finally {
        if (-not $currentUserIsSqlAdmin) {
            if ($currentSqlAdminGroup) {
                if (-not $userisAlreadyAddedToGroup) {
                    Write-Host "Removing user / service principal $displayNameToAllow ($objectIdToAllow) from the Azure AD group $($currentSqlAdminGroup.DisplayName) ($($existingSqlAzureAdAdmin.ObjectId)) that is admin on the SQL Server."
                    Remove-AzADGroupMember -MemberObjectId $objectIdToAllow -GroupObjectId $existingSqlAzureAdAdmin.ObjectId -ErrorAction SilentlyContinue | Out-Null
                }
            }
            else {
                Write-Host "Setting $($existingSqlAzureAdAdmin.DisplayName) back as the Azure AD admin on the SQL Server."
                Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -ServerName $serverName -DisplayName $existingSqlAzureAdAdmin.DisplayName -ObjectId $existingSqlAzureAdAdmin.ObjectId | Out-Null
            }
        }
    }
}

function Get-SqlConnection(
    [Parameter(Mandatory = $true)]
    [string] $server,
    [Parameter(Mandatory = $true)]
    [string] $database,
    [Parameter(Mandatory = $true, ParameterSetName = "password")]
    [string] $username,
    [Parameter(Mandatory = $true, ParameterSetName = "password")]
    [securestring] $password,
    [Parameter(Mandatory = $true, ParameterSetName = "token")]
    [string] $token
) {
    $connectionString = "Data Source=$server;Initial Catalog=$database;Trusted_Connection=False;Encrypt=True;"
    $connection = new-object -TypeName system.data.SqlClient.SQLConnection
    $connection.ConnectionString = $connectionString

    if ($password) {
        if (-not $password.IsReadOnly()) {
            $password.MakeReadOnly()
        }
        $connection.Credential = New-Object -TypeName "System.Data.SqlClient.SqlCredential" -ArgumentList $username, $password
    }
    else {
        $connection.AccessToken = $token
    }
    $connection.Open()
    return $connection
}

function Test-SqlTableExists([System.Data.IDbConnection] $connection, [string] $schema, [string] $tableName) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @tablename"
    $cmd.Parameters.Add((New-Object -TypeName "System.Data.SqlClient.SqlParameter" -ArgumentList "schema", $schema)) | Out-Null
    $cmd.Parameters.Add((New-Object -TypeName "System.Data.SqlClient.SqlParameter" -ArgumentList "tablename", $tableName)) | Out-Null
    $result = $cmd.ExecuteScalar()

    if ($result -gt 0) {
        return $true
    }
    else {
        return $false
    }
}

function Set-SqlLogin([System.Data.IDbConnection] $connection, [string] $username, [securestring] $password) {
    $cmd = $connection.CreateCommand()

    $cmd.CommandText = "
        DECLARE @u nvarchar(MAX);
        DECLARE @p nvarchar(MAX);
        SELECT @u = quotename(@username), @p = quotename(@password, '''');

        IF NOT EXISTS (SELECT name from sys.sql_logins WHERE name = @username)
            EXEC('CREATE LOGIN ' + @u + ' WITH PASSWORD = ' + @p);
        ELSE
            EXEC('ALTER LOGIN ' + @u + ' WITH PASSWORD = ' + @p);
    "

    $passwordPlain = ConvertFrom-SecureString -AsPlainText -SecureString $password
    $cmd.Parameters.Add((New-Object -TypeName "System.Data.SqlClient.SqlParameter" -ArgumentList "username", $username)) | Out-Null
    $cmd.Parameters.Add((New-Object -TypeName "System.Data.SqlClient.SqlParameter" -ArgumentList "password", $passwordPlain)) | Out-Null
    $cmd.ExecuteNonQuery() | Out-Null
}

function ConvertTo-SidFromAzureADGuid([guid] $objectId) {
    return "0x" + (($objectId.ToByteArray() | ForEach-Object ToString X2) -Join '')
}

function Set-SqlPermissions(
    [Parameter(Mandatory)]
    [System.Data.IDbConnection] $connection,
    [Parameter(Mandatory)]
    [string] $username,
    [Parameter(Mandatory)]
    [string[]] $permissions,
    [Parameter(Mandatory, ParameterSetName = "AzureADServicePrincipalApplicationId")]
    [Parameter(Mandatory, ParameterSetName = "AzureADUserObjectId")]
    [Parameter(Mandatory, ParameterSetName = "AzureADGroupObjectId")]
    [guid]
    $azureADId,
    [Parameter(Mandatory, ParameterSetName = "LocalSqlUser")]
    [Switch] $isLocalSqlUser,
    [Parameter(Mandatory, ParameterSetName = "AzureADPrincipal")]
    [Switch] $isAzureADPrincipalName,
    [Parameter(Mandatory, ParameterSetName = "AzureADServicePrincipalApplicationId")]
    [Switch] $isAzureADPrincipalApplicationId,
    [Parameter(Mandatory, ParameterSetName = "AzureADUserObjectId")]
    [Switch] $isAzureADUserObjectId,
    [Parameter(Mandatory, ParameterSetName = "AzureADGroupObjectId")]
    [Switch] $isAzureADGroupObjectId
) {
    $cmd = $connection.CreateCommand()

    if ($isAzureADPrincipalName) {
        $cmd.CommandText = "
            DECLARE @u nvarchar(MAX);
            SELECT @u = quotename(@username);

            IF NOT EXISTS (SELECT name from sys.database_principals WHERE name = @username)
                EXEC('CREATE USER ' + @u + ' FROM EXTERNAL PROVIDER');
        "

    }
    elseif ($isLocalSqlUser) {
        $cmd.CommandText = "
            DECLARE @u nvarchar(MAX);
            SELECT @u = quotename(@username);

            IF NOT EXISTS (SELECT name from sys.database_principals WHERE name = @username)
                EXEC('CREATE USER ' + @u + ' FROM LOGIN ' + @u);
        "
    }
    elseif ($isAzureADPrincipalApplicationId -or $isAzureADUserObjectId) {
        $cmd.CommandText = "
            DECLARE @u nvarchar(MAX);
            SELECT @u = quotename(@username);

            IF NOT EXISTS (SELECT name from sys.database_principals WHERE name = @username)
                EXEC('CREATE USER ' + @u + ' WITH SID = ' + @sid + ', Type = E');
        "
    }
    elseif ($isAzureADGroupObjectId) {
        $cmd.CommandText = "
            DECLARE @u nvarchar(MAX);
            SELECT @u = quotename(@username);

            IF NOT EXISTS (SELECT name from sys.database_principals WHERE name = @username)
                EXEC('CREATE USER ' + @u + ' WITH SID = ' + @sid + ', Type = X');
        "
    }
    else {
        throw "Unknown parameter set for Set-SqlPermissions"
    }

    foreach ($permission in $permissions) {
        if ($permission.ToUpper() -eq "EXECUTE") {
            $cmd.CommandText += "
                EXEC('GRANT EXECUTE TO ' + @u);
            "
        }
        elseif ($permission.ToUpper() -clike "CREATE*" -or $permission.ToUpper() -clike "DROP*") {
            $cmd.CommandText += "
                EXEC('GRANT $permission TO ' + @u);
            "
        }
        elseif ($permission.ToUpper() -clike "CONTROL SCHEMA:*") {
            $schema = $permission.Split(":")[1]
            $cmd.CommandText += "
                EXEC('IF NOT EXISTS (SELECT 1 FROM sys.schemas S WHERE S.[name] = ''$schema'') EXEC(''CREATE SCHEMA $schema'')');
                EXEC('GRANT CONTROL ON SCHEMA::$schema TO ' + @u);
            "
        }
        elseif ($permission.ToUpper() -eq "CONTROL") {
            $schema = $permission.Split(":")[1]
            $cmd.CommandText += "
                EXEC('GRANT CONTROL TO ' + @u);
            "
        }
        else {
            $cmd.CommandText += "
                EXEC sp_addrolemember '$permission', @username;
            "
        }
    }

    $cmd.Parameters.Add((New-Object -TypeName "System.Data.SqlClient.SqlParameter" -ArgumentList "username", $username)) | Out-Null
    if ($isAzureADPrincipalApplicationId -or $isAzureADUserObjectId -or $isAzureADGroupObjectId) {
        $cmd.Parameters.Add((New-Object -TypeName "System.Data.SqlClient.SqlParameter" -ArgumentList "sid", (ConvertTo-SidFromAzureADGuid $azureADId))) | Out-Null
    }
    $cmd.ExecuteNonQuery() | Out-Null
}

function Get-PostgresqlConnection([string] $server, [string] $port, [string] $database, [string] $username, [securestring] $password) {

    Add-Type -Path "$PSScriptRoot\System.Runtime.CompilerServices.Unsafe.dll"
    Add-Type -Path "$PSScriptRoot\System.Threading.Tasks.Extensions.dll"
    Add-Type -Path "$PSScriptRoot\System.ValueTuple.dll"
    Add-Type -Path "$PSScriptRoot\Npgsql.dll"

    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    $connectionString = "Host=$server;Port=$port;Username=$username;Password=""$plainPassword"";Database=$database;SSL Mode=Require"
    $connection = New-Object Npgsql.NpgsqlConnection;
    $connection.ConnectionString = $connectionString
    $connection.Open()

    return $connection
}

function Set-PostgresqlLogin([System.Data.IDbConnection] $connection, [string] $username, [securestring] $password) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "

        CREATE OR REPLACE FUNCTION UpsertUser(username varchar, password varchar) RETURNS void
        AS `$`$
        DECLARE
	        dynamicSql VARCHAR;
        BEGIN

            IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = username) THEN
		        dynamicSql := 'CREATE ROLE ' || quote_ident(username) || ' WITH LOGIN PASSWORD ' || quote_literal(password) || ';';
            ELSE
                dynamicSql := 'ALTER USER ' || quote_ident(username) || ' WITH PASSWORD ' || quote_literal(password) || ';';
            END IF;

            --raise notice '%',dynamicSql;
            EXECUTE dynamicSql;
        END;
        `$`$ language plpgsql;
    "
    $cmd.ExecuteNonQuery() | Out-Null


    $cmd2 = $connection.CreateCommand()
    $cmd2.CommandText = "UpsertUser"
    $cmd2.CommandType = "StoredProcedure"
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    $cmd2.Parameters.AddWithValue("username", $username) | Out-Null
    $cmd2.Parameters.AddWithValue("password", $plainPassword) | Out-Null
    $cmd2.ExecuteNonQuery() | Out-Null
}

function Set-PostgresqlDatabasePermissions([System.Data.IDbConnection] $connection, [string] $username, [string] $database, [string[]] $permissions) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "

        CREATE OR REPLACE FUNCTION GrantDatabasePermission(username varchar, database varchar, permission varchar) RETURNS void
        AS `$`$
        DECLARE
	        dynamicSql VARCHAR;
        BEGIN
            dynamicSql := 'GRANT ' || permission || ' ON DATABASE ' || quote_ident(database) || ' TO ' || quote_ident(username) || ';';
            --raise notice '%',dynamicSql;
            EXECUTE dynamicSql;
        END;
        `$`$ language plpgsql;
    "
    $cmd.ExecuteNonQuery() | Out-Null


    foreach ($permission in $permissions) {
        $cmd2 = $connection.CreateCommand()
        $cmd2.CommandText = "GrantDatabasePermission"
        $cmd2.CommandType = "StoredProcedure"
        $cmd2.Parameters.AddWithValue("username", $username) | Out-Null
        $cmd2.Parameters.AddWithValue("database", $database) | Out-Null
        $cmd2.Parameters.AddWithValue("permission", $permission) | Out-Null
        $cmd2.ExecuteNonQuery() | Out-Null
    }
}

function Set-PostgresqlPermissions([System.Data.IDbConnection] $connection, [string] $username, [string] $permissionType, [string[]] $permissions) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "

        CREATE OR REPLACE FUNCTION GrantPermission(username varchar, permissiontype varchar, permission varchar) RETURNS void
        AS `$`$
        DECLARE
	        dynamicSql VARCHAR;
        BEGIN
            dynamicSql := 'GRANT ' || permission || ' ON ' || permissiontype || ' TO ' || quote_ident(username) || ';';
            --raise notice '%',dynamicSql;
            EXECUTE dynamicSql;
        END;
        `$`$ language plpgsql;
    "
    $cmd.ExecuteNonQuery() | Out-Null

    foreach ($permission in $permissions) {
        $cmd2 = $connection.CreateCommand()
        $cmd2.CommandText = "GrantPermission"
        $cmd2.CommandType = "StoredProcedure"
        $cmd2.Parameters.AddWithValue("username", $username) | Out-Null
        $cmd2.Parameters.AddWithValue("permissiontype", $permissionType) | Out-Null
        $cmd2.Parameters.AddWithValue("permission", $permission) | Out-Null
        $cmd2.ExecuteNonQuery() | Out-Null
    }
}

Export-ModuleMember -Function * -Verbose:$false
