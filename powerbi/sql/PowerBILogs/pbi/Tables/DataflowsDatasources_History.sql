CREATE TABLE [pbi].[DataflowsDatasources_History] (
    [DatasourceId]     VARCHAR (50)   NOT NULL,
    [DataflowId]       VARCHAR (50)   NOT NULL,
    [Name]             NVARCHAR (MAX) NULL,
    [ConnectionString] VARCHAR (2000) NULL,
    [DatasourceType]   VARCHAR (500)  NULL,
    [GatewayId]        VARCHAR (50)   NULL,
    [Server]           VARCHAR (500)  NULL,
    [Database]         VARCHAR (500)  NULL,
    [Url]              VARCHAR (MAX)  NULL,
    [ValidFrom]        DATETIME2 (7)  NOT NULL,
    [ValidTo]          DATETIME2 (7)  NOT NULL
);

