# ADP Configurator Web API

## Purpose

At various customers, a change management process exists for our data pipelines. To manage this process engineers generally complete their work in the development environment. Once they are confident that their changes are well tested and effective, they promote this work to the production environment.

To facilitate this promotion process, the development environment exposes an API through which production can fetch systems and tasks to pull into its environment.

## How?

From a task or system view in production, the user will choose to pull from dev. They will need to set values that must differ between dev and production, such as AAD groups. Using entity names to correlate values, prod will call dev apis to see if such a task or system or already exists, fetch it, and update its own values to match.

## What doesn't get migrated?

Schedules - dev schedules are likely to differ drastically from production schedules.

AAD groups - these are driven by the system code of a system, and can't be changed once set.

## Correlating values

We cannot depend on anything in the development environment to have the same primary key as its equivalent in the production environment. So we must instead depend on the names of things - the names of properties, property types, systems, tasks - everything.

If something has the same name in production as in dev, it will be assumed that they are the same entity and will be pulled across.

## Deployment

This system requires a double deployment, because the dev and production environment must be made mutually aware of each other. The production environment must acquire a secret key to use in server-to-server communications with dev, and dev must be aware of the proudction environment in order to trust production as an api client.

The first deployment will create the dev api, and provide production with a client secret to call the api. The second deployment will require a configuration variable to be set in the Azure Devops pipeline providing details about the production client, which the development will then add to its trusted list of clients.
