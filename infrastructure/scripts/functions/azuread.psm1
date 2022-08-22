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

function Get-CurrentServicePrincipalAzureAdApplicationId() {
    $account = (Get-AzContext).Account
    if ($account.Type -eq "ServicePrincipal") {
        return [guid]($account.Id)
    }
    return [guid]::Empty
}

function Get-CurrentUserAzureAdName() {
    $account = (Get-AzContext).Account
    if ($account.Type -eq 'User') {
        return $account.Id
    }
    $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $account.Id
    return $servicePrincipal.DisplayName
}

function Update-GraphApplication {
    param(
        [Parameter(Mandatory)]
        [string] $azureGraphApiAadToken,

        [Parameter(Mandatory)]
        [string]
        $applicationObjectId,

        [Parameter(Mandatory)]
        [object]
        $bodyObject
    )

    $uri = "https://graph.microsoft.com/beta/applications/$applicationObjectId"
    $headers = @{
        "Authorization" = "Bearer $azureGraphApiAadToken";
        "Content-Type"  = "application/json";
    }

    $bodyJSON = $bodyObject | ConvertTo-Json -Depth 10
    Write-Host "The bodyJSON: $($bodyJSON)"
    $response = Invoke-RestMethod -Uri $uri -Method "Patch" -Body $bodyJSON -Headers $headers
    return $response
}

function Get-OrNewAzureADGroup {
    param(
        [Parameter(Mandatory)]
        [string] $azureGraphApiAadToken,

        [Parameter(Mandatory)]
        [string]
        $displayName,

        [Parameter(Mandatory)]
        [string]
        $description,

        [switch]
        $isAssignableToRole = $false,

        [switch]
        $isMailEnabled = $false,

        [switch]
        $isSecurityEnabled = $false,

        [switch]
        $isO365Group = $false
    )

    $headers = @{
        "Authorization" = "Bearer $azureGraphApiAadToken";
        "Content-Type"  = "application/json";
    }

    $getUri = "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$displayName'"
    $existing = Invoke-RestMethod -Uri $getUri -Method "GET" -Headers $headers -Verbose:$false

    if ($existing.value.Length -eq 1) {
        return $existing.value[0]
    }
    else {
        $uri = "https://graph.microsoft.com/beta/groups"

        $ownerUrl = "https://graph.microsoft.com/v1.0/users/"
        $userType = (Get-AzContext).Account.Type
        if ($userType -eq "ServicePrincipal") {
            $ownerUrl = "https://graph.microsoft.com/v1.0/servicePrincipals/"
        }

        $bodyObject = @{
            "description"        = $description;
            "groupTypes"         = $isO365Group ? @("Unified") : @();
            "mailEnabled"        = $isMailEnabled ? $true : $false;
            "securityEnabled"    = $isSecurityEnabled ? $true : $false;
            "mailNickname"       = ($displayName -replace "[@\(\)\\\[\]"";:\.<>, ]", "-");
            "displayName"        = $displayName;
            "isAssignableToRole" = $isAssignableToRole ? $true : $false;
            # Set current user as the owner
            "owners@odata.bind"  = @($ownerUrl + (Get-CurrentUserAzureAdObjectId))
        }

        $bodyJSON = $bodyObject | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $uri -Method "POST" -Body $bodyJSON -Headers $headers -Verbose:$false
        return $response
    }
}

function Get-OrAddAzureADRoleAssignment {
    param(
        [Parameter(Mandatory)]
        [string] $azureGraphApiAadToken,

        [Parameter(Mandatory)]
        [string]
        $principalId,

        [Parameter(Mandatory)]
        [string]
        $roledisplayName
    )
    $headers = @{
        "Authorization" = "Bearer $azureGraphApiAadToken";
        "Content-Type"  = "application/json";
    }

    $getUri = "https://graph.microsoft.com/beta/roleManagement/directory/roleDefinitions?`$filter=displayName eq '$roledisplayName'"
    $getId = Invoke-RestMethod -Uri $getUri -Method "GET" -Headers $headers -Verbose:$false

    if ($getId.value.Length -eq 1) {
        $roleDefinitionId = $getId.value[0].id

        $getUri2 = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignments?`$filter=roleDefinitionId eq '$roleDefinitionId' and principalId eq '$principalId'&`$expand=principal"
        $getRoleId = Invoke-RestMethod -Uri  $getUri2 -Method "GET" -Headers $headers -Verbose:$false

        if ($getRoleId.value.Length -eq 1) {
            return $true
        }
        else {
            $postUri = "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignments"

            $bodyObject = @{
                "principalId"      = $principalId;
                "roleDefinitionId" = $roleDefinitionId;
                "directoryScopeId" = "/";
            }
            $bodyJSON = $bodyObject | ConvertTo-Json -Depth 10
            try {
                Invoke-RestMethod -Uri $postUri -Method "POST" -Body $bodyJSON -Headers $headers -Verbose:$false
                return $true
            }
            catch {
                return $false
            }
        }
    }
    else {
        return $false
    }
}

function Get-AzADGroupObjectOrDisplayName([string] $displayNameObjectId) {
    if (Assert-Guid $displayNameObjectId) {
        $group = Get-AzADGroup -ObjectId $displayNameObjectId -ErrorAction SilentlyContinue
    }
    else {
        $group = Get-AzADGroup -DisplayName $displayNameObjectId -ErrorAction SilentlyContinue
    }
    return $group
}

Export-ModuleMember -Function * -Verbose:$false