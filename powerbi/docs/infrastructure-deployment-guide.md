# Infrastructure Deployment Guide
The aim of this guide is to provide Telstra Purple consultants with the steps required to deploy and configure the Azure Infrastructure required to support Agile Enterprise BI. 

## Table of Contents
| No | Title | Notes |
|---|---|---|
|01| [XXX](#XXX) | - | 


# Infrastructure architecture overview
The diagram below explains how the infrastructure is configured for Agile Enterprise BI. 
![Architecture diagram](img/architecture-diagram.png)

### Resources
The following Azure Resources are deployed with the corresponding purposes below:
|Resource|Purpose| 
|---|---|
|Power BI Service|Used for storing Power BI assets for enterprise consumption.|
|On-premises Data Gateway|Used by Power BI Service to access on-premise data sources or data sources behind a client's virtual network.|
|Azure Virtual Machines|Used for: (A) hosting the Power BI Gateway (B) as a Hybrid Worker for Azure Automation.|
|Azure SQL Server and Database|Persistent storage for Power BI Log data.|
|PowerBILogs SQL Project|Contains schema, objects and stored procedures for persistent storage of Power BI Log data. Data is modelled using Views and subsequently used by Power BI Log Report.|
|Azure Log Analytics|Push logs to Log Analytics. Easily configure alerts.|
|Azure Automation|Used for scheduling and running jobs to export Power BI Logs.|
|Azure Automation RunAs Account|Used by Azure Automation to authenticating to Azure Services.|
|Azure Key Vault|Store credentials to Azure SQL Database, Log Analytics, and Power BI Service. Credentials accessed by Azure Automation RunAs Account for running export log job.|


### Network
1. The client's on-premise environment is assumed to have been connected to Azure through a VPN Gateway and ExpressRoute. This allows the client's traffic to flow between on-premise and Azure. (Refer to "On-Premises Environment" in the diagram).
2. A Virtual Network that performs the role of a "Hub" (see [Hub and Spoke model](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)) is assumed to have been created and is managed by the client. (Refer to "Networking ARG" in the diagram).
3. Other resource groups ("Spokes") are also assumed to exist and are assumed to be connected to the "Hub" through either vNet peering if the Spokes are in separate vNets, or if all resources are in the same vNet but in separate subnets, then NSG rules have been applied to allow traffic to flow between subnets. (Refer to "Other RGs" in the diagram).
4. We deploy a new vNet ("Power BI vNet") into the client's existing Networking Resource Group. The Power BI vNet is peered to the "Hub" vNet to allow for connectivity back to on-premise data sources. A single subnet is created ("Power BI Subnet"). 
5. We deploy resources as mentioned in the [resources](###resources) section above. For each resource, the following connections are applied to allow connectivity between resources and back to on-premise:

|Resource|Connectivity|
|---|---|
|Azure Virtual Machines (On-premise data gateway)|Virtual machines are added to the Power BI subnet. NSG rules can be applied to the subnet or VM's NIC.|
|Azure Virtual Machines (Hybrid workers)|Virtual machines are added to the Power BI subnet. NSG rules can be applied to the subnet or VM's NIC.|
|Azure SQL Server and Database|Deny all is applied for public in-bound traffic to the SQL Server. Service Endpoint for `Microsoft.SQL` is enabled on the Power BI vNet. A connection to the Power BI vNet is created on the SQL Server, allowing traffic to flow between the Power BI vNet and the SQL Server.|
|Azure Log Analytics|Log Analytics is a fully Azure managed service. Connectivity to Log Analytics is via the public internet, however only AAD token based authentication is supported.|
|Azure Key Vault|Deny all is applied for public in-bound traffic to the Key Vault. Service Endpoint for `Microsoft.KeyVault` is enabled on the Power BI vNet. A connection to the Power BI vNet is created on KeyVault, allowing traffic to flow between the Power BI vNet and KeyVault.|

6. The on-premise data gateway is installed on the VMs serving as the gateway. Only outbound ports TCP 443, 5671, 5672 and 9350-9354 are required for the VMs. The gateway does not require inbound ports. More info [here](https://docs.microsoft.com/en-us/data-integration/gateway/service-gateway-communication). 

# Deployment pre-requisites
When you are ready to deploy the infrastructure to a client's Azure environment, the first step is to request that the client provision the follow pre-requisites in order for you to perform the deployment successfully. 
|No|Prerequisite|Reason|
|---|---|---|

WORK IN PROGRESS

# Deployment Service Connection
Create a service connection that will be used to deploy resources into the client's Azure environment. 
1. Go to dev.azure.com
2. Select your Project
3. Select Project Settings
4. Select Service connections
5. Select "New service connection"
6. Select "Azure Resource Manager" as the connection type
7. Select "Service principal (manual)" 
8. Populate all the fields. Note: use the Service Principal supplied by the client as part of the pre-requisites. Ensure also that the Service Principal does have all required permissions as listed in the pre-requisites. 
9. Verify and save


# Deployment Variable Group
The deployment pipeline references a DevOps Variable Group for configuration parameters. Please create a variable group in the client's DevOps Project. 
1. Go to dev.azure.com
2. Select your Project
3. Select Pipelines
4. Select Library
5. Select "+ Variable group" 
6. Give the variable group name the following name: "powerbi-infrastructure-vg"
7. Populate the variable group variables based on the table below
8. Save

### Variables
|Name|Value|
|---|---|
|AAD_ADMINISTRATOR_OBJECT_ID|The object id of the Azure AD user or group that will be added to the Key Vault access policy.|
|ARM_CONNECTION|The name of the newly created [service connection](#deployment-service-connection).|
|AUTOMATION_DEPLOY_RUNAS|'true' or 'false' flag to indicate deployment of the Automation RunAs account.|
|COMPANY_CODE|The company code used when forming the resource names.|
|COMPANY_NAME|The company name used for resource tags if required.|
|DELIMITER|The delimiter used when forming the resource names.|
|DEPARTMENT_CODE|The department code used when forming the resource names.|
|DEVOPS_APPLICATION_ID|The application id of the DevOps application that was provisioned by the client as part of the pre-requisites.|
|DEVOPS_SERVICE_PRINCIPAL_OBJECT_ID|The object id of the DevOps service principal that was provisioned by the client as part of the pre-requisites.|
|ENVIRONMENT_CODE|The environment code used when forming the resource names.|
|ENVIRONMENT_LONG_NAME|The environment name used for resource tags if required.|
|KEYVAULT_DEPLOY|'true' or 'false' flag to indicate deployment of a KeyVault instance.|
|KEYVAULT_EXISTING_NAME|The name of the existing KeyVault instance if `KEYVAULT_DEPLOY` is set to `false`.|
|LOCATION|The data centre region where the resources are deployed. **Important** The region must support linked log analytics workspaces. Refer to the link [here](https://docs.microsoft.com/en-us/azure/automation/how-to/region-mappings) for a list of supported regions.|
|NETWORK_DEPLOY|'true' or 'false' flag to indicate deployment of a the Power BI vNet and subnet.|
|NETWORK_SUBNET_CIDR|The CIDR for the Power BI subnet. If `NETWORK_DEPLOY` is set to `true`, then the subnet CIDR is used for the subnet deployment and also referenced when adding VMs to the subnet. If `NETWORK_DEPLOY` is set to `false`, then the existing subnet CIDR is referenced when adding VMs to the subnet.|
|NETWORK_SUBNET_NAME|The subnet name for the Power BI subnet. If `NETWORK_DEPLOY` is set to `true`, then the subnet name is used for the subnet deployment and also referenced when adding VMs to the subnet. If `NETWORK_DEPLOY` is set to `false`, then the existing subnet name is referenced when adding VMs to the subnet.|
|NETWORK_VNET_CIDR|The CIDR for the Power BI vNet. If `NETWORK_DEPLOY` is set to `true`, then the vNet CIDR is used for the vNet deployment and also referenced when adding VMs to the vNet. If `NETWORK_DEPLOY` is set to `false`, then the existing vNet CIDR is referenced when adding VMs to the vNet.|
|NETWORK_VNET_NAME|The vNet name for the Power BI vNet. If `NETWORK_DEPLOY` is set to `true`, then the vNet name is used for the vNet deployment and also referenced when adding VMs to the vNet. If `NETWORK_DEPLOY` is set to `false`, then the existing vNet name is referenced when adding VMs to the vNet.|
|PBI_ADMIN_PASSWORD|The password of the Power BI Administrator Service Account.|
|PBI_ADMIN_USERNAME|The username (principalName/email address) of the Power BI Administrator Service Account.|
|RESOURCE_GROUP_NETWORK|The resource group to deploy and/or reference networking azure resources.|
|RESOURCE_GROUP_POWERBI|The resource group to deploy and/or reference Power BI related azure resources.|
|SQL_ADMINISTRATOR_PASSWORD|The password of the SQL adminstrator account that will be created.|
|SQL_ADMINISTRATOR_USERNAME|The username of the SQL adminstrator account that will be created.|
|SQL_AZURE_AD_ADMIN_ID|The object id of the Azure AD user or group that will be added to as the Azure SQL Server Administrator.|
|SQL_AZURE_AD_ADMIN_NAME|The principal name of the Azure AD user or group that will be added to as the Azure SQL Server Administrator.|
|SQL_DATABASE_NAME|The Azure SQL Database name that will be created to house the Power BI Logs. The name is stored in KeyVault and is not hard-coded anywhere. Thus you are free to choose whatever you wish, however we recommend using "PowerBILogs". |
|SUBSCRIPTION_ID|The Azure subscription id.|
|TENANT_ID|The Azure tenant id.|
|VM_HYBRIDWORKER_ADMIN_PASSWORD|The password of the Virtual Machine (Hybrid Worker) administrator account that will be created.|
|VM_HYBRIDWORKER_ADMIN_USERNAME|The username of the Virtual Machine (Hybrid Worker) administrator account that will be created.|
|VM_HYBRIDWORKER_APPLY_HUB|'true' or 'false' flag to indicate use of Hybrid Usage Benefit (HUB) pricing for the Virtual Machine (Hybrid Worker).|
|VM_HYBRIDWORKER_DEPLOY_DSC|'true' or 'false' flag to indicate deployment of Desired State Configuration (DSC) for the Virtual Machine (Hybrid Worker).|
|VM_HYBRIDWORKER_NAME|The name of the Virtual Machine (Hybrid Worker) that will be deployed.|
|VM_HYBRIDWORKER_SERVICE_PRINCIPAL_OBJECT_ID_FAILOVER|The object id of the Virtual Machine (Hybrid Worker) Managed Service Identity that is created upon the first deployment. This field is created if the DevOps Service Principal does not have permissions to read from Azure AD.|
|VM_PBIGATEWAY_ADMIN_PASSWORD|The password of the Virtual Machine (Power BI Gateway) administrator account that will be created.|
|VM_PBIGATEWAY_ADMIN_USERNAME|The username of the Virtual Machine (Power BI Gateway) administrator account that will be created.|
|VM_PBIGATEWAY_APPLY_HUB|'true' or 'false' flag to indicate use of Hybrid Usage Benefit (HUB) pricing for the Virtual Machine (Power BI Gateway).|
|VM_PBIGATEWAY_DEPLOY_DSC|'true' or 'false' flag to indicate deployment of Desired State Configuration (DSC) for the Virtual Machine (Power BI Gateway).|
|VM_PBIGATEWAY_NAME_1|The name of the Virtual Machine (Power BI Gateway) that will be deployed.|
|VM_PBIGATEWAY_NAME_2|The name of the Virtual Machine (Power BI Gateway) that will be deployed.|
|VM_AVAILABILITYSET_NAME|The name of an availability set under which the Power BI Gateway Virtual Machines are logically grouped.|

### Notes
- Refer to [On-Premise Gateway resource recommendation](https://docs.microsoft.com/en-us/data-integration/gateway/service-gateway-install#requirements) on what tiers to configure the VMs on. 
- The variable group is configured to only deploy 1 Virtual Machine for On-premise Gateway. It is recommended that you deploy at least 2 VMs (cluster) to allow for high-availability. More [here](https://docs.microsoft.com/en-us/data-integration/gateway/service-gateway-install#add-another-gateway-to-create-a-cluster) and [here](https://docs.microsoft.com/en-us/data-integration/gateway/service-gateway-high-availability-clusters). 

### Naming convention
Resources deployed will adhere to the following naming convention: 

(COMPANY_CODE)(DELIMITER)(ENVIRONMENT_CODE)(DELIMITER)(DEPARTMENT_CODE)(DELIMITER)(RESOURCE_CODE)(DELIMITER)(SUFFIX)


# Deployment YAML Pipeline

# Post deployment configuration
