CREATE TABLE [pbi].[DashboardsTiles] (
    [DashboardId]          VARCHAR(50) NULL,
    [Id]					VARCHAR(50) NOT NULL,
	[Title]					NVARCHAR(MAX)   NULL,
	[RowSpan]				INT   NULL,
	[ColumnSpan]				INT   NULL,
	[EmbedUrl]				VARCHAR(MAX)   NULL,
	[EmbedData]				NVARCHAR(MAX)   NULL,
	[ReportId]				VARCHAR(50)   NULL,
	[DatasetId]				VARCHAR(50)   NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo),
	CONSTRAINT [PK_PBI_DashboardsTiles] PRIMARY KEY CLUSTERED ([Id] ASC),
	CONSTRAINT [FK_PBI_DashboardsTiles_Dashboards] FOREIGN KEY ([DashboardId]) REFERENCES [pbi].[Dashboards] ([Id]),
	CONSTRAINT [FK_PBI_DashboardsTiles_Reports] FOREIGN KEY ([ReportId]) REFERENCES [pbi].[Reports] ([Id]),
	CONSTRAINT [FK_PBI_DashboardsTiles_Datasets] FOREIGN KEY ([DatasetId]) REFERENCES [pbi].[Datasets] ([Id])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.DashboardsTiles_History));