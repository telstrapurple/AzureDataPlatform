
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