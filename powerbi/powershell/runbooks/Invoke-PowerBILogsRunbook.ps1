Write-Output "-------------- Start --------------"

Write-Output "Connecting to Azure using AzureRunAsConnection"
$servicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Connect-AzAccount -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
    -Subscription $servicePrincipalConnection.SubscriptionId

Write-Output "Get Variables"
$resouceGroupName = (Get-AzResourceGroup).ResourceGroupName
Write-Output "ResouceGroupName: " $resouceGroupName
$automationAccountName = (Get-AzResource -ResourceType "Microsoft.Automation/automationAccounts").ResourceName
Write-Output "AutomationAccountName: " $automationAccountName
$hybridWorkerGroup = Get-AzAutomationHybridWorkerGroup -ResourceGroupName $resouceGroupName -AutomationAccountName $automationAccountName
$vmName = $hybridWorkerGroup.RunbookWorker[0].Name
Write-Output "Hybrid Worker Name: " $vmName
$hybridWorkerGroupName = $hybridWorkerGroup.Name
Write-Output "Hybrid Worker Group Name: " $hybridWorkerGroupName

Write-Output "Start the Hybrid Worker"
Start-AzVM -ResourceGroupName $resouceGroupName -Name $vmName
Write-Output "Hybrid Worker Started"

Write-Output "Executing 'Execute-PowerBILogsRunbook' on HybridWorker"
$output = Start-AzAutomationRunbook -Name "Execute-PowerBILogsRunbook" -ResourceGroupName $resouceGroupName -RunOn $hybridWorkerGroupName -AutomationAccountName $automationAccountName -Wait -ErrorAction SilentlyContinue

Write-Output "Stop the Hybrid Worker"
Stop-AzVM -ResourceGroupName $resouceGroupName -Name $vmName -Force
Write-Output "Hybrid Worker Stopped"

Write-Output "-------------- Finish --------------"