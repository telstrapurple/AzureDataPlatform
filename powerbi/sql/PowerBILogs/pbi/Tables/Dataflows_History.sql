CREATE TABLE [pbi].[Dataflows_History] (
    [Id]           VARCHAR (50)   NOT NULL,
    [Name]         NVARCHAR (MAX) NULL,
    [Description]  NVARCHAR (MAX) NULL,
    [ModelUrl]     VARCHAR (MAX)  NULL,
    [ConfiguredBy] VARCHAR (500)  NULL,
    [ValidFrom]    DATETIME2 (7)  NOT NULL,
    [ValidTo]      DATETIME2 (7)  NOT NULL
);

