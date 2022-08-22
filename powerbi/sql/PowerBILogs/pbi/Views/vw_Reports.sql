CREATE VIEW pbi.vw_Reports AS

SELECT 
	rpt.[Id]       
	,wrpt.WorkspaceId
    ,rpt.[Name]     
	,rpt.[WebUrl]	
	,rpt.[EmbedUrl]	
	,rpt.[DatasetId]
FROM 
	[pbi].[Reports] rpt INNER JOIN [pbi].[WorkspacesReports] wrpt
	ON rpt.Id = wrpt.Id