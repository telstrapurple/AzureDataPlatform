Param
(
	[parameter(Mandatory = $true)] 
	[String] 
	$resourceGroupName,   

	[parameter(Mandatory = $true)] 
	[String] 
	$serverName,   
	
	[parameter(Mandatory = $true)] 
	[String] 
	$databaseList, 
	
	[parameter(Mandatory = $true)] 
	[String] 
	$edition, 
	
	[parameter(Mandatory = $true)] 
	[String] 
	$requestedServiceObjectiveName
)
# Make sure errors cause the job to fail.
# Errors like: missing RunAs connection,
#              SQL service level objective name that doesn't exist
#              SQL server or db that doesn't exist
#              etc
$ErrorActionPreference = "Stop"

# Get the Service Principal connection details for the Connection name
$servicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'

#Connect to Azure

Connect-AzAccount -TenantId $servicePrincipalConnection.TenantId `
	-ApplicationId $servicePrincipalConnection.ApplicationId `
	-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
	-Subscription $servicePrincipalConnection.SubscriptionId

#Loop through the list of databases to scale

foreach ($databaseName in $databaseList.Split(",")) {
	$sqlDB = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
	Write-Output ("Current size for database $databaseName is " + $sqldb.Edition + ", " + $sqldb.CurrentServiceObjectiveName)

	Set-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -Edition $edition -RequestedServiceObjectiveName $requestedServiceObjectiveName   

	$sqlDB = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName
	Write-Output ("Database $databaseName updated to " + $sqldb.Edition + ", " + $sqldb.CurrentServiceObjectiveName)
}