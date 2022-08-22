<#
    .SYNOPSIS 
        Retrieves all Azure AD users and their licences
    .DESCRIPTION 
        
    
    .EXAMPLE
        
    .NOTES
        Pre-requisites: 
            AzureAD module is installed. If not installed, then run `Install-Module -Name AzureAD`
#>

# Declare functions
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
        [parameter(Mandatory = $false)][Int]$distinct = 0, 
        [parameter(Mandatory = $true)][PSObject]$outputData,
        [parameter(Mandatory = $true)][System.Data.SqlClient.SqlConnection]$sqlConn,
        [parameter(Mandatory = $false)][String]$mergeOperation = "IUD" 
    )
    try {
        # truncate tempstage
        $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $sqlCmd.Connection = $sqlConn
        $sqlCmd.CommandTimeout = 0

        $sqlConn.Open()
        $sqlCmd.CommandText = "TRUNCATE TABLE tempstage.aad_$tableName"
        $output = $sqlCmd.ExecuteNonQuery()
        if ($null -ne $output) {
            Write-Host "Truncated tempstage.aad_$tableName"
        }
        else { 
            Write-Host "Failed to truncate tempstage.aad_$tableName"
        }

        # insert to tempstage
        $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy($sqlConn)
        $bulkCopy.BulkCopyTimeout = 0
        foreach ($_ in $outputData[0].Columns) {
            $output = $bulkCopy.ColumnMappings.Add($_.ColumnName, $_.ColumnName)
        }
        $bulkCopy.DestinationTableName = "tempstage.aad_$tableName"
        $output = $bulkCopy.WriteToServer($outputData)
        if ($null -eq $output) {
            $rowCount = $outputData.Rows.Count
            Write-Host "Inserted $rowCount records to tempstage.aad_$tableName"
        }
        else { 
            Write-Host "Failed to insert records to tempstage.aad_$tableName"
        }

        # merge tempstage to pbi table
        $sqlCmd.CommandText = "EXEC pbi.usp_GenericMerge @SourceSchema = 'tempstage', @SourceTable = 'aad_$tableName', @TargetSchema = 'aad', @TargetTable = '$tableName', @Operation = '$mergeOperation', @Distinct = $distinct"
        $output = $sqlCmd.ExecuteNonQuery()
        if ($null -ne $output) {
            Write-Host "Merged pbi.$tableName. $output records were inserted or updated or deleted"
        }
        else { 
            Write-Host "Failed to merge pbi.$tableName"
        }
        $sqlConn.Close()
        return $true
    }
    catch { 
        Write-Error $_
    }
}
function Get-CurrentUserAzureAdObjectId() {
    $account = (Get-AzContext).Account
    if ($account.Type -eq 'User') {
        $user = Get-AzADUser -UserPrincipalName $account.Id
        if (-not $user) {
            $user = Get-AzADUser -Mail $account.Id
        }
        return $user.Id
    }
    $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $account.Id
    return $servicePrincipal.Id
}

Write-Output "Connecting to Azure"
# Connect to Azure
# Get the Service Principal connection details for the Connection name

$servicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'

#Connect to Azure

Connect-AzAccount `
    -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
    -Subscription $servicePrincipalConnection.SubscriptionId

# Get the AAD access token for Azure AD
$aadAccessToken = Get-AzAccessToken -ResourceUrl 'https://graph.windows.net'

# Import/Reload modules
Write-Output "Importing Modules"
if (($PSVersionTable.PSVersion).Major -gt 5) {
    Import-Module AzureADPreview
}
else {
    Import-Module AzureAD
}
Write-Output "Modules Imported"

Write-Output "Connecting to Azure AD"

try {
    Connect-AzureAD -AadAccessToken $aadAccessToken.Token -AccountId (Get-CurrentUserAzureAdObjectId) -TenantId $aadAccessToken.TenantId | Out-Null
}
catch {
    Write-Error "Unable to establish a connection to Azure AD"
    exit
}

# Get all Azure AD users 
Write-Output "Get all Azure AD users"
$userData = Get-AzADUser | Select-Object  @{n = "UserID"; e = { $_.Id } },
@{n = "UserPrincipalName"; e = { $_.UserPrincipalName } },
@{n = "DisplayName"; e = { $_.DisplayName } },
@{n = "GivenName"; e = { $_.GivenName } },
@{n = "Surname"; e = { $_.Surname } },
@{n = "Mail"; e = { $_.Mail } },
@{n = "MailNickname"; e = { $_.MailNickname } },
@{n = "DeletionTimestamp"; e = { $_.DeletionTimestamp } },
@{n = "AccountEnabled"; e = { $_.AccountEnabled } },
@{n = "ImmutableID"; e = { $_.ImmutableId } } | Out-DataTable

 
# Get all Azure AD Groups
Write-Output "Get all Azure AD groups"
$groupData = Get-AzADGroup | Select-Object  @{n = "GroupID"; e = { $_.Id } },
@{n = "GroupName"; e = { $_.DisplayName } },
@{n = "Mail"; e = { $_.MailNickname } },
@{n = "MailEnabled"; e = { $_.MailEnabled } },
@{n = "SecurityEnabled"; e = { $_.SecurityEnabled } } | Out-DataTable

# Get all Azure AD User Group Memberships
Write-Output "Get all Azure AD User Group memberships"
$userGroupData = @()
foreach ($user in ($userData)) {
    $userGroupData += Get-AzureADUserMembership -ObjectId ($user.UserID) -All $true | Where-Object { $_.ObjectType -eq "Group" } | Select-Object  @{n = "UserID"; e = { $user.UserID } },
    @{n = "GroupID"; e = { $_.ObjectId } } | Out-DataTable  
}                                          

# Get all Azure AD user licences
Write-Output "Get all Azure AD user licences"
$userLicenceData = @()
foreach ($user in ($userData)) {
    $userLicenceDetail = Get-AzureADUserLicenseDetail -ObjectId ($user.UserID)
    if ($null -ne $userLicenceDetail) {
        $userLicenceData += $userLicenceDetail | Select-Object  @{n = "UserID"; e = { $user.UserID } },
        @{n = "SKUID"; e = { $_.SkuId } },
        @{n = "SKUName"; e = { $_.SkuPartNumber } } | Out-DataTable
    }
}

# Connect to SQL as MSI
Connect-AzAccount -Identity

Write-Output "Getting KeyVault Secrets"
$keyVaultName = Get-AutomationVariable "keyVaultName"
if (($PSVersionTable.PSVersion).Major -ge 7) {
    $SQLConnectionString = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "sqlDatabaseConnectionStringStage").SecretValue | ConvertFrom-SecureString -AsPlainText
}
else {
    $secureString = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "sqlDatabaseConnectionStringStage").SecretValue
    $bStr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $SQLConnectionString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bStr)
}

# Get the SQL access token
$sqlAccessToken = Get-AzAccessToken -ResourceUrl "https://database.windows.net" | Select-Object -ExpandProperty Token

# Create new sql connection
$sqlConn = New-Object System.Data.SqlClient.SqlConnection($SQLConnectionString)
$sqlConn.AccessToken = $sqlAccessToken

# Users
$result = Update-SQL -tableName "Users" -outputData $userData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update Users Table"
}

# Groups
$result = Update-SQL -tableName "Groups" -outputData $groupData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update Groups Table"
}

# User Groups
$result = Update-SQL -tableName "UsersGroups" -outputData $userGroupData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update UsersGroups Table"
}

# Users Licences
$result = Update-SQL -tableName "UsersLicences" -outputData $userLicenceData -sqlConn $sqlConn
if ($result -ne $true) {
    Write-Warning "Failed to update UsersLicences Table"
}
