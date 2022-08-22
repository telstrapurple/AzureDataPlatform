$output = Connect-AzAccount -Identity
if ($null -eq $output) {
    Write-Warning "Could not connect to Azure using the Hybrid Worker's MSI."
}
$resouceGroupName = (Get-AzResourceGroup).ResourceGroupName
$automationAccountName = (Get-AzResource -ResourceType "Microsoft.Automation/automationAccounts").ResourceName
$vmName = (Get-AzAutomationHybridWorkerGroup -ResourceGroupName $resouceGroupName -AutomationAccountName $automationAccountName).RunbookWorker[0].Name
Write-Output "Exporting Runbook 'Export-PowerBILogsRunbook.ps1' to Hybrid Worker $vmName filepath '$env:temp\Export-PowerBILogsRunbook.ps1'"
Export-AzAutomationRunbook -ResourceGroupName $resouceGroupName -AutomationAccountName $automationAccountName -Name "Export-PowerBILogsRunbook" -Slot "Published" -OutputFolder "$env:temp" -Force
Write-Output "Calling pwsh.exe -File $env:temp\Export-PowerBILogsRunbook.ps1"
pwsh.exe -File "$env:temp\Export-PowerBILogsRunbook.ps1"
Write-Output "Execution of 'Export-PowerBILogsRunbook' complete" 