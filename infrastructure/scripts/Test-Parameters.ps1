# See https://devblogs.microsoft.com/powershell/powershell-foreach-object-parallel-feature/#:~:text=Runspace%20contexts%20are%20an%20isolation%20unit%20for%20running%20scripts
$failures = [System.Collections.Generic.List[string]]::new()

if (-not $(Get-AzContext)) {
    throw "❌ No Az context available. Run Connect-AzAccount to login."
}

Write-Host -ForegroundColor Gray "Setting up..."

$testResourceGroupName = 'testparameters-{0}' -f (Get-Date -Format FileDateTimeUniversal)
New-AzResourceGroup -Name $testResourceGroupName -Location "australiaeast" -Force | Out-Null
Write-Host -ForegroundColor Gray -Object ('Created resource group ''{0}'' to test ARM parameters' -f $testResourceGroupName)

try {

    $templateFolder = Join-Path $PSScriptRoot "../arm"
    Get-ChildItem $templateFolder -File -Filter '*.json' |
    ForEach-Object {
        # Not all template files can be tested as they may require already created resources e.g. checking you can apply roles to an existing object
        if ($_.Name -eq 'roleAssignment.json') {
            Write-Warning "Template file '$_' cannot be tested"
        }
        else {
            Write-Output $_
        }
    } |
    ForEach-Object -Parallel {

        function Get-DeploymentError([Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceManagerError] $resourceManagerError, $prefix = "") {
            $errorMessage = "$prefix$($resourceManagerError.Message) ($($resourceManagerError.Code))"

            if ($resourceManagerError.Target) {
                $errorMessage = "$errorMessage [Target: $($resourceManagerError.Target)]"
            }

            if ($resourceManagerError.Details) {
                $innerErrorMessages = $resourceManagerError.Details | ForEach-Object { Get-DeploymentError -resourceManagerError $_ -prefix "$prefix  " }
                return "$errorMessage`n$($innerErrorMessages -join "`n")"
            }
            else {
                return $errorMessage
            }
        }

        $templateToTest = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $templateFile = Join-Path $using:templateFolder "$templateToTest.json"
        $templateParametersFile = Join-Path $using:templateFolder "parameters/$templateToTest.parameters.json"

        if (-not (Test-Path $templateParametersFile)) {
            Write-Host -ForegroundColor Red "❌ $templateToTest"
            Write-Host "  $templateParametersFile doesn't exist"
            $localFailures = $using:failures
            $localFailures.Add($templateToTest)
            return
        }

        if ($templateToTest -imatch ("^(resourceGroup|azurePolicy\.basic|azurePolicy\.ISMProtectedAustralia|insights)")) {
            $result = Test-AzDeployment -Location "australiaeast" -TemplateFile $templateFile -TemplateParameterFile $templateParametersFile -SkipTemplateParameterPrompt
        }
        else {
            $result = Test-AzResourceGroupDeployment -ResourceGroupName $using:testResourceGroupName -TemplateFile $templateFile -TemplateParameterFile $templateParametersFile -SkipTemplateParameterPrompt
        }

        if ($result.Count -gt 0) {
            $result | ForEach-Object {
                $regex = "was disallowed by policy|references wrong subscription|MarketplacePurchaseEligibilityFailed|Subscription currently has 1 resources and the template contains 1 new resources of the this type"
                $errorToAdd = $(Get-DeploymentError $_ -prefix "  ")
                $warningsToAdd = $(Get-DeploymentError $_ -prefix "  ")
                $errors += $errorToAdd | Where-Object { $_ -inotmatch $regex }
                $warnings += $warningsToAdd | Where-Object { $_ -imatch $regex }
            }

            if ($errors) {
                Write-Host -ForegroundColor Red "❌ $templateToTest`n$errors"
                $localFailures = $using:failures
                $localFailures.Add($templateToTest)
            }
            else {
                Write-Host -ForegroundColor Yellow ("⚠️  $templateToTest`n   " + $warnings.Count + " issue(s) detected (e.g. incorrect resourceId), but the ARM template is okay.")
            }

        }
        else {
            Write-Host -ForegroundColor Green "✔️  $templateToTest"
        }
    }
}
finally {

    Write-Host -ForegroundColor Gray "Cleaning up..."
    Remove-AzResourceGroup -Name $testResourceGroupName -Force | Out-Null
    Write-Host -ForegroundColor Gray -Object ('Removed resource group ''{0}''' -f $testResourceGroupName)
}

if ($failures.Count -eq 0) {
    Write-Output '✔️ Success'
    exit 0
}
else {
    Write-Error '❌ Failure'
    exit 1
}
