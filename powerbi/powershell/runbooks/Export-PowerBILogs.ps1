<#
    .SYNOPSIS 
        Writes Power BI Logs to Azure SQL Database and Log analytics
    .DESCRIPTION 
        
    
    .EXAMPLE
        
    .NOTES
        Pre-requisites: 
            MicrosoftPowerBIMgmt module is installed. If not installed, then run `Install-Module -Name MicrosoftPowerBIMgmt`
#>

[CmdletBinding()]
param (
    [parameter(Mandatory = $true)][String]$pbi_username,
    [parameter(Mandatory = $true)][String]$pbi_pwd,
    [parameter(Mandatory = $true)][String]$sql_server,
    [parameter(Mandatory = $true)][String]$sql_database,
    [parameter(Mandatory = $true)][String]$sql_username,
    [parameter(Mandatory = $true)][String]$sql_pwd,
    [parameter(Mandatory = $true)][String]$lga_workspaceId,
    [parameter(Mandatory = $true)][String]$lga_sharedKey
)

# Import/Reload modules
Remove-Module "sql-functions" -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\functions\sql-functions.psm1"
Remove-Module "lga-functions" -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\functions\lga-functions.psm1"
Import-Module MicrosoftPowerBIMgmt

$pwdSecure = ConvertTo-SecureString -String $pbi_pwd -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $pbi_username, $pwdSecure
Connect-PowerBIServiceAccount -Credential $credential

$SQLConnectionString = "Server = $sql_server; Database = $sql_database; User ID = $sql_username; Password = $sql_pwd;"
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
$timestampOutput
$sqlCmd.Connection.Close()
# Start Date Time
if ($timestampOutput -is [DBNull]) {
    # Get last 30 days for first load as Power BI activity log only stores up to 30 days of activity data. Source: https://docs.microsoft.com/en-us/power-bi/admin/service-admin-auditing#activityevents-rest-api
    $startDate = Get-Date
    $startDate = $startDate.AddDays(-30)
    $startDateTime = Get-Date -Year $startDate.Year -Month $startDate.Month -Day $startDate.Day -Hour 0 -Minute 0 -Second 0 -Millisecond 0 
    $startDateTimeString = $startDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
    $startDateTimeString
}
else {
    $startDateTimeOffset = $timestampOutput
    $startDateTimeOffset = $startDateTimeOffset.ToUniversalTime()
    $startDateTime = Get-Date -Year $startDateTimeOffset.Year -Month $startDateTimeOffset.Month -Day $startDateTimeOffset.Day -Hour $startDateTimeOffset.Hour -Minute $startDateTimeOffset.Minute -Second $startDateTimeOffset.Second
    $startDateTime = $startDateTime.AddHours(-24) # get previous 24 hours overlap as it can take up to 24 hours for all events to show up. Source: https://docs.microsoft.com/en-us/power-bi/admin/service-admin-auditing#activityevents-rest-api
    $startDateTimeString = $startDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
    $startDateTimeString
}
# End Date Time
$endDateTime = Get-Date
$endDateTime = $endDateTime.ToUniversalTime()
$endDateTimeString = $endDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
$endDateTimeString

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
$logType = "PowerBILogs" # note: when querying from LGA, use PowerBILogs_CL as "_CL" is appended automatically
$sqlCommand = "SELECT * FROM lga.ActivityEvents"
$lgaTable = Invoke-SQL -sqlCommand $sqlCommand -sqlConn $sqlConn 
$lgaTable | ForEach-Object {
    $json = $_ | ConvertTo-Json
    Send-LogAnalyticsData -customerId $lga_workspaceId -sharedKey $lga_sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType # -TimestampField $TimestampField
}
