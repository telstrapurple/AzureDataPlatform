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

    [Parameter(Mandatory = $false)]
    [string] $GlobalAdminGroupId,

    [Parameter(Mandatory = $true)]
    [string] $databasesObject,

    [Parameter(Mandatory = $true)]
    [string] $sqlServerDomainName,

    [Parameter(Mandatory = $true)]
    [string] $deploymentKeyVaultName,

    [Parameter(Mandatory = $true)]
    [string] $generalNetworkObject,

    [Parameter(Mandatory = $true)]
    [string] $diagnosticsObject,

    [Parameter(Mandatory = $true)]
    [string] $dataFactoryResourceId,

    [Parameter(Mandatory = $true)]
    [string] $dataLakeResourceId,

    [Parameter(Mandatory = $false)]
    [string] $pullSourceAppId,

    [Parameter(Mandatory = $false)]
    [string] $pullSourceUrl,

    [Parameter(Mandatory = $false)]
    [string] $databricksServicePrincipalId,

    [Parameter(Mandatory = $false)]
    [string] $dataFactoryPrincipalId
)

Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "./functions/adp.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/keyvault.psm1") -Force -Verbose:$false
Import-Module (Join-Path $PSScriptRoot "./functions/azuread.psm1") -Force -Verbose:$false

$Context = Initialize-ADPContext -parameters $PSBoundParameters -configFilePath (Join-Path $PSScriptRoot $ConfigFile)
$databases = ConvertFrom-JsonToHash -Object $databasesObject
$generalNetwork = ConvertFrom-JsonToHash -Object $generalNetworkObject
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

        $webAppName = Get-ResourceName -context $Context -resourceCode "APP" -suffix "001"
        $webApiName = Get-ResourceName -context $Context -resourceCode "APP" -suffix "002"

        ###############################################################################
        ## Application Insights
        ###############################################################################

        $appInsightsParams = Get-Params -context $Context -diagnostics $diagnostics -with @{
            "ainName" = (Get-ResourceName -context $Context -resourceCode "AIN" -suffix "001");
        }
        $appInsights = Invoke-ARM -context $Context -template "applicationInsights" -resourceGroupName $Context.resourceGroupNames.admin -parameters $appInsightsParams
        $appInsightsKey = $appInsights.appInsightsInstrumentationKey.value

        ################################################################################
        ## Admin Service Plan
        ################################################################################

        $adminServicePlanParams = Get-Params -context $Context -configKey "adminServicePlan" -diagnostics $diagnostics -with @{
            "servicePlanName" = (Get-ResourceName -context $Context -resourceCode "ASP" -suffix "001");
        }
        $adminServicePlan = Invoke-ARM -context $Context -template "appServicePlan" -resourceGroupName $Context.resourceGroupNames.admin -parameters $adminServicePlanParams
        $adminServicePlanId = $adminServicePlan.servicePlanResourceId.value;

        ###############################################################################
        ## Web App - Azure AD Application Registration
        ###############################################################################

        $webAppAADDisplayName = "$webAppName-Auth"
        if ($Context.webAppAADAppRegistration.displayName) {
            $webAppAADDisplayName = $Context.webAppAADAppRegistration.displayName
        }

        $monthsMaxCredentialLife = $Context.webAppAADAppRegistration.maxCredentialExpiryInMonths
        $monthsMinCredentialLife = $Context.webAppAADAppRegistration.minCredentialExpiryInMonths

        if ($Context.deployAzureADResources) {
            $AzADApplicationRegistration = Get-AzADApplication -DisplayName $webAppAADDisplayName -ErrorAction SilentlyContinue
            if (-not($AzADApplicationRegistration)) {
                Write-Host "$(Get-Date -Format FileDateTimeUniversal) Executing '$webAppName' Azure AD application creation."
                $AzADApplicationRegistration = New-AzADApplication -DisplayName $webAppAADDisplayName -HomePage "https://$webAppName.azurewebsites.net" -IdentifierUris ("https://$webAppName.azurewebsites.net")
            }
            $azureADObjectId = $AzADApplicationRegistration.ObjectId

            # Get the latest credential for the Application Registration
            #
            # Unfortunately the underlying .NET class for this API returns the EndDate as a string (Why?!?) not a Date object which
            # means we can't reliably do sorting as it may be locale dependant (e.g. M/d/Y can't alpha sort correctly). Instead we
            # map the array and convert the string into a DateFormat, which is then sortable. This does depend on the underlying
            # .NET class to use the same default datetime formatting
            $LatestAppCred = Get-AzADAppCredential -ApplicationId $AzADApplicationRegistration.ApplicationId.Guid |
            ForEach-Object { Write-Output ([DateTime]::Parse($_.EndDate)) } |
            Sort-Object -Descending |
            Select-Object -First 1

            # Does the Credential Secret Key exist and is still young enough? If not, create a new one
            if (-not($LatestAppCred) -or ($LatestAppCred -lt (Get-Date).AddMonths($monthsMinCredentialLife))) {
                if ($LatestAppCred) { Write-Host "Azure AD Application will expire" }
                Write-Host "Creating new Azure AD application credential for Web App."
                $secretValueText = Get-RandomPassword
                New-AzADAppCredential -ApplicationId $AzADApplicationRegistration.ApplicationId -Password $secretValueText -StartDate (Get-Date).AddMinutes(-5).ToUniversalTime() -EndDate (Get-Date).AddMonths($monthsMaxCredentialLife).ToUniversalTime()
                Set-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -SecretName 'webappApplicationKey' -SecretValue $secretValueText | Out-Null
            }
            else {
                Write-Host ($webAppName + " Azure AD application credential exists and is valid for at least $monthsMinCredentialLife more months.")
                $secret = Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'webappApplicationKey'
                if ($null -eq $secret) {
                    Throw "The 'webappApplicationKey' secret is missing in the Key Vault '$deploymentKeyVaultName'. Please remove any valid credentials in the '$webAppAADDisplayName' Application Registration to force a new credential to be created and saved in the KeyVault"
                }
                $secretValueText = $secret | Select-Object -ExpandProperty SecretValue | ConvertFrom-SecureString -AsPlainText
            }
            Publish-Variables -vars @{ "webappApplicationKey" = $secretValueText } -isSecret

            $azureADDomain = Get-AzTenant -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $TenantId }
            if ($azureADDomain.Domains) {
                $azureADDomain = $azureADDomain.Domains[0];
            }
            else {
                $azureADDomain = $Context.webAppSettings.azureADDomainName
            }
            $azureADTenantId = $TenantId
            $azureADClientId = $AzADApplicationRegistration.ApplicationId.Guid
            $azureADClientSecret = $secretValueText
        }
        else {
            $azureADDomain = $Context.webAppSettings.azureADDomainName
            $azureADTenantId = $Context.webAppSettings.azureADTenantId
            $azureADClientId = $Context.webAppSettings.azureADApplicationClientId
            $azureADObjectId = $Context.webAppSettings.azureADApplicationObjectId
            $azureADClientSecret = $Context.webAppSettings.azureADApplicationClientSecret
        }

        ###############################################################################
        ## Web App
        ###############################################################################

        $existingWebApp = Get-AzWebApp -ResourceGroupName $Context.resourceGroupNames.admin -Name $webAppName -ErrorAction SilentlyContinue

        $datalakeStorageEndpoint = (Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'dataLakeStorageEndpoint').SecretValue | ConvertFrom-SecureString -AsPlainText

        $newAppSettings = @(
            @{
                "name"        = "APPINSIGHTS_INSTRUMENTATIONKEY";
                "value"       = $appInsightsKey;
                "slotSetting" = $false;
            },
            @{
                "name"        = "ApplicationInsightsAgent_EXTENSION_VERSION";
                "value"       = "~2";
                "slotSetting" = $false;
            },
            @{
                "name"        = "XDT_MicrosoftApplicationInsights_Mode";
                "value"       = "default";
                "slotSetting" = $false;
            },
            @{
                "name"        = "XDT_MicrosoftApplicationInsights_BaseExtensions";
                "value"       = "disabled";
                "slotSetting" = $false;
            },
            @{
                "name"        = "WEBSITE_VNET_ROUTE_ALL";
                "value"       = "0";
                "slotSetting" = $false;
            },
            @{
                "name"        = "WEBSITE_TIME_ZONE";
                "value"       = $Context.webAppSettings.websiteTimeZone;
                "slotSetting" = $false;
            },
            @{
                "name"        = "AzureAd:Domain";
                "value"       = $azureADDomain;
                "slotSetting" = $false;
            },
            @{
                "name"        = "azureAd:TenantId";
                "value"       = $azureADTenantId;
                "slotSetting" = $false;
            },
            @{
                "name"        = "azureAd:ClientId";
                "value"       = $azureADClientId;
                "slotSetting" = $false;
            },
            @{
                "name"        = "azureAd:ClientSecret";
                "value"       = $azureADClientSecret;
                "slotSetting" = $false;
            },
            @{
                "name"        = "ApplicationConfig:ConnectionString";
                "value"       = "Data Source=$sqlServerDomainName;Initial Catalog=$($databases.Config);Persist Security Info=False";
                "slotSetting" = $false;
            },
            # @{ Unused and causes error Login failed for user '<token-identified principal>'
            #     "name"        = "PullSource:BaseUrl";
            #     "value"       = $pullSourceUrl;
            #     "slotSetting" = $false;
            # },
            @{
                "name"        = "PullSource:Scopes";
                "value"       = "$pullSourceAppId/entities.pull";
                "slotSetting" = $false;
            },
            @{
                "name"        = "ApplicationConfig:DatalakeStorageEndpoint";
                "value"       = $datalakeStorageEndpoint;
                "slotSetting" = $false;
            },
            @{
                "name"        = "ApplicationConfig:EnvironmentName";
                "value"       = $EnvironmentName;
                "slotSetting" = $false;
            },
            @{
                "name"        = "ApplicationConfig:DatabricksServicePrincipal";
                "value"       = $databricksServicePrincipalId;
                "slotSetting" = $false;
            },
            @{
                "name"        = "ApplicationConfig:DatafactoryServicePrincipal";
                "value"       = $dataFactoryPrincipalId;
                "slotSetting" = $false;
            },
            @{
                "name"        = "ApplicationConfig:GlobalAdminGroupId";
                "value"       = $GlobalAdminGroupId;
                "slotSetting" = $false;
            }
        )

        $appSettings = @();
        if ($existingWebApp) {
            $appSettings = $existingWebApp.SiteConfig.AppSettings
        }

        $newAppSettings | ForEach-Object {
            $setting = $_
            $existingSetting = $null
            if ($existingWebApp) {
                $existingSetting = $appSettings | Where-Object { $_.Name -eq $setting.name }
            }
            if ($existingSetting) {
                $existingSetting.Value = $setting.value
            }
            else {
                $appSettings += $setting
            }
        }

        $webAppParams = Get-Params -context $Context -configKey "webApp" -purpose "ADP Configurator" -diagnostics $diagnostics -with @{
            "servicePlanId"          = $adminServicePlanId;
            "appName"                = $webAppName;
            "appSettings"            = $appSettings;
            "subnetWebAppResourceId" = $generalNetwork.subnetWebAppResourceId;
        }
        $webApp = Invoke-ARM -context $Context -template "webApp" -resourceGroupName $Context.resourceGroupNames.admin -parameters $webAppParams

        Publish-Variables -vars @{ "webAppServicePrincipalId" = $webApp.webAppServicePrincipalId.value; }

        ###############################################################################
        ## Web App - Azure AD Application Registration Manifest Update
        ###############################################################################

        if ($Context.deployAzureADResources) {
            $existingWebApp = Get-AzWebApp -ResourceGroupName $Context.resourceGroupNames.admin -Name $webAppName -ErrorAction SilentlyContinue

            # The $pullSourceAppId is set in the DevOps Library using a format of api://. 
            # This format is incorrect in the Manifest and the required GUID is extracted with this Select-String

            $guidPullSourceAppId = $pullSourceAppId | Select-String -Pattern '[-0-9a-f]+$' -AllMatches | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
            
            Write-Host -ForegroundColor Green "`r`n AppID: '$pullSourceAppId' and GUID: '$guidPullSourceAppId' `r`n"

            $body = @{
                "displayName"            = $webAppAADDisplayName;
                "web"                    = @{
                    "redirectUris"          = @("https://" + $existingWebApp.DefaultHostName + "/signin-oidc");
                    "implicitGrantSettings" = @{
                        "enableIdTokenIssuance" = "true"
                    }
                };
                "requiredResourceAccess" = @( @{
                        "resourceAppId"  = "00000003-0000-0000-c000-000000000000"; #Microsoft Graph
                        "resourceAccess" = @(
                            # If additional permissions are needed, the easiest way to find the correct GUIDs for
                            # the permissions you're adding is to add the permission manually in the Azure Portal
                            # and then look in the generated manifest.
                            @{
                                "id"   = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182"; #offline_access
                                "type" = "Scope"
                            },
                            @{
                                "id"   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; #User.Read
                                "type" = "Scope"
                            },
                            @{
                                "id"   = "37f7f235-527c-4136-accd-4a02d197296e"; #openid
                                "type" = "Scope"
                            },
                            @{
                                "id"   = "14dad69e-099b-42c9-810b-d002981feec1"; #profile
                                "type" = "Scope"
                            },
                            @{
                                "id"   = "14dad69e-099b-42c9-810b-d002981feec1"; #user.read
                                "type" = "Scope"
                            }
                        )
                    },
                    @{
                        "resourceAppId"  = $guidPullSourceAppId;
                        "resourceAccess" = @(
                            @{
                                "id"   = "f0a6bd21-1db7-4a1f-9d82-e09be81fc216";
                                "type" = "Scope";
                            }
                        )
                    }
                )
            }

            if ($context.webAppAADAppRegistration["enableLocalhostRedirectUrl"]) {
                # don't use . notation as it fails if the property is nullor does not exist
                # 44399 is the default localhost port for the ADSGoFast / ADPConfigurator webapp
                $body.web.redirectUris += @('http://localhost:44399/signin-oidc', 'https://localhost:44399/signin-oidc')
            }

            $azureGraphApiAadToken = Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com' | Select-Object -ExpandProperty Token
            try {
                Update-GraphApplication -azureGraphApiAadToken $azureGraphApiAadToken -applicationObjectId $azureADObjectId -bodyObject $body
            }
            catch {
                # Note: sometimes there is a 404 when the app registration is first created; just re-run it
                Write-Warning "Azure AD app manifest update failed ($_); re-trying it one more time after 30s since it's likely a timing issue."
                Start-Sleep -Seconds 30
                Update-GraphApplication -azureGraphApiAadToken $azureGraphApiAadToken -applicationObjectId $azureADObjectId -bodyObject $body
            }

            Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) '$webAppName' Azure AD application created successfully.`r`n"
        }

        if ($Context.create.ContainsKey('webApi') -and $Context.create.webApi) {
            ###############################################################################
            ## Web Api App - Azure AD Application Registration
            ###############################################################################
            $azureADDomain = $null
            $azureADTenantId = $null
            $azureADClientId = $null
            $azureADObjectId = $null
            $azureADClientSecret = $null

            $webApiAADDisplayName = "$webApiName-Auth"
            if ($Context.webApiAADAppRegistration.displayName) {
                $webApiAADDisplayName = $Context.webApiAADAppRegistration.displayName
            }

            $monthsMaxCredentialLife = $Context.webApiAADAppRegistration.maxCredentialExpiryInMonths
            $monthsMinCredentialLife = $Context.webApiAADAppRegistration.minCredentialExpiryInMonths

            if ($Context.deployAzureADResources) {
                $AzADApplicationRegistration = Get-AzADApplication -DisplayName $webApiAADDisplayName -ErrorAction SilentlyContinue
                if (-not($AzADApplicationRegistration)) {
                    Write-Host "$(Get-Date -Format FileDateTimeUniversal) Executing '$webApiName' Azure AD application creation."
                    $AzADApplicationRegistration = New-AzADApplication -DisplayName $webApiAADDisplayName -HomePage "https://$webApiName.azurewebsites.net"
                }
                $azureADObjectId = $AzADApplicationRegistration.ObjectId

                # Get the latest credential for the Application Registration
                #
                # Unfortunately the underlying .NET class for this API returns the EndDate as a string (Why?!?) not a Date object which
                # means we can't reliably do sorting as it may be locale dependant (e.g. M/d/Y can't alpha sort correctly). Instead we
                # map the array and convert the string into a DateFormat, which is then sortable. This does depend on the underlying
                # .NET class to use the same default datetime formatting
                $LatestAppCred = Get-AzADAppCredential -ApplicationId $AzADApplicationRegistration.ApplicationId.Guid |
                ForEach-Object { Write-Output ([DateTime]::Parse($_.EndDate)) } |
                Sort-Object -Descending |
                Select-Object -First 1

                # Does the Credential Secret Key exist and is still young enough? If not, create a new one
                if (-not($LatestAppCred) -or ($LatestAppCred -lt (Get-Date).AddMonths($monthsMinCredentialLife))) {
                    if ($LatestAppCred) { Write-Host "Azure AD Application will expire" }
                    Write-Host "Creating new Azure AD application credential for Web App."
                    $secretValueText = Get-RandomPassword
                    New-AzADAppCredential -ApplicationId $AzADApplicationRegistration.ApplicationId -Password $secretValueText -StartDate (Get-Date).AddMinutes(-5).ToUniversalTime() -EndDate (Get-Date).AddMonths($monthsMaxCredentialLife).ToUniversalTime()
                    Set-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -SecretName 'webapiApplicationKey' -SecretValue $secretValueText | Out-Null
                }
                else {
                    Write-Host ($webApiName + " Azure AD application credential exists and is valid for at least $monthsMinCredentialLife more months.")
                    $secret = Get-AzKeyVaultSecret -VaultName $deploymentKeyVaultName -Name 'webapiApplicationKey'
                    if ($null -eq $secret) {
                        Throw "The 'webapiApplicationKey' secret is missing in the Key Vault '$deploymentKeyVaultName'. Please remove any valid credentials in the '$webApiAADDisplayName' Application Registration to force a new credential to be created and saved in the KeyVault"
                    }
                    $secretValueText = $secret | Select-Object -ExpandProperty SecretValue | ConvertFrom-SecureString -AsPlainText
                }
                Publish-Variables -vars @{ "webapiApplicationKey" = $secretValueText } -isSecret

                $azureADDomain = Get-AzTenant -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $TenantId }
                if ($azureADDomain.Domains) {
                    $azureADDomain = $azureADDomain.Domains[0];
                }
                else {
                    $azureADDomain = $Context.webApiSettings.azureADDomainName
                }
                $azureADTenantId = $TenantId
                $azureADClientId = $AzADApplicationRegistration.ApplicationId.Guid
                $azureADClientSecret = $secretValueText
            }
            else {
                $azureADDomain = $Context.webApiSettings.azureADDomainName
                $azureADTenantId = $Context.webApiSettings.azureADTenantId
                $azureADClientId = $Context.webApiSettings.azureADApplicationClientId
                $azureADObjectId = $Context.webApiSettings.azureADApplicationObjectId
                $azureADClientSecret = $Context.webApiSettings.azureADApplicationClientSecret
            }

            ###############################################################################
            ## Web Api App
            ###############################################################################

            $existingWebApi = Get-AzWebApp -ResourceGroupName $Context.resourceGroupNames.admin -Name $webApiName -ErrorAction SilentlyContinue

            $newAppSettings = @(
                @{
                    "name"        = "APPINSIGHTS_INSTRUMENTATIONKEY";
                    "value"       = $appInsightsKey;
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "ApplicationInsightsAgent_EXTENSION_VERSION";
                    "value"       = "~2";
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "XDT_MicrosoftApplicationInsights_Mode";
                    "value"       = "default";
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "XDT_MicrosoftApplicationInsights_BaseExtensions";
                    "value"       = "disabled";
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "WEBSITE_TIME_ZONE";
                    "value"       = $Context.webAppSettings.websiteTimeZone;
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "AzureAd:Domain";
                    "value"       = $azureADDomain;
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "azureAd:TenantId";
                    "value"       = $azureADTenantId;
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "azureAd:ClientId";
                    "value"       = $azureADClientId;
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "azureAd:ClientSecret";
                    "value"       = $azureADClientSecret;
                    "slotSetting" = $false;
                },
                @{
                    "name"        = "azureAd:Scopes";
                    "value"       = "entities.pull";
                    "slotSetting" = $false;
                }
                @{
                    "name"        = "ApplicationConfig:ConnectionString";
                    "value"       = "Data Source=$sqlServerDomainName;Initial Catalog=$($databases.Config);Persist Security Info=False";
                    "slotSetting" = $false;
                }
            )

            $appSettings = @();
            if ($existingWebApi) {
                $appSettings = $existingWebApi.SiteConfig.AppSettings
            }

            $newAppSettings | ForEach-Object {
                $setting = $_
                $existingSetting = $null
                if ($existingWebApi) {
                    $existingSetting = $appSettings | Where-Object { $_.Name -eq $setting.name }
                }
                if ($existingSetting) {
                    $existingSetting.Value = $setting.value
                }
                else {
                    $appSettings += $setting
                }
            }

            $webAppParams = Get-Params -context $Context -configKey "webApi" -purpose "ADP Configurator API" -diagnostics $diagnostics -with @{
                "servicePlanId"          = $adminServicePlanId;
                "appName"                = $webApiName;
                "appSettings"            = $appSettings;
                "subnetWebAppResourceId" = $generalNetwork.subnetWebAppResourceId;
            }
            $webApi = Invoke-ARM -context $Context -template "webApp" -resourceGroupName $Context.resourceGroupNames.admin -parameters $webAppParams

            Publish-Variables -vars @{ "webApiServicePrincipalId" = $webApi.webAppServicePrincipalId.value; }

            ###############################################################################
            ## Web Api App - Azure AD Application Registration Manifest Update
            ###############################################################################
            <# Removed incomplete feature and it's causing errors. The configuration is still required and MUST set manually for now.
            if ($Context.deployAzureADResources) {
                $existingWebApi = Get-AzWebApp -ResourceGroupName $Context.resourceGroupNames.admin -Name $webApiName -ErrorAction SilentlyContinue

                $body = @{
                    "displayName"               = $webApiAADDisplayName;
                    "web"                       = @{
                        "redirectUris"          = @("https://" + $existingWebApi.DefaultHostName + "/signin-oidc");
                        "implicitGrantSettings" = @{
                            "enableIdTokenIssuance" = "true"
                        }
                    };
                    "oauth2Permissions"         = @(
                        @{
                            "adminConsentDescription" = "Allows the app to pull tasks and systems on your behalf";
                            "adminConsentDisplayName" = "Pull tasks and systems";
                            "id"                      = "f0a6bd21-1db7-4a1f-9d82-e09be81fc216";
                            "isEnabled"               = "true";
                            "lang"                    = "null";
                            "origin"                  = "Application";
                            "type"                    = "User";
                            "userConsentDescription"  = "Allows the app to pull tasks and systems on your behalf";
                            "userConsentDisplayName"  = "Pull tasks and systems";
                            "value"                   = "entities.pull";
                        }
                    );
                    "preAuthorizedApplications" = @(
                        @{
                            "appId"         = $pullSourceAppId;
                            "permissionIds" = @(
                                "f0a6bd21-1db7-4a1f-9d82-e09be81fc216";
                            )
                        }
                        @{
                            "appId"         = $azureADClientId;
                            "permissionIds" = @(
                                "f0a6bd21-1db7-4a1f-9d82-e09be81fc216";
                            )
                        }
                    );
                    "requiredResourceAccess"    = @(
                        @{
                            "resourceAppId"  = "00000003-0000-0000-c000-000000000000"; #Microsoft Graph
                            "resourceAccess" = @(
                                # If additional permissions are needed, the easiest way to find the correct GUIDs for
                                # the permissions you're adding is to add the permission manually in the Azure Portal
                                # and then look in the generated manifest.
                                @{
                                    "id"   = "37f7f235-527c-4136-accd-4a02d197296e"; #openid
                                    "type" = "Scope"
                                },
                                @{
                                    "id"   = "14dad69e-099b-42c9-810b-d002981feec1"; #profile
                                    "type" = "Scope"
                                }
                            )
                        }
                    )
                }

                if ($context.webApiAADAppRegistration["enableLocalhostRedirectUrl"]) {
                    # don't use . notation as it fails if the property is nullor does not exist
                    # 44399 is the default localhost port for the ADSGoFast / ADPConfigurator webapi
                    $body.web.redirectUris += @('http://localhost:44399/signin-oidc', 'https://localhost:44399/signin-oidc')
                }

                $azureGraphApiAadToken = Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com' | Select-Object -ExpandProperty Token
                try {
                    Update-GraphApplication -azureGraphApiAadToken $azureGraphApiAadToken -applicationObjectId $azureADObjectId -bodyObject $body
                }
                catch {
                    # Note: sometimes there is a 404 when the app registration is first created; just re-run it
                    Write-Warning "Azure AD app manifest update failed ($_); re-trying it one more time after 30s since it's likely a timing issue."
                    Start-Sleep -Seconds 30
                    Update-GraphApplication -azureGraphApiAadToken $azureGraphApiAadToken -applicationObjectId $azureADObjectId -bodyObject $body
                }

                Write-Host -ForegroundColor Green "`r`n✔️  $(Get-Date -Format FileDateTimeUniversal) '$webApiName' Azure AD application created successfully.`r`n"
            }
            #>
        }

        ###############################################################################
        ## Function App
        ###############################################################################

        $functionAppStorageParams = Get-Params -context $Context -configKey "functionAppStorage" -purpose "Function App" -diagnostics $diagnostics -with @{
            "staName"                    = Get-ResourceName -context $Context -resourceCode "STA" -suffix "04";
            "subnetIdArray"              = @();
            "bypassNetworkDefaultAction" = "None";
            "networkDefaultAction"       = "Allow";
        }
        $functionAppStorage = Invoke-ARM -context $Context -template "storageAccount" -resourceGroupName $Context.resourceGroupNames.admin -parameters $functionAppStorageParams
        $functionAppStorageName = $functionAppStorage.storageAccountName.value

        $functionAppParams = Get-Params -context $Context -configKey "functionApp" -diagnostics $diagnostics -with @{
            "appInsightsInstrumentationKey" = $appInsightsKey;
            "servicePlanId"                 = $adminServicePlanId;
            "appName"                       = (Get-ResourceName -context $Context -resourceCode "FNA" -suffix "001");
            "storageAccountName"            = $functionAppStorageName;
            "storageAccountResourceGroup"   = $Context.resourceGroupNames.admin;
            "subnetWebAppResourceId"        = $generalNetwork.subnetWebAppResourceId;
        }
        $functionApp = Invoke-ARM -context $Context -template "functionApp" -resourceGroupName $Context.resourceGroupNames.admin -parameters $functionAppParams
        $functionAppServicePrincipalId = $functionApp.functionAppServicePrincipalId.value;
        $functionAppMasterKey = $functionApp.functionAppMasterKey.value;
        $functionAppURL = $functionApp.functionAppURL.value;

        Publish-Variables -vars @{ "functionAppURL" = $functionAppURL; }
        Publish-Variables -vars @{ "functionAppServicePrincipalId" = $functionAppServicePrincipalId; }
        Publish-Variables -vars @{ "functionAppMasterKey" = $functionAppMasterKey } -isSecret

        ###############################################################################
        ## Function App - Role Assignments
        ###############################################################################

        # Give function App MSI read access to Data Factory
        $functionAppRoleParams = Get-Params -context $Context -with @{
            "principalId"     = $functionAppServicePrincipalId;
            "builtInRoleType" = "Reader";
            "resourceId"      = $dataFactoryResourceId;
            "roleGuid"        = "guidFunctionApptoDataFactory"; # To keep idempotent, dont change this string after first run
        }
        Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $functionAppRoleParams

        # Give function App MSI contributor access to the data lake
        $functionAppRoleParams = Get-Params -context $Context -with @{
            "principalId"     = $functionAppServicePrincipalId;
            "builtInRoleType" = "Owner";
            "resourceId"      = $dataLakeResourceId;
            "roleGuid"        = "guidFunctionApptoDatalake"; # To keep idempotent, dont change this string after first run
        }
        Invoke-ARM -context $Context -template "roleAssignment" -resourceGroupName $Context.resourceGroupNames.data -parameters $functionAppRoleParams
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