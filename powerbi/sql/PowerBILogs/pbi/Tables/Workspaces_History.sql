CREATE TABLE [pbi].[Workspaces_History] (
    [Id]                    VARCHAR (50)   NOT NULL,
    [Name]                  NVARCHAR (MAX) NULL,
    [IsReadOnly]            VARCHAR (50)   NULL,
    [IsOnDedicatedCapacity] VARCHAR (50)   NULL,
    [CapacityId]            VARCHAR (500)  NULL,
    [Description]           NVARCHAR (MAX) NULL,
    [Type]                  VARCHAR (255)  NULL,
    [State]                 VARCHAR (255)  NULL,
    [IsOrphaned]            VARCHAR (50)   NULL,
    [ValidFrom]             DATETIME2 (7)  NOT NULL,
    [ValidTo]               DATETIME2 (7)  NOT NULL
);

