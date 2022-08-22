CREATE TABLE [tempstage].[DatasetsDatasources] (
    [DatasourceId]          VARCHAR(50) NULL,
    [DatasetId]             VARCHAR(50) NULL,
	[Name]					NVARCHAR(MAX)   NULL,
	[ConnectionString]		VARCHAR(2000)   NULL,
	[DatasourceType]		VARCHAR(500)   NULL,
	[GatewayId]				VARCHAR(50)   NULL,
	[Server]				VARCHAR(500)   NULL,
	[Database]				VARCHAR(500)   NULL,
	[Url]					VARCHAR(MAX)   NULL,
);