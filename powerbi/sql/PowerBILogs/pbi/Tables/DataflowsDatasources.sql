CREATE TABLE [pbi].[DataflowsDatasources] (
    [DatasourceId]          VARCHAR (50) NOT NULL,
    [DataflowId]             VARCHAR (50) NOT NULL,
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
	CONSTRAINT [PK_PBI_DataflowsDatasources] PRIMARY KEY CLUSTERED ([DatasourceId], [DataflowId] ASC),
	CONSTRAINT [FK_PBI_DataflowsDatasources_Dataflows] FOREIGN KEY ([DataflowId]) REFERENCES [pbi].[Dataflows] ([Id])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.DataflowsDatasources_History));