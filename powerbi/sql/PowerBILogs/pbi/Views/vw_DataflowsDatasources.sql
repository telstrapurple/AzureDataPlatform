CREATE VIEW pbi.vw_DataflowsDatasources AS
SELECT 
	[DatasourceId]     
    ,[DataflowId]
	,[Name]			
	,[ConnectionString]
	,[DatasourceType]
	,[GatewayId]		
	,[Server]		
	,[Database]		
	,[Url]
FROM 
	pbi.DataflowsDatasources