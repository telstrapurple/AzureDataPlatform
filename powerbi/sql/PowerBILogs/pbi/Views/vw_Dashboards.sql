CREATE VIEW pbi.vw_Dashboards AS

SELECT 
	dbs.[Id]                    
    ,wdbs.WorkspaceId
	,dbs.[Name]                  
	,dbs.[IsReadOnly]			
	,dbs.[EmbedUrl]
FROM 
	[pbi].[Dashboards] dbs INNER JOIN [pbi].[WorkspacesDashboards] wdbs
	ON dbs.Id = wdbs.Id