# Optional features

[[_TOC_]]

## Using CIS pre-hardened base images

The virtual machines by default are using the `MicrosoftWindowsServer` OS publisher virtual machine type. For production usage, it's highly recommended to use the [CIS hardened virtual machines](https://www.cisecurity.org/cis-hardened-images/). To make this happen you must complete two steps:

1. Update `config.{env}.json` to use the CIS hardened variables.

```json
  "virtualMachine": {
    "OSPublisher": "center-for-internet-security-inc",
    "OSOffer": "cis-ws2019-l1",
    "OSVersion":  "cis-windows-server-2019-v1-0-0-l1",
  }
```

2. Accept the terms of the Marketplace VM image by running the following PowerShell cmdlet in the customers subscription and Azure AD tenancy.

```powershell
  Set-AzMarketplaceTerms -Publisher "center-for-internet-security-inc" -Product "cis-ws2019-l1" -Name "cis-windows-server-2019-v1-0-0-l1" | Set-AzMarketplaceTerms -Accept
```

For more information, refer to the following [Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/az.marketplaceordering/set-azmarketplaceterms?view=azps-5.1.0) page.

## Communicating with on-premises data source

The data factory pipelines look for the following secrets in the operational Key Vault, which you would need to manually add:

- `onPremisesUserName`
- `onPremisesPassword`
