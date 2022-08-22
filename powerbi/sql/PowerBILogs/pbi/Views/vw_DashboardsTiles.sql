CREATE VIEW pbi.vw_DashboardsTiles AS

SELECT 
	[DashboardId]
    ,[Id]		
	,[Title]		
	,[RowSpan]	
	,[ColumnSpan]
	,[EmbedUrl]	
	,[EmbedData]	
	,[ReportId]	
	,[DatasetId]	
FROM 
	[pbi].[DashboardsTiles] 