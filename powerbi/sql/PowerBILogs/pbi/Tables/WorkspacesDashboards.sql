﻿CREATE TABLE [pbi].[WorkspacesDashboards]
(
	[Id] VARCHAR (50) NOT NULL,
	[WorkspaceId] VARCHAR (50) NOT NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo),
	CONSTRAINT [PK_PBI_WorkspacesDashboards] PRIMARY KEY CLUSTERED ([Id] ASC, [WorkspaceId] ASC),
	CONSTRAINT [FK_PBI_WorkspacesDashboards_Dashboards] FOREIGN KEY ([Id]) REFERENCES [pbi].[Dashboards] ([Id]),
	CONSTRAINT [FK_PBI_WorkspacesDashboards_Workspaces] FOREIGN KEY ([WorkspaceId]) REFERENCES [pbi].[Workspaces] ([Id])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.WorkspacesDashboards_History));