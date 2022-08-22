CREATE TABLE [tempstage].[DashboardsTiles] (
    [DashboardId]          VARCHAR(50) NULL,
    [Id]            VARCHAR(50) NULL,
	[Title]					NVARCHAR(MAX)   NULL,
	[RowSpan]				INT   NULL,
	[ColumnSpan]				INT   NULL,
	[EmbedUrl]				VARCHAR(MAX)   NULL,
	[EmbedData]				NVARCHAR(MAX)   NULL,
	[ReportId]				VARCHAR(50)   NULL,
	[DatasetId]				VARCHAR(50)   NULL
);