CREATE TABLE [pbi].[DatasetsDatasources] (
    [DatasourceId]          VARCHAR (50) NOT NULL,
    [DatasetId]             VARCHAR (50) NOT NULL,
	[Name]					NVARCHAR(MAX)   NULL,
	[ConnectionString]		VARCHAR(2000)   NULL,
	[DatasourceType]		VARCHAR(500)   NULL,
	[GatewayId]				VARCHAR (50)   NULL,
	[Server]				VARCHAR(500)   NULL,
	[Database]				VARCHAR(500)   NULL,
	[Url]					VARCHAR(MAX)   NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo),
	CONSTRAINT [PK_PBI_DatasetsDatasources] PRIMARY KEY CLUSTERED ([DatasourceId], [DatasetId] ASC),
	CONSTRAINT [FK_PBI_DatasetsDatasources_Datasets] FOREIGN KEY ([DatasetId]) REFERENCES [pbi].[Datasets] ([Id])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.DatasetsDatasources_History));