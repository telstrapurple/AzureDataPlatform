CREATE TABLE [pbi].[WorkspacesUsers]
(
	[Identifier] VARCHAR (50) NOT NULL,
	[WorkspaceId] VARCHAR (50) NOT NULL,
	[AccessRight] VARCHAR (50) NULL,
	[UserPrincipalName] VARCHAR (500) NULL,
	[PrincipalType] VARCHAR (50) NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo),
	CONSTRAINT [PK_PBI_WorkspacesUsers] PRIMARY KEY CLUSTERED ([Identifier] ASC, [WorkspaceId] ASC),
	CONSTRAINT [FK_PBI_WorkspacesUsers_Workspaces] FOREIGN KEY ([WorkspaceId]) REFERENCES [pbi].[Workspaces] ([Id])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.WorkspacesUsers_History));
