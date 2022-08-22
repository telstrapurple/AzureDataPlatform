Param
(
	[parameter(Mandatory=$true)] 
	[String] 
	$keyVaultName,   

	[parameter(Mandatory=$true)] 
	[String] 
	$databricksTokenSecret,   
	
	[parameter(Mandatory=$true)] 
	[String] 
	$databricksURL, 
	
	[parameter(Mandatory=$true)] 
	[String] 
	$adGroupName
)

# Get the Service Principal connection details for the Connection name
$servicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'

#Connect to Azure

Connect-AzAccount -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
    -Subscription $servicePrincipalConnection.SubscriptionId

# Get the access token from KeyVault

$databricksToken = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $databricksTokenSecret).SecretValueText

# Connect to Databricks

Set-DatabricksEnvironment -AccessToken $databricksToken -ApiRootUrl $databricksURL

# Create the Databricks group if it doesn't exist

$groupExists = 0
$databricksGroups = Get-DatabricksGroup

foreach($group in $databricksGroups)
{
    if($group -eq $adGroupName)
    {
        $groupExists = 1
    }
}

if($groupExists -eq 0)
{
    Add-DatabricksGroup -GroupName $adGroupName
}

# Add new group members, remove ones that no longer exist

$groupMemberExists = 0
$databricksGroupMembers = Get-DatabricksGroupMember -GroupName $adGroupName | Select value

# Add new group members

$adMembers = Get-AzADGroupMember -GroupDisplayName $adGroupName

foreach($groupMember in $adMembers.UserPrincipalName)
{
    foreach($databricksGroupMember in $databricksGroupMembers)
    {
        if($groupMember -eq $databricksGroupMember.value)
        {
            $groupMemberExists = 1
        }
    }

    if($groupMemberExists -eq 0)
    {
        Add-DatabricksGroupMember -UserName $groupMember -ParentGroupName $adGroupName -ErrorAction SilentlyContinue
    }
}

# Remove old group members

$groupMemberExists = 0

foreach($databricksGroupMember in $databricksGroupMembers.value)
{
    foreach($groupMember in $adMembers.UserPrincipalName)
    {
        if($groupMember -eq $databricksGroupMember)
        {
            $groupMemberExists = 1
        }
    }

    if($groupMemberExists -eq 0)
    {
        Remove-DatabricksGroupMember -UserName $groupMember -ParentGroupName $adGroupName -ErrorAction SilentlyContinue
    }
}