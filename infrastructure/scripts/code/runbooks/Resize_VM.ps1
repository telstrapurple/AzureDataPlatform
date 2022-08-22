Param
(
    [parameter(Mandatory = $true)] 
    [String] 
    $resourceGroupName, 

    [parameter(Mandatory = $true)] 
    [String] 
    $vmList,   
	
    [parameter(Mandatory = $true)] 
    [String] 
    $vmSize
)

# Make sure errors cause the job to fail.
# Errors like: missing RunAs connection,
#              VM size that doesn't exist
#              VM that doesn't exist
#              etc
$ErrorActionPreference = "Stop"

# Get the Service Principal connection details for the Connection name

$servicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'

#Connect to Azure

Connect-AzAccount -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
    -Subscription $servicePrincipalConnection.SubscriptionId

#Loop through the list of VM's to scale

foreach ($vmName in $vmList.Split(",")) {
    $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
    $currentVMSize = $vm.HardwareProfile.VmSize

    Write-Output "Current size for ${vmName} is ${currentVMSize}"

    $vm.HardwareProfile.VmSize = $vmSize 
    Update-AzVM -ResourceGroupName $resourceGroupName -VM $vm

    Write-Output "${vmName} updated to ${vmSize}"
}