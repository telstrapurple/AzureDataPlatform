<#
    .SYNOPSIS 
        Writes Power BI Logs to Azure SQL Database and Log analytics
    .DESCRIPTION 
        
    
    .EXAMPLE
        
    .NOTES
        Pre-requisites: 
            MicrosoftPowerBIMgmt module is installed. If not installed, then run `Install-Module -Name MicrosoftPowerBIMgmt`
#>

Write-Host "Connecting to Azure"
# Connect to Azure
Connect-AzAccount -Identity

Write-Host "Getting KeyVault Secrets"
$keyVaultName = (Get-AzKeyVault)[0].VaultName # MSI should only be granted access to the single KeyVault 
$pbi_username = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "pbiUsername").SecretValueText
$pbi_pwd = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "pbiPwd").SecretValueText
$sql_connectionString = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "sqlConnectionString").SecretValueText
$lga_workspaceId = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "lgaWorkspaceId").SecretValueText
$lga_sharedKey = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "lgaSharedKey").SecretValueText


# Import/Reload modules
Write-Host "Importing Modules"
Import-Module MicrosoftPowerBIMgmt.Profile
Import-Module MicrosoftPowerBIMgmt.Admin
Import-Module MicrosoftPowerBIMgmt.Capacities
Import-Module MicrosoftPowerBIMgmt.Data
Import-Module MicrosoftPowerBIMgmt.Reports
Import-Module MicrosoftPowerBIMgmt.Workspaces 
Write-Host "Modules Imported"

# declare functions
# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
    return $authorization
}


# Create the function to create and post the request
Function Send-LogAnalyticsData($customerId, $sharedKey, $body, $logType) {
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type"      = $logType;
        "x-ms-date"     = $rfc1123date;
        # "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
}


function Get-Type { 
    param($type) 
 
    $types = @( 
        'System.Boolean', 
        'System.Byte[]', 
        'System.Byte', 
        'System.Char', 
        'System.Datetime', 
        'System.Decimal', 
        'System.Double', 
        # 'System.Guid',  # treat Guid as String
        'System.Int16', 
        'System.Int32', 
        'System.Int64', 
        'System.Single', 
        'System.UInt16', 
        'System.UInt32', 
        'System.UInt64') 
 
    if ( $types -contains $type ) { 
        Write-Output "$type" 
    } 
    else { 
        Write-Output 'System.String' 
         
    } 
} #Get-Type 
function Out-DataTable { 
    [CmdletBinding()] 
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)] [PSObject[]]$InputObject,
        [parameter(Mandatory = $false)][Boolean]$userSchema = $false,
        [parameter(Mandatory = $false)][Hashtable]$schema
    ) 
 
    Begin { 
        $dt = new-object Data.datatable   
        $First = $true  
        if ($userSchema) {
            $schema.keys | ForEach-Object {
                $Col = New-Object Data.DataColumn
                $Col.ColumnName = $_
                $value = $schema[$_]
                $Col.DataType = [System.Type]::GetType("$($value)")
                $dt.Columns.Add($Col) 
            }
        }
    } 
    Process { 
        foreach ($object in $InputObject) { 
            $DR = $DT.NewRow()   
            foreach ($property in $object.PsObject.get_properties()) {   
                if ($first -and ($userSchema -eq $false)) {   
                    $Col = new-object Data.DataColumn   
                    $Col.ColumnName = $property.Name.ToString()   
                    if ($property.value) { 
                        if ($property.value -isnot [System.DBNull]) { 
                            $Col.DataType = [System.Type]::GetType("$(Get-Type $property.TypeNameOfValue)") 
                        } 
                    } 
                    $DT.Columns.Add($Col) 
                }
                
                if ($userSchema) {
                    foreach ($key in $schema.keys) {
                        if ($key -eq $property.Name) {
                            if ($property.Gettype().IsArray) { 
                                $DR.Item($property.Name) = $property.value | ConvertTo-Json 
                            }  
                            else { 
                                $DR.Item($property.Name) = $property.value 
                            } 
                        }
                    }
                }
                else { 
                    if ($property.Gettype().IsArray) { 
                        $DR.Item($property.Name) = $property.value | ConvertTo-Json # | ConvertTo-XML -AS String -NoTypeInformation -Depth 1 
                    }  
                    else { 
                        $DR.Item($property.Name) = $property.value 
                    } 
                }
            }   
            $DT.Rows.Add($DR)
            $First = $false 
        } 
    }  
      
    End { 
        Write-Output @(, ($dt)) 
    } 
 
} #Out-DataTable

function Update-SQL {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)][String]$tableName,
        [parameter(Mandatory = $true)][PSObject]$outputData,
        [parameter(Mandatory = $true)][System.Data.SqlClient.SqlConnection]$sqlConn,
        [parameter(Mandatory = $false)][String]$mergeOperation = "IUD" 
    )
    try {
        # truncate tempstage
        $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $sqlCmd.Connection = $sqlConn
        $sqlCmd.CommandTimeout = 0
        $sqlCmd.Connection.Open()
        $sqlCmd.CommandText = "DELETE FROM tempstage.$tableName"
        $output = $sqlCmd.ExecuteNonQuery()
        if ($null -ne $output) {
            Write-Host "Truncated tempstage.$tableName"
        }
        else { 
            Write-Host "Failed to truncate tempstage.$tableName"
        }
        $sqlCmd.Connection.Close()

        # insert to tempstage
        $sqlConn.Open()
        $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($sqlConn)
        foreach ($_ in $outputData[0].Columns) {
            $output = $bulkCopy.ColumnMappings.Add($_.ColumnName, $_.ColumnName)
        }
        $bulkCopy.DestinationTableName = "tempstage.$tableName"
        $output = $bulkCopy.WriteToServer($outputData)
        if ($null -eq $output) {
            $rowCount = $outputData.Rows.Count
            Write-Host "Inserted $rowCount records to tempstage.$tableName"
        }
        else { 
            Write-Host "Failed to insert records to tempstage.$tableName"
        }
        $sqlConn.Close()

        # merge tempstage to pbi table
        $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $sqlCmd.Connection = $sqlConn
        $sqlCmd.CommandTimeout = 0
        $sqlCmd.Connection.Open()
        $sqlCmd.CommandText = "EXEC pbi.usp_GenericMerge @SourceSchema = 'tempstage', @SourceTable = '$tableName', @TargetSchema = 'pbi', @TargetTable = '$tableName', @Operation = '$mergeOperation'"
        $output = $sqlCmd.ExecuteNonQuery()
        if ($null -ne $output) {
            Write-Host "Merged pbi.$tableName. $output records were inserted or updated or deleted"
        }
        else { 
            Write-Host "Failed to merge pbi.$tableName"
        }
        $sqlCmd.Connection.Close()
        return $true
    }
    catch { 
        Write-Error $_
    }
}

function Update-LGASQLTable {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)][String]$sourceSchema,
        [parameter(Mandatory = $true)][String]$sourceTable,
        [parameter(Mandatory = $true)][String]$targetCompareSchema,
        [parameter(Mandatory = $true)][String]$targetCompareTable,
        [parameter(Mandatory = $true)][String]$targetSchema,
        [parameter(Mandatory = $true)][String]$targetTable,
        [parameter(Mandatory = $true)][PSObject]$outputData,
        [parameter(Mandatory = $true)][System.Data.SqlClient.SqlConnection]$sqlConn
    )
    try {
        # truncate tempstage
        $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $sqlCmd.Connection = $sqlConn
        $sqlCmd.CommandTimeout = 0
        $sqlCmd.Connection.Open()
        $sqlCmd.CommandText = "DELETE FROM $sourceSchema.$sourceTable"
        $output = $sqlCmd.ExecuteNonQuery()
        if ($null -ne $output) {
            Write-Host "Truncated $sourceSchema.$sourceTable"
        }
        else { 
            Write-Host "Failed to truncate $sourceSchema.$sourceTable"
        }
        $sqlCmd.Connection.Close()

        # insert to tempstage
        $sqlConn.Open()
        $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($sqlConn)
        foreach ($_ in $outputData[0].Columns) {
            $output = $bulkCopy.ColumnMappings.Add($_.ColumnName, $_.ColumnName)
        }
        $bulkCopy.DestinationTableName = "$sourceSchema.$sourceTable"
        $output = $bulkCopy.WriteToServer($outputData)
        if ($null -eq $output) {
            $rowCount = $outputData.Rows.Count
            Write-Host "Inserted $rowCount records to $sourceSchema.$sourceTable"
        }
        else { 
            Write-Host "Failed to insert records to $sourceSchema.$sourceTable"
        }
        $sqlConn.Close()

        # truncate lga table
        $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $sqlCmd.Connection = $sqlConn
        $sqlCmd.CommandTimeout = 0
        $sqlCmd.Connection.Open()
        $sqlCmd.CommandText = "DELETE FROM $targetSchema.$targetTable"
        $output = $sqlCmd.ExecuteNonQuery()
        if ($null -ne $output) {
            Write-Host "Truncated $targetSchema.$targetTable"
        }
        else { 
            Write-Host "Failed to truncate $targetSchema.$targetTable"
        }
        $sqlCmd.Connection.Close()

        # merge tempstage to lga table
        $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $sqlCmd.Connection = $sqlConn
        $sqlCmd.CommandTimeout = 0
        $sqlCmd.Connection.Open()
        $sqlCmd.CommandText = "EXEC pbi.usp_Get_ActivityEventsDiff @SourceSchema = '$sourceSchema', @SourceTable = '$sourceTable', @TargetCompareSchema = '$targetCompareSchema', @TargetCompareTable = '$targetCompareTable', @TargetSchema = '$targetSchema', @TargetTable = '$targetTable'"
        $output = $sqlCmd.ExecuteNonQuery()
        if ($null -ne $output) {
            Write-Host "Merged $targetSchema.$targetTable. $output records were inserted or updated or deleted"
        }
        else { 
            Write-Host "Failed to merge $targetSchema.$targetTable"
        }
        $sqlCmd.Connection.Close()
        return $true
    }
    catch { 
        Write-Error $_
    }
}

function Set-SQLConstraint {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)][Boolean]$constraint,
        [parameter(Mandatory = $true)][System.Data.SqlClient.SqlConnection]$sqlConn
    )
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.Connection = $sqlConn
    $sqlCmd.CommandTimeout = 0
    $sqlCmd.Connection.Open()
    if ($constraint) {
        $sqlCmd.CommandText = "EXEC pbi.sp_msforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL'"
        
    }
    else {
        $sqlCmd.CommandText = "EXEC pbi.sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'"
    }
    $output = $sqlCmd.ExecuteNonQuery()
    if (($output -eq -1) -and ($constraint -eq $true)) {
        Write-Host "Constraint turned on"
    }
    elseif (($output -eq -1) -and ($constraint -eq $false)) {
        Write-Host "Constraint turned off"
    }
    elseif (($output -ne -1) -and ($constraint -eq $true)) {
        Write-Host "Failed to turn constraint on"
    }
    elseif (($output -ne -1) -and ($constraint -eq $false)) {
        Write-Host "Failed to turn constraint off"
    }
    $sqlCmd.Connection.Close()
}

function Invoke-SQL {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)][String]$sqlCommand,
        [parameter(Mandatory = $true)][System.Data.SqlClient.SqlConnection]$sqlConn
    )
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand, $sqlConn)
    $sqlConn.Open()

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null

    $sqlConn.Close()
    return $dataset.Tables
}

# Function to get row batches
Function Get-RowBatches{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)][int]$totalRowCount,
        [parameter(Mandatory = $true)][int]$batchCount
    )
  $rowCount = $totalRowCount
  $batches = @() # creates an empty powershell array 
  $currentRow = 0 # set starting row pointer to index "0" 
  while($rowCount -gt 0) {
    if(($currentRow + $batchCount) -lt $totalRowCount){
      $batches += @{
        "startRow" = $currentRow;
        "endRow" = $currentRow + $batchCount - 1;
      }
    } else { 
      $batches += @{
        "startRow" = $currentRow;
        "endRow" = $totalRowCount - 1;
      }
    }
    $rowCount -= $batchCount
    $currentRow += $batchCount
  }
  return $batches
}

$pwdSecure = ConvertTo-SecureString -String $pbi_pwd -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential($pbi_username, $pwdSecure)
Disconnect-PowerBIServiceAccount
$output = Connect-PowerBIServiceAccount -Credential $credential -ErrorAction Stop

$SQLConnectionString = $sql_connectionString
# create new sql connection
$sqlConn = New-Object System.Data.SqlClient.SqlConnection($SQLConnectionString)

# Turn Constraints Off
Set-SQLConstraint -constraint $false -sqlConn $sqlConn

# Workspaces All  
$workspacesAll = Get-PowerBIWorkspace -Scope Organization -Include All

# Workspaces 
$outputData = $workspacesAll | Select-Object Id, Name, IsOnDedicatedCapacity, CapacityId, Description, Type, State, IsOrphaned | Out-DataTable
$result = Update-SQL -tableName "Workspaces" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update Workspaces Table"
}

# Users
$outputData = $workspacesAll | Where-Object { ($null -ne $_.Users.Identifier ) } | Select-Object @{Name = "WorkspaceId"; Expression = { $_.Id } }, @{Name = "UsersObject"; Expression = { $_.Users | Select-Object AccessRight, UserPrincipalName, Identifier, PrincipalType } } | Select-Object -Property * -ExcludeProperty Users, UsersObject -ExpandProperty UsersObject | Out-DataTable 
$result = Update-SQL -tableName "WorkspacesUsers" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update WorkspacesUsers Table"
}

# Workbooks
$outputData = $workspacesAll | Where-Object { ($null -ne $_.Workbooks.Name ) } | Select-Object @{Name = "WorkspaceId"; Expression = { $_.Id } }, @{Name = "Workbooks"; Expression = { $_.Workbooks | Select-Object Name, DatasetId } } | Select-Object -Property * -ExcludeProperty Workbooks -ExpandProperty Workbooks | Out-DataTable
$result = Update-SQL -tableName "WorkspacesWorkbooks" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update WorkspacesWorkbooks Table"
}

# Datasets
$datasets = Get-PowerBIDataset -Scope Organization
$outputData = $datasets | Out-DataTable
$result = Update-SQL -tableName "Datasets" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update Datasets Table"
}

# Datasets Datasources
$datasources = @()
$datasets | ForEach-Object {
    $datasource = Get-PowerBIDatasource -DatasetId $_.Id -Scope Organization
    $datasource | Add-Member -MemberType NoteProperty -Name "DatasetId" -value $_.Id
    $datasources += $datasource 
}

$outputData = $datasources | Select-Object -Property * , @{Name = "ConnectionDetailsObject"; Expression = { $_.ConnectionDetails | Select-Object Server, Database, Url } } | Select-Object -Property * -ExcludeProperty ConnectionDetails, ConnectionDetailsObject -ExpandProperty ConnectionDetailsObject | Out-DataTable
$result = Update-SQL -tableName "DatasetsDatasources" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update DatasetsDatasources Table"
}

# WorkspacesDatasets
$outputData = $workspacesAll | Where-Object { ($null -ne $_.Datasets.Id ) } | Select-Object @{Name = "WorkspaceId"; Expression = { $_.Id } }, @{Name = "Datasets"; Expression = { $_.Datasets | Select-Object Id } } | Select-Object -Property * -ExcludeProperty Datasets -ExpandProperty Datasets | Out-DataTable
$result = Update-SQL -tableName "WorkspacesDatasets" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update WorkspacesDatasets Table"
}

# Reports
$reports = Get-PowerBIReport -Scope Organization
$outputData = $reports | Out-DataTable
$result = Update-SQL -tableName "Reports" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update Reports Table"
}

# WorkspacesReports
$outputData = $workspacesAll | Where-Object { ($null -ne $_.Reports.Id ) } | Select-Object @{Name = "WorkspaceId"; Expression = { $_.Id } }, @{Name = "Reports"; Expression = { $_.Reports | Select-Object Id } } | Select-Object -Property * -ExcludeProperty Reports -ExpandProperty Reports | Out-DataTable
$result = Update-SQL -tableName "WorkspacesReports" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update WorkspacesReports Table"
}

# Dataflows
$dataflows = Get-PowerBIDataflow -Scope Organization
$outputData = $dataflows | Out-DataTable
$result = Update-SQL -tableName "Dataflows" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update Dataflows Table"
}

# Dataflows Datasources
$dataflowDatasources = @()
$dataflows | ForEach-Object { 
    $dataflowDatasource = Get-PowerBIDataflowDatasource -DataflowId $_.Id -Scope Organization
    $dataflowDatasource | Add-Member -MemberType NoteProperty -Name "DataflowId" -value $_.Id
    $dataflowDatasources += $dataflowDatasource
}
$outputData = $dataflowDatasources | Select-Object -Property * , @{Name = "ConnectionDetailsObject"; Expression = { $_.ConnectionDetails | Select-Object Server, Database, Url } } | Select-Object -Property * -ExcludeProperty ConnectionDetails, ConnectionDetailsObject -ExpandProperty ConnectionDetailsObject | Out-DataTable
$result = Update-SQL -tableName "DataflowsDatasources" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update DataflowsDatasources Table"
}

# WorkspacesDataflows
$outputData = $workspacesAll | Where-Object { ($null -ne $_.Dataflows.Id ) } | Select-Object @{Name = "WorkspaceId"; Expression = { $_.Id } }, @{Name = "Dataflows"; Expression = { $_.Dataflows | Select-Object Id } } | Select-Object -Property * -ExcludeProperty Dataflows -ExpandProperty Dataflows | Out-DataTable
$result = Update-SQL -tableName "WorkspacesDataflows" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update WorkspacesDataflows Table"
}

# Dashboards
$dashboards = Get-PowerBIDashboard -Scope Organization
$outputData = $dashboards | Out-DataTable
$result = Update-SQL -tableName "Dashboards" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update Dashboards Table"
}

# # Dashboard Tiles
$dashboardTiles = @()
$dashboards | ForEach-Object {
    $dashboardTile = Get-PowerBITile -DashboardId $_.Id
    $dashboardTile | Add-Member -MemberType NoteProperty -Name "DashboardId" -value $_.Id
    $dashboardTiles += $dashboardTile 
}
$outputData = $dashboardTiles | Out-DataTable
$result = Update-SQL -tableName "DashboardsTiles" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update DashboardsTiles Table"
}

# WorkspacesDashboards
$outputData = $workspacesAll | Where-Object { ($null -ne $_.Dashboards.Id ) } | Select-Object @{Name = "WorkspaceId"; Expression = { $_.Id } }, @{Name = "Dashboards"; Expression = { $_.Dashboards | Select-Object Id } } | Select-Object -Property * -ExcludeProperty Dashboards -ExpandProperty Dashboards | Out-DataTable
$result = Update-SQL -tableName "WorkspacesDashboards" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update WorkspacesDashboards Table"
}

# Turn constraints on
Set-SQLConstraint -constraint $true -sqlConn $sqlConn

# -- Activities -- 

# Get Activity Events Timestamp
$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlCmd.Connection = $sqlConn
$sqlCmd.CommandTimeout = 0
$sqlCmd.Connection.Open()
$sqlCmd.CommandText = "EXEC [pbi].[usp_Get_ActivityEvents_Timestamp]"
$reader = $sqlCmd.ExecuteReader()
while ($reader.Read()) {
    $timestampOutput = $reader.GetValue(0)
}
$sqlCmd.Connection.Close()
# Start Date Time
if ($timestampOutput -is [DBNull]) {
    # Get last 30 days for first load as Power BI activity log only stores up to 30 days of activity data. Source: https://docs.microsoft.com/en-us/power-bi/admin/service-admin-auditing#activityevents-rest-api
    $startDate = Get-Date
    $startDate = $startDate.AddDays(-30)
    $startDateTime = Get-Date -Year $startDate.Year -Month $startDate.Month -Day $startDate.Day -Hour 0 -Minute 0 -Second 0 -Millisecond 0 
    $startDateTimeString = $startDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
    Write-Host "Start Date Time String: " $startDateTimeString
}
else {
    $startDateTimeOffset = $timestampOutput
    $startDateTimeOffset = $startDateTimeOffset.ToUniversalTime()
    $startDateTime = Get-Date -Year $startDateTimeOffset.Year -Month $startDateTimeOffset.Month -Day $startDateTimeOffset.Day -Hour $startDateTimeOffset.Hour -Minute $startDateTimeOffset.Minute -Second $startDateTimeOffset.Second
    $startDateTime = $startDateTime.AddHours(-24) # get previous 24 hours overlap as it can take up to 24 hours for all events to show up. Source: https://docs.microsoft.com/en-us/power-bi/admin/service-admin-auditing#activityevents-rest-api
    $startDateTimeString = $startDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
    Write-Host "Start Date Time String: " $startDateTimeString
}
# End Date Time
$endDateTime = Get-Date
$endDateTime = $endDateTime.ToUniversalTime()
$endDateTimeString = $endDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
Write-Host "End Date Time String: " $endDateTimeString

$dateTimeRanges = @()
$timespan = New-TimeSpan -Start $startDateTime -End $endDateTime 
$timespanDays = $timespan.Days

$currentStartDateTime = $startDateTime
$currentEndDateTime = $endDateTime

while ($timespanDays -ge 0) {
    if ($timespanDays -ne 0 ) {
        $currentStartDateTimeString = $currentStartDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
        $currentEndDateTime = Get-Date -Year $currentStartDateTime.Year -Month $currentStartDateTime.Month -Day $currentStartDateTime.Day -Hour 23 -Minute 59 -Second 59 -Millisecond 59
        $currentEndDateTimeString = $currentEndDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
        $dateTimeRange = @{
            "startDateTime" = "$currentStartDateTimeString"; 
            "endDateTime"   = "$currentEndDateTimeString"; 
        }
        $dateTimeRanges += $dateTimeRange
        $currentStartDateTime = $currentStartDateTime.AddDays(1)
    }
    else { 
        $currentStartDateTimeString = $currentStartDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
        $endDateTimeString = $endDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
        $dateTimeRange = @{
            "startDateTime" = "$currentStartDateTimeString"; 
            "endDateTime"   = "$endDateTimeString"; 
        }
        $dateTimeRanges += $dateTimeRange
    }
    $timespanDays -= 1 # decrement by 1 day
}

# specify schema 
$schema = @{ 
    "Id"                                   = "System.String";
    "RecordType"                           = "System.String";
    "CreationTime"                         = "System.String";
    "Operation"                            = "System.String";
    "OrganizationId"                       = "System.String";
    "UserType"                             = "System.String";
    "UserKey"                              = "System.String";
    "Workload"                             = "System.String";
    "UserId"                               = "System.String";
    "ClientIP"                             = "System.String";
    "UserAgent"                            = "System.String";
    "Activity"                             = "System.String";
    "IsSuccess"                            = "System.String";
    "RequestId"                            = "System.String";
    "ActivityId"                           = "System.String";
    "ItemName"                             = "System.String";
    "ItemType"                             = "System.String";
    "ObjectId"                             = "System.String";
    "WorkspaceName"                        = "System.String";
    "WorkspaceId"                          = "System.String";
    "ImportId"                             = "System.String";
    "ImportSource"                         = "System.String";
    "ImportType"                           = "System.String";
    "ImportDisplayName"                    = "System.String";
    "DatasetName"                          = "System.String";
    "DatasetId"                            = "System.String";
    "DataConnectivityMode"                 = "System.String";
    "OrgAppPermission"                     = "System.String";
    "DashboardId"                          = "System.String";
    "DashboardName"                        = "System.String";
    "DataflowId"                           = "System.String";
    "DataflowName"                         = "System.String";
    "DataflowAccessTokenRequestParameters" = "System.String";
    "DataflowType"                         = "System.String";
    "GatewayId"                            = "System.String";
    "GatewayName"                          = "System.String";
    "GatewayType"                          = "System.String";
    "ReportName"                           = "System.String";
    "ReportId"                             = "System.String";
    "ReportType"                           = "System.String";
    "FolderObjectId"                       = "System.String";
    "FolderDisplayName"                    = "System.String";
    "ArtifactName"                         = "System.String";
    "ArtifactId"                           = "System.String";
    "CapacityName"                         = "System.String";
    "CapacityUsers"                        = "System.String";
    "CapacityState"                        = "System.String";
    "DistributionMethod"                   = "System.String";
    "ConsumptionMethod"                    = "System.String";
    "RefreshType"                          = "System.String";
    "ExportEventStartDateTimeParameter"    = "System.String";
    "ExportEventEndDateTimeParameter"      = "System.String";
    # "ExportedArtifactExportType"        = "System.String";
    # "ExportedArtifactType"              = "System.String";
    # "AuditedArtifactName"               = "System.String";
    # "AuditedArtifactObjectID"           = "System.String";
    # "AuditedArtifactItemType"           = "System.String";
    # "OtherDatasetIDs"                   = "System.String";
    # "OtherDatasetNames"                 = "System.String";
    # "OtherDatasourceTypes"              = "System.String";
    # "OtherDatasourceConnectionDetails"  = "System.String";
    # "SharingRecipientEmails"            = "System.String";
    # "SharingResharePermissions"         = "System.String";
    # "SubscribeeRecipientEmails"         = "System.String";
    # "SubscribeeRecipientNames"          = "System.String";
    # "SubscribeeObjectIDs"               = "System.String";
}

$output = @()
$dateTimeRanges | ForEach-Object {
    Write-Host "Fetching logs between startDateTime: " $_.startDateTime ", endDateTime: " $_.endDateTime 
    $output += Get-PowerBIActivityEvent -StartDateTime $_.startDateTime -EndDateTime $_.endDateTime  | ConvertFrom-Json | Where-Object { ($null -ne $_.Id ) }  # only allowed to query within the same UTC day
}
$outputData = $output | Out-DataTable -userSchema $true -schema $schema 

# Get activity events
# insert to lga.ActivityEvents
$result = Update-LGASQLTable -sourceSchema "tempstage" -sourceTable "ActivityEvents" -targetCompareSchema "pbi" -targetCompareTable "ActivityEvents" -targetSchema "lga" -targetTable "ActivityEvents" -outputData $outputData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update LGA SQL Table"
}

# insert to pbi.ActivityEvents
$result = Update-SQL -tableName "ActivityEvents" -outputData $outputData -sqlConn $sqlConn -mergeOperation "I--" # only insert new Ids
if ($result -eq $true) {
    # Set Activity Events Timestamp
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.Connection = $sqlConn
    $sqlCmd.CommandTimeout = 0
    $sqlCmd.Connection.Open()
    $sqlCmd.CommandText = "EXEC [pbi].[usp_Set_ActivityEvents_Timestamp] @StartDateTime='$startDateTimeString', @EndDateTime='$endDateTimeString'"
    $output = $sqlCmd.ExecuteNonQuery()
    if ($output -eq 1) {
        Write-Host "Updated Activity Events Timestamp"
    }
    else { 
        Write-Warning "Failed to update Activity Events Timestamp"
    }
    $sqlCmd.Connection.Close()
}


# Submit the Log Analytics data to the API endpoint
# name of the record type
Write-Host "Fetching from lga.ActivityEvents"
$logType = "PowerBILogs" # note: when querying from LGA, use PowerBILogs_CL as "_CL" is appended automatically
$sqlCommand = "SELECT * FROM lga.ActivityEvents"
$lgaTable = Invoke-SQL -sqlCommand $sqlCommand -sqlConn $sqlConn 
if ($null -ne $lgaTable) {
    Write-Host "Completed fetching from lga.ActivityEvents"
}

$totalRowCount = $lgaTable.Rows.Count # get total row count
$batchCount = 100 # set batch count to 100 
$batches = Get-RowBatches -totalRowCount $totalRowCount -batchCount $batchCount # get batches by calling our custom function

Write-Host "Sending to Log Analytics"
$output = $null
# iterate through each batch 
$batches | ForEach-Object { 
    Write-Host "Processing Rows " $_.startRow.ToString() " to " $_.endRow.ToString()
    $json = $lgaTable.GetList()[$_.startRow..$_.endRow] | Select-Object -Property * -ExcludeProperty DataView, Row | ConvertTo-Json # select the start row to end row, and convert to JSON
    $output = Send-LogAnalyticsData -customerId $lga_workspaceId -sharedKey $lga_sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType # -TimestampField $TimestampField
}
if ($null -ne $output) {
    Write-Host "Completed sending to Log Analytics"
}
