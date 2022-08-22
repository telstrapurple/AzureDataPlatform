CREATE VIEW pbi.vw_DatasetsDatasources AS 

SELECT 
	[DatasourceId]     
    ,[DatasetId]
	,[Name]			
	,[ConnectionString]
	,[DatasourceType]
	,[GatewayId]		
	,[Server]		
	,[Database]		
	,[Url]
FROM 
	pbi.DatasetsDatasources