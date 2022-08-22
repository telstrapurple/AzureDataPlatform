CREATE TABLE [pbi].[DashboardsTiles_History] (
    [DashboardId] VARCHAR (50)   NULL,
    [Id]          VARCHAR (50)   NOT NULL,
    [Title]       NVARCHAR (MAX) NULL,
    [RowSpan]     INT            NULL,
    [ColumnSpan]  INT            NULL,
    [EmbedUrl]    VARCHAR (MAX)  NULL,
    [EmbedData]   NVARCHAR (MAX) NULL,
    [ReportId]    VARCHAR (50)   NULL,
    [DatasetId]   VARCHAR (50)   NULL,
    [ValidFrom]   DATETIME2 (7)  NOT NULL,
    [ValidTo]     DATETIME2 (7)  NOT NULL
);

