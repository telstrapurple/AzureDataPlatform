CREATE TABLE [pbi].[Workspaces] (
    [Id]                    VARCHAR (50) NOT NULL,
    [Name]                  NVARCHAR (MAX)   NULL,
    [IsReadOnly]            VARCHAR (50)     NULL,
    [IsOnDedicatedCapacity] VARCHAR (50)     NULL,
    [CapacityId]            VARCHAR (500)    NULL,
    [Description]           NVARCHAR (MAX)   NULL,
    [Type]                  VARCHAR (255)    NULL,
    [State]                 VARCHAR (255)    NULL,
    [IsOrphaned]            VARCHAR (50)     NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo),
    CONSTRAINT [PK_PBI_Workspaces] PRIMARY KEY CLUSTERED ([Id] ASC)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.Workspaces_History));