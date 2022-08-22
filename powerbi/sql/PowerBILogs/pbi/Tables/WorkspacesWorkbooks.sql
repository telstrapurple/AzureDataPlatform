CREATE TABLE [pbi].[WorkspacesWorkbooks]
(
	[Name] NVARCHAR (4000) NOT NULL,
	[WorkspaceId] VARCHAR (50) NOT NULL,
	[DatasetId] VARCHAR (50) NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo),
	CONSTRAINT [PK_PBI_WorkspacesWorkbooks] PRIMARY KEY CLUSTERED ([Name] ASC, [WorkspaceId] ASC),
	CONSTRAINT [FK_PBI_WorkspacesWorkbooks_Workspaces] FOREIGN KEY ([WorkspaceId]) REFERENCES [pbi].[Workspaces] ([Id])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.WorkspacesWorkbooks_History));