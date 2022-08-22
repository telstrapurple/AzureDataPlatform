CREATE TABLE [pbi].[Reports_History] (
    [Id]        VARCHAR (50)   NOT NULL,
    [Name]      NVARCHAR (MAX) NULL,
    [WebUrl]    NVARCHAR (MAX) NULL,
    [EmbedUrl]  NVARCHAR (MAX) NULL,
    [DatasetId] VARCHAR (50)   NULL,
    [ValidFrom] DATETIME2 (7)  NOT NULL,
    [ValidTo]   DATETIME2 (7)  NOT NULL
);

