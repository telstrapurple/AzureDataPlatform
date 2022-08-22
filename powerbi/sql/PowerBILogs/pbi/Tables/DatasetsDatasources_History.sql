CREATE TABLE [pbi].[DatasetsDatasources_History] (
    [DatasourceId]     VARCHAR (50)   NOT NULL,
    [DatasetId]        VARCHAR (50)   NOT NULL,
    [Name]             VARCHAR (MAX)  NULL,
    [ConnectionString] VARCHAR (MAX)  NULL,
    [DatasourceType]   VARCHAR (500)  NULL,
    [GatewayId]        VARCHAR (50)   NULL,
    [Server]           VARCHAR (500)  NULL,
    [Database]         VARCHAR (500)  NULL,
    [Url]              VARCHAR (4000) NOT NULL,
    [ValidFrom]        DATETIME2 (7)  NOT NULL,
    [ValidTo]          DATETIME2 (7)  NOT NULL
);

