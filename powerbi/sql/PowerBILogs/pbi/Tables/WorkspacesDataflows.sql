CREATE TABLE [pbi].[WorkspacesDataflows]
(
	[Id] VARCHAR (50) NOT NULL,
	[WorkspaceId] VARCHAR (50) NOT NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo),
	CONSTRAINT [PK_PBI_WorkspacesDataflows] PRIMARY KEY CLUSTERED ([Id] ASC, [WorkspaceId] ASC),
	CONSTRAINT [FK_PBI_WorkspacesDataflows_Dataflows] FOREIGN KEY ([Id]) REFERENCES [pbi].[Dataflows] ([Id]),
	CONSTRAINT [FK_PBI_WorkspacesDataflows_Workspaces] FOREIGN KEY ([WorkspaceId]) REFERENCES [pbi].[Workspaces] ([Id])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.WorkspacesDataflows_History));