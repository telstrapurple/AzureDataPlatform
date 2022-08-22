# Known limitations

[[_TOC_]]

## KeyVault backed Databricks scope and Service Principals

Currently, as of December 2020, service principals cannot add or control KeyVault backed Databricks secret scopes. To mitigate or workaround this, the `Deploy-KeyVault.ps1` script prints a `Write-Warning` message with the exact cmdlets that need to be run by a privileged user account.
