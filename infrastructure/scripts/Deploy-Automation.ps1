[CmdletBinding(SupportsShouldProcess = $true)]
Param (
    [ValidatePattern("[a-zA-Z0-9\-]{3,24}")]
    [Parameter(Mandatory = $true)]
    [string] $EnvironmentName,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9]{1,5}")]
    [string] $EnvironmentCode,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9]{1,5}")]
    [string] $Location,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("[a-zA-Z0-9\-]{3,24}")]
    [string] $LocationCode,

    [Parameter(Mandatory = $true)]
    [string] $TenantId,

    [Parameter(Mandatory = $true)]
    [string] $SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string] $ConfigFile = "config.$($EnvironmentCode.ToLower()).json",

    [Parameter(Mandatory = $true)]
    [string] $codeStorageAccountName,

    [Parameter(Mandatory = $true)]
    [string] $codeStorageResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $diagnosticsObject,

    [Parameter(Mandatory = $true)]
    [string] $deploymentKeyVaultName
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/storage.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/automation.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$diagnostics = ConvertFrom-JsonToHash -Object $diagnosticsObject

try {

    if ($VerbosePreference -eq "SilentlyContinue" -and $Env:SYSTEM_DEBUG) {
        $VerbosePreference = "Continue"
    }

    if (-not $pscmdlet.ShouldProcess("Deploy with powershell")) {
        Write-Verbose "-WhatIf is set, will not execute deployment."

        Write-Host "Deploy would proceed with the following parameters"
        $Context | Format-Table | Out-String | Write-Host
    }
    else {
        $Context | Format-Table | Out-String | Write-Verbose

        ###############################################################################
        ## Automation runbooks
        ###############################################################################

        $codeStorageContext = Get-StorageContext -Name $codeStorageAccountName -ResourceGroupName $codeStorageResourceGroupName

        # Upload PowerShell runbooks to code storage
        Get-ChildItem (Join-Path $PSScriptRoot "code/runbooks") -Filter *.ps1 | ForEach-Object {
            Write-Host "Uploading $($_.Name) to $codeStorageAccountName/runbooks"
            Set-AzStorageBlobContent -File $_.FullName -Container "runbooks" -Blob $_.Name -Context $codeStorageContext -Force -Properties @{"ContentType" = "text/plain" } | Out-Null
        }

        ###############################################################################
        ## Automation Account
        ###############################################################################

        $container = Get-AzStorageContainer -Name "runbooks" -Context $codeStorageContext
        $sas = $container | New-AzStorageContainerSASToken `
            -Permission "r" `
            -StartTime (Get-Date).ToUniversalTime().AddMinutes(-5) `
            -ExpiryTime (Get-Date).ToUniversalTime().AddMinutes(15)

        $aaaParams = Get-Params -context $Context -configKey "automationAccount" -diagnostics $diagnostics -with @{
            "aaaName"              = Get-ResourceName -context $Context -resourceCode "AAA" -suffix "001";
            "runbookBlobContainer" = $container.BlobContainerClient.Uri.AbsoluteUri;
            "runbookBlobSASToken"  = $sas.ToString();
            "runbooks"             = @(
                @{
                    "name"        = "Scale_Azure_SQL";
                    "file"        = "Scale_Azure_SQL.ps1";
                    "description" = "Runbook to scale Azure SQL database";
                    "version"     = "1.0.0.0";
                    "type"        = "PowerShell";
                },
                @{
                    "name"        = "Resize_VM";
                    "file"        = "Resize_VM.ps1";
                    "description" = "Runbook to resize an Azure virtual machine";
                    "version"     = "1.0.0.0";
                    "type"        = "PowerShell";
                },
                @{
                    "name"        = "Maintain_Databricks_Group_Members";
                    "file"        = "Maintain_Databricks_Group_Members.ps1";
                    "description" = "Runbook to synchronise Azure AD group members to Databricks groups";
                    "version"     = "1.0.0.0";
                    "type"        = "PowerShell";
                }
            );
            "parentModules"        = @(
                @{
                    "name" = "Az.Accounts";
                    "url"  = "https://www.powershellgallery.com/api/v2/package/Az.Accounts/2.6.0";
                },
                @{
                    "name" = "DatabricksPS";
                    "url"  = "https://www.powershellgallery.com/api/v2/package/DatabricksPS/1.2.2.0";
                }
            );
            "childModules"         = @(
                @{
                    "name" = "Az.Sql";
                    "url"  = "https://www.powershellgallery.com/api/v2/package/Az.Sql/3.5.1";
                },
                @{
                    "name" = "Az.Compute";
                    "url"  = "https://www.powershellgallery.com/api/v2/package/Az.Compute/4.17.1";
                },
                @{
                    "name" = "Az.KeyVault";
                    "url"  = "https://www.powershellgallery.com/api/v2/package/Az.KeyVault/3.6.0";
                },
                @{
                    "name" = "Az.Resources";
                    "url"  = "https://www.powershellgallery.com/api/v2/package/Az.Resources/4.4.0";
                }
            )
        }
        try {
            $aaa = Invoke-ARM -context $Context -template "automationAccount" -resourceGroupName $Context.resourceGroupNames.admin -parameters $aaaParams
        }
        catch {
            # Note: sometimes the modules intermittently fail to install with a Conflict against that Azure resource; just re-run it
            Write-Warning "Automation account deployment failed ($_); re-trying it one more time since it's likely an intermittent module installation error."
            $aaa = Invoke-ARM -context $Context -template "automationAccount" -resourceGroupName $Context.resourceGroupNames.admin -parameters $aaaParams
        }

        $aaaName = $aaa.automationAccountName.value

        ###############################################################################
        ## Automation Run As Account
        ###############################################################################

        if ($Context.deployAzureADResources) {
            Write-Host "$(Get-Date -Format FileDateTimeUniversal) Executing '$aaaName' run as account creation."

            # Create RunAs certificate in Key Vault

            $RunAsAccountName = $aaaName + "-RunAs";
            $monthsMaxCertificateLife = $Context.automationRunAs.maxCertificateExpiryInMonths;
            $monthsMinCertificateLife = $Context.automationRunAs.minCertificateExpiryInMonths

            Write-Host "Checking if there is an existing Azure KeyVault certificate for the Automation Account."
            $AzureKeyVaultCertificate = Get-AzKeyVaultCertificate -VaultName $deploymentKeyVaultName -Name $RunAsAccountName -ErrorAction SilentlyContinue

            if (-not($AzureKeyVaultCertificate) -or ($AzureKeyVaultCertificate).Created -gt (Get-Date).AddMonths($monthsMaxCertificateLife - $monthsMinCertificateLife)) {
                Write-Host "Creating new Azure KeyVault certificate for the Automation Account."

                $AzureKeyVaultCertificatePolicy = New-AzKeyVaultCertificatePolicy `
                    -SubjectName ("CN=" + $aaaName) -IssuerName "Self" -KeyType "RSA" `
                    -KeyUsage "DigitalSignature" -ValidityInMonths $monthsMaxCertificateLife `
                    -RenewAtNumberOfDaysBeforeExpiry 20 -KeyNotExportable:$False `
                    -ReuseKeyOnRenewal:$False

                $AzureKeyVaultCertificate = Add-AzKeyVaultCertificate `
                    -VaultName $deploymentKeyVaultName -Name $RunAsAccountName `
                    -CertificatePolicy $AzureKeyVaultCertificatePolicy

                do {
                    Start-Sleep -Seconds 10
                } until ((Get-AzKeyVaultCertificateOperation -Name $RunAsAccountName -vaultName $deploymentKeyVaultName).Status -eq "completed")
            }
            else {
                Write-Host ($AzureKeyVaultCertificate.Name + " certificate exists and is valid for at least " + $monthsMinCertificateLife + " more months.")
            }

            # Retrieve the run as certificate from key vault and convert to PFX

            $x509Cert = Request-X509FromAzureKeyVault -KeyVaultName $deploymentKeyVaultName -CertificateName $RunAsAccountName
            $pfxPassword = Get-KeyVaultCertificatePassword
            $pfxFilePath = Get-PFXFilePath
            Out-PfxFile -x509Cert $x509Cert -pfxPassword $pfxPassword -pfxFilePath $pfxFilePath

            Write-Host "Get App Registration for $($RunAsAccountName)"

            # Create the RunAs App Registration if it doesn't already exist
            $AzADApplicationRegistration = Get-AzADApplication -DisplayName $RunAsAccountName -ErrorAction SilentlyContinue

            Write-Host "App Registration Name $($AzADApplicationRegistration.DisplayName) and ObjectId $($AzADApplicationRegistration.ObjectId)" -ErrorAction SilentlyContinue

            if (-not($AzADApplicationRegistration)) {
                Write-Host "Creating a new AD Application for $RunAsAccountName"
                $AzADApplicationRegistration = New-AzADApplication -DisplayName $RunAsAccountName -HomePage "http://$($RunAsAccountName)" -IdentifierUris ("http://" + (New-Guid).Guid.ToString())
                $AzADServicePrincipal = New-AzADServicePrincipal -ApplicationId $AzADApplicationRegistration.ApplicationId -SkipAssignment
            }

            Write-Host "Try Publish-Variables" 

            Publish-Variables -vars @{ "automationAccountPrincipalId" = $AzADApplicationRegistration.ObjectId; }

            Write-Host "Passed Publish-Variables" 

            # Get RunAs service principal (App Registration) certificate secrets
            $accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
            $appRegistrationAppId = $AzADApplicationRegistration.ApplicationId
            $graphUrl = "https://graph.microsoft.com/v1.0/myorganization/applications?`$filter=appId%20eq%20'$appRegistrationAppId'"
            $graphResponse = Invoke-WebRequest -Uri $graphUrl -Headers @{"Authorization" = "Bearer $accessToken" }
            $graphResponseJson = ($graphResponse.Content | ConvertFrom-Json)
            $keyCredentials = $graphResponseJson.value | Select-Object -expandProperty keyCredentials

            # look for an existing certificate secret with the matching thumbprint
            $keys = $keyCredentials `
            | Where-Object {
                $_.type -eq "AsymmetricX509Cert" `
                    -and $_.usage -eq "Verify" `
                    -and $_.customKeyIdentifier -eq $x509Cert.Thumbprint
            }

            if ($keys -and ([array]$keys).Length -gt 0) {
                Write-Host "Required key vault certificate secret already exists on App Registration $($AzADApplicationRegistration.DisplayName), no need to add it again."
            }
            else {
                # No matching cert secret on the app registration, so add it
                # Register the certificate with Azure AD app to be able to be used to authenticate the service principal

                Write-Host "RunAs service principal does not have the Key Vault certificate set as a secret on App Registration $($AzADApplicationRegistration.DisplayName)"
                $AzKeyVaultCertificateStringValue = [System.Convert]::ToBase64String($x509Cert.GetRawCertData())
                New-AzADAppCredential `
                    -ApplicationId $AzADApplicationRegistration.ApplicationId `
                    -CertValue $AzKeyVaultCertificateStringValue `
                    -StartDate $x509Cert.NotBefore -EndDate $x509Cert.NotAfter
            }

            # Upload the certificate to Azure Automation runas account

            $ConnectionFieldData = @{
                "ApplicationId"         = $AzADApplicationRegistration.ApplicationId
                "TenantId"              = (Get-AzContext).Tenant.ID
                "CertificateThumbprint" = $x509Cert.Thumbprint
                "SubscriptionId"        = (Get-AzContext).Subscription.ID
            }

            # No need to check the existence, thumbprint value, or expiry of what might already be there.
            # Removing and re-adding the AzAutomationCertificate/Connection doesn't leave any
            # secrets/certs/junk lying around, so it's easier to just remove it and re-add it.
            $AutomationCertificate = Get-AzAutomationCertificate -ResourceGroupName $Context.resourceGroupNames.admin -AutomationAccountName $aaaName -ErrorAction SilentlyContinue
            $AutomationConnection = Get-AzAutomationConnection -ResourceGroupName $Context.resourceGroupNames.admin -AutomationAccountName $aaaName -Name "AzureRunAsConnection" -ErrorAction SilentlyContinue
            if ($AutomationCertificate) {
                Invoke-WithTemporaryNoResourceLocks -resourceGroupName $Context.resourceGroupNames.admin `
                    -codeToExecute `
                {
                    $AutomationCertificate | Remove-AzAutomationCertificate -Confirm:$false
                    $AutomationConnection | Remove-AzAutomationConnection -Confirm:$false -Force
                }
            }

            New-AzAutomationCertificate -ResourceGroupName $Context.resourceGroupNames.admin -AutomationAccountName $aaaName -Path $pfxFilePath -Name "AzureRunAsCertificate" -Password $pfxPassword -Exportable:$false
            New-AzAutomationConnection -ResourceGroupName $Context.resourceGroupNames.admin -AutomationAccountName $aaaName -Name "AzureRunAsConnection" -ConnectionTypeName "AzureServicePrincipal" -ConnectionFieldValues $ConnectionFieldData

            # Remove the RunAs Service Principal's subscription-wide Contributor role assignment, if it exists.

            $AzADServicePrincipal = $AzADApplicationRegistration | Get-AzADServicePrincipal
            $runAsContributorAssignment = Get-AzRoleAssignment -ObjectId $AzADServicePrincipal.Id `
                -RoleDefinitionName 'Contributor' -Scope "/subscriptions/$SubscriptionId"
            if ($runAsContributorAssignment) {
                Write-Host "RunAs Service Principal $($AzADServicePrincipal.DisplayName) has a subscription-wide role Contributor role assignment... removing the role assignment"
                $runAsContributorAssignment | Remove-AzRoleAssignment
            }

            # Give RunAs service principal contributor level access to Data resource group
            $dataRgRoleParams = Get-Params -context $Context -with @{
                "principalId"     = $AzADServicePrincipal.Id;
                "builtInRoleType" = "Contributor";
                "resourceId"      = (Get-AzResourceGroup -Name $Context.resourceGroupNames.data).ResourceId
                "roleGuid"        = "guidRunAsToDataRg"; # To keep idempotent, dont change this string after first run
            }
            Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $dataRgRoleParams

            # Give RunAs service principal VM Administrator level access to Compute resource group
            $computeRgRoleParams = Get-Params -context $Context -with @{
                "principalId"     = $AzADServicePrincipal.Id;
                "builtInRoleType" = "Virtual Machine Contributor";
                "resourceId"      = (Get-AzResourceGroup -Name $Context.resourceGroupNames.admin).ResourceId
                "roleGuid"        = "guidRunAsToComputeRg"; # To keep idempotent, dont change this string after first run
            }
            Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.admin -parameters $computeRgRoleParams

            Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) '$aaaName' run as account created successfully.`r`n"


        }
        else {
            Write-Warning "⚠️  Skipping creation of Azure AD Service Principal for Automation Run As account due to no permission on the Azure AD tenancy $TenantId; follow documentation to manually configure this otherwise the automation will not run successfully."

            Publish-Variables -vars @{ "automationAccountPrincipalId" = $Context.automationAccountPrincipalId }
        }

        ###############################################################################
        ## Web Connections
        ###############################################################################

        $webConnectionParams = Get-Params -context $Context -configKey "webConnection" -with @{
            "connectionTypes" = @("azureautomation", "office365")
        }

        $webConnection = Invoke-ARM -context $Context -template "webConnection" -resourceGroupName $Context.resourceGroupNames.admin -parameters $webConnectionParams

        ###############################################################################
        ## Scale VMs Logic App
        ###############################################################################

        $scaleVMsLogicAppParams = Get-Params -context $Context -diagnostics $diagnostics -with @{
            "lgaName"     = Get-ResourceName -context $Context -resourceCode "LGA" -suffix "ScaleVMs";
            "aaaName"     = $aaaName;
            "runbookName" = "Resize_VM";
        }
        $scaleVMsLogicApp = Invoke-ARM -context $Context -template "logicApp.VMScale" -resourceGroupName $Context.resourceGroupNames.admin -parameters $scaleVMsLogicAppParams

        #Publish the Scale VMs Logic App HTTP trigger url to pre-populate the SQL configuration data
        Get-OrSetKeyVaultSecret -keyVaultName $deploymentKeyVaultName -secretName "logicAppScaleVMUrl" -secretValue $scaleVMsLogicApp.callbackURL.value | Out-Null

        ###############################################################################
        ## Scale SQL Logic App
        ###############################################################################

        $scaleSQLLogicAppParams = Get-Params -context $Context -diagnostics $diagnostics -with @{
            "lgaName"     = Get-ResourceName -context $Context -resourceCode "LGA" -suffix "ScaleSQL";
            "aaaName"     = $aaaName;
            "runbookName" = "Scale_Azure_SQL";
        }
        $scaleSQLLogicApp = Invoke-ARM -context $Context -template "logicApp.SQLScale" -resourceGroupName $Context.resourceGroupNames.admin -parameters $scaleSQLLogicAppParams

        #Publish the Scale SQL Logic App HTTP trigger url to pre-populate the SQL configuration data
        Get-OrSetKeyVaultSecret -keyVaultName $deploymentKeyVaultName -secretName "logicAppScaleSQLUrl" -secretValue $scaleSQLLogicApp.callbackURL.value | Out-Null

        ###############################################################################
        ## Send email Logic App
        ###############################################################################

        $sendMailLogicAppParams = Get-Params -context $Context -diagnostics $diagnostics -with @{
            "lgaName" = Get-ResourceName -context $Context -resourceCode "LGA" -suffix "SendMail";
        }
        $sendMailLogicApp = Invoke-ARM -context $Context -template "logicApp.Office365Email" -resourceGroupName $Context.resourceGroupNames.admin -parameters $sendMailLogicAppParams

        #Publish the Scale SQL Logic App HTTP trigger url to pre-populate the SQL configuration data
        Get-OrSetKeyVaultSecret -keyVaultName $deploymentKeyVaultName -secretName "logicAppSendEmailUrl" -secretValue $sendMailLogicApp.callbackURL.value | Out-Null
    }
}
catch {
    Write-Host -ForegroundColor Red "Caught an exception of type $($_.Exception.GetType())"
    Write-Host -ForegroundColor Red $_.Exception.Message

    if ($_.ScriptStackTrace) {
        Write-Host -ForegroundColor Red $_.ScriptStackTrace
    }

    if ($_.Exception.InnerException) {
        Write-Host -ForegroundColor Red "Caused by: $($_.Exception.InnerException.Message)"
    }

    throw
}