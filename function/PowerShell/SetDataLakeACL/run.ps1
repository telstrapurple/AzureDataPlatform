using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
# Interact with query parameters or the body of the request.
$permissionsObject = $Request.Body

$pathDictionary = @{};

Try {
    # Get storage account 
    $body = $null
    if ($null -ne $permissionsObject) {
        $serviceEndpoint = $permissionsObject.serviceEndpoint.TrimEnd("/") + "/"
        $selectedStorageAccount = Get-AzStorageAccount | Where-Object { $_.PrimaryEndpoints.Dfs -eq $serviceEndpoint -or $_.PrimaryEndpoints.Blob -eq $serviceEndpoint }
        if ($selectedStorageAccount) {
            # Get a context to apply the ACL's
            $storageAccountName = $selectedStorageAccount.StorageAccountName
            $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

            foreach ($acl in $permissionsObject.aclPermissions) {
                if (-Not $pathDictionary.ContainsKey($acl.path)) {
                    $pathDictionary += @{$acl.path = @() };
                }
                $pathDictionary[$acl.path] += $acl;
            }
            Write-Host $pathDictionary.Keys
            foreach ($key in $pathDictionary.Keys) {
                Write-Host "1.0"

                # Split the path to get the container name and folder path
                $fileSystem = $key.Split("/")[0]
                $path = $key.Replace($fileSystem, '', 1).TrimStart("/")
                # Check the current ACLs - Re-apply if the permission doesn't exist or has been modified
                $currentACLList = (Get-AzDataLakeGen2Item -Context $storageContext -FileSystem $fileSystem -Path $path -ErrorAction SilentlyContinue).ACL

                $currentACLList = Set-AzDataLakeGen2ItemAclObject -AccessControlType "user" -Permission "rwx"
                $currentACLList = Set-AzDataLakeGen2ItemAclObject -AccessControlType "group" -Permission "r-x" -InputObject $currentACLList
                $currentACLList = Set-AzDataLakeGen2ItemAclObject -AccessControlType "other" -Permission "---" -InputObject $currentACLList

                foreach ($acl in $pathDictionary[$key]) {
                    Write-Host "1.1"

                    if ($acl.permission.Length -ne 3) {
                        $body = "Please specify the correct permission. Supplied value is $($acl.permission)"
                        break
                    }
                    if ([string]::IsNullOrEmpty($acl.path)) {
                        $body = "Please specify a path"
                        break
                    }
                    if ($acl.path.Split("/").Length -le 1) {
                        $body = "Please specify a path in addition to the name of the storage container. Supplied value is $($acl.path)"
                        break
                    }
                    # Check if the supplied Azure AD object exists
                    if ($acl.objectType -notin ("User", "Group", "ServicePrincipal")) {
                        $body = "Please provide the correct object type. Supplied value is $($acl.objectType)"
                        break
                    }
                    Write-Host "1.2"

                    $accessControlType = switch ($acl.objectType) {
                        "User" { "user" }
                        "Group" { "group" }
                        "ServicePrincipal" { "user" }
                        Default { "other" }
                    }
                    
                    Write-Host "1.3"
                    $currentACLList = Set-AzDataLakeGen2ItemAclObject -AccessControlType $accessControlType -EntityId $acl.objectID -Permission $acl.permission -InputObject $currentACLList
                    $currentACLList = Set-AzDataLakeGen2ItemAclObject -AccessControlType $accessControlType -EntityId $acl.objectID -Permission $acl.permission -DefaultScope -InputObject $currentACLList

                    # DEVELOPER'S NOTE
                    # Previously we would automatically set execute permissions up the parent tree here
                    # This is now being done manually by administrators, because we were finding we couldn't
                    # revoke the access once it was granted.
                    # A solution for this would be to pass a parent AAD group to this function app, to which
                    # all other relevant AAD groups belong, and grant that group execute access up the chain.
                    # The code to set EXE permissions up the chain can be found int his commit:
                    # cc0810ac495941349389da673c72c5df2d98dea1
                }
                
                $result = Set-AzDataLakeGen2AclRecursive -Context $storageContext -FileSystem $fileSystem -Path $path -Acl $currentACLList -ContinueOnFailure
                Write-Host "1.6"
                # Retry failed assignments
                $result.FailedEntries
                foreach ($path in $result.FailedEntries.Name) {
                    # Set the ACL again
                    Set-AzDataLakeGen2AclRecursive -Context $storageContext -FileSystem $fileSystem -Path $path -Acl $currentACLList
                }
                $currentACLList = $null
            }
            if ($null -eq $body) {
                $body = "Success"
            }
        }
        else {
            $body = "Cannot find storage account '$storageAccountName' because it does not exist. Please make sure the name of storage is correct."
        }
    }
    else {
        $noop = 1
    }
}
catch {
    $body = $_.Exception.Message
}

# Status code 
if (($body -eq "Success") -or $noop) {
    $status = [HttpStatusCode]::OK
}
else {
    $status = [HttpStatusCode]::BadRequest
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body       = ($body | Select-Object @{n = "Response"; e = { $body } } | ConvertTo-Json)
    })
