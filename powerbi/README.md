# Agile Enterprise BI

## Overview

This repository folder contains all IP required to deliver the Agile Enterprise BI offering.

## Quick Help

> I wish to learn and understand what is Agile Enterprise BI.

- Refer to the [agile-enterprise-bi-framework.pptx](docs/agile-enterprise-bi-framework.pptx) slide pack which explains how the Framework works.
- Have a go at following the steps in the [Demo Guide](docs/DemoGuide.md) to implement Agile Enterprise BI in your own environment. Doing so will help you understand the framework in depth.

> I wish to implement Agile Enterprise BI for a Client.

- Refer to the [Delivery Guide](docs/DeliveryGuide.md) which lists the steps to implement this offering at a client.

> I wish to setup a demo of Agile Enterprise BI for Telstra Purple training or for a client demo.

- Refer to the steps in the [Demo Guide](docs/DemoGuide.md) to implement Agile Enterprise BI in your own environment.

## Repository contents

| Folder                           | Description                                                                                                                                                                                                             |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [docs](docs)                     | Contains all documentation required to deliver Agile Enterprise BI. It is recommended you read contents here first before implementing at a client (particularly the Delivery Guide and Agile Enterprise BI Framework). |
| [infrastructure](infrastructure) | Contains all code relating to infrastructure configuration and deployment for Agile Enterprise BI.                                                                                                                      |
| [pipelines](pipelines)           | Contains all code used for deployment of infrastructure and Power BI CI/CD.                                                                                                                                             |
| [powerbi](powerbi)               | Contains all Power BI assets (.pbix) such as demo and monitoring content.                                                                                                                                               |
| [powershell](powershell)         | Contains all PowerShell scripts used for Power BI and AzureAD Administration, and Automation Runbooks for Power BI monitoring and logging.                                                                              |
| [sql](sql)                       | Contains the SQL database project which is used for persistent storage of the Power BI log tables.                                                                                                                      |
| [training](training)             | Contains all training content that shall be delivered to the client during delivery. Please plan ahead and book participants time for the training.                                                                     |
| [workbooks](workbooks)           | Contains all excel workbooks used for AAD User <-> AAD Group <-> Workspace mapping exercises.                                                                                                                           |
