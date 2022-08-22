CREATE TABLE [tempstage].[Workspaces] (
    [Id]                    VARCHAR (50) NULL,
    [Name]                  NVARCHAR (MAX)   NULL,
    [IsReadOnly]            VARCHAR (50)     NULL,
    [IsOnDedicatedCapacity] VARCHAR (50)     NULL,
    [CapacityId]            VARCHAR (500)    NULL,
    [Description]           NVARCHAR (MAX)   NULL,
    [Type]                  VARCHAR (255)    NULL,
    [State]                 VARCHAR (255)    NULL,
    [IsOrphaned]            VARCHAR (50)     NULL
);

