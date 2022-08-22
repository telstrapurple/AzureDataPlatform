CREATE TABLE [pbi].[Dashboards_History] (
    [Id]         VARCHAR (50)   NOT NULL,
    [Name]       NVARCHAR (MAX) NULL,
    [IsReadOnly] VARCHAR (30)   NULL,
    [EmbedUrl]   VARCHAR (MAX)  NULL,
    [ValidFrom]  DATETIME2 (7)  NOT NULL,
    [ValidTo]    DATETIME2 (7)  NOT NULL
);

