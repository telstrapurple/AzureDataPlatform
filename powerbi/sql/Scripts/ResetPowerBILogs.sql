/*
Drops all tables from PowerBILogs
*/

-- Drop all tempstage tables
DROP TABLE [tempstage].[WorkspacesWorkbooks]
DROP TABLE [tempstage].[WorkspacesUsers]
DROP TABLE [tempstage].[WorkspacesReports]
DROP TABLE [tempstage].[WorkspacesDatasets]
DROP TABLE [tempstage].[WorkspacesDataflows]
DROP TABLE [tempstage].[WorkspacesDashboards]
DROP TABLE [tempstage].[Workspaces]
DROP TABLE [tempstage].[Reports]
DROP TABLE [tempstage].[DatasetsDatasources]
DROP TABLE [tempstage].[Datasets]
DROP TABLE [tempstage].[DataflowsDatasources]
DROP TABLE [tempstage].[Dataflows]
DROP TABLE [tempstage].[DashboardsTiles]
DROP TABLE [tempstage].[Dashboards]

-- Drop all pbi tables
ALTER TABLE [pbi].[WorkspacesWorkbooks] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[WorkspacesWorkbooks]
DROP TABLE [pbi].[WorkspacesWorkbooks_History]

ALTER TABLE [pbi].[WorkspacesUsers] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[WorkspacesUsers] 
DROP TABLE [pbi].[WorkspacesUsers_History]

ALTER TABLE [pbi].[WorkspacesReports] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[WorkspacesReports] 
DROP TABLE [pbi].[WorkspacesReports_History]

ALTER TABLE [pbi].[WorkspacesDatasets] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[WorkspacesDatasets]
DROP TABLE [pbi].[WorkspacesDatasets_History]

ALTER TABLE [pbi].[WorkspacesDataflows] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[WorkspacesDataflows]
DROP TABLE [pbi].[WorkspacesDataflows_History]

ALTER TABLE [pbi].[WorkspacesDashboards] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[WorkspacesDashboards]
DROP TABLE [pbi].[WorkspacesDashboards_History]

ALTER TABLE [pbi].[DashboardsTiles] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[DashboardsTiles]
DROP TABLE [pbi].[DashboardsTiles_History]

ALTER TABLE [pbi].[Workspaces] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[Workspaces] 
DROP TABLE [pbi].[Workspaces_History] 

ALTER TABLE [pbi].[Reports] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[Reports] 
DROP TABLE [pbi].[Reports_History] 

ALTER TABLE [pbi].[DatasetsDatasources] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[DatasetsDatasources] 
DROP TABLE [pbi].[DatasetsDatasources_History]

ALTER TABLE [pbi].[Datasets] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[Datasets] 
DROP TABLE [pbi].[Datasets_History] 

ALTER TABLE [pbi].[DataflowsDatasources] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[DataflowsDatasources] 
DROP TABLE [pbi].[DataflowsDatasources_History]

ALTER TABLE [pbi].[Dataflows] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[Dataflows]
DROP TABLE [pbi].[Dataflows_History]

ALTER TABLE [pbi].[Dashboards] SET (SYSTEM_VERSIONING = OFF)
DROP TABLE [pbi].[Dashboards] 
DROP TABLE [pbi].[Dashboards_History] 