CREATE VIEW pbi.vw_Dataflows AS

SELECT 
	dfl.[Id]     
	,wdfl.WorkspaceId
    ,dfl.[Name]        
	,dfl.[Description]
	,dfl.[ModelUrl]		
	,dfl.[ConfiguredBy]
FROM 
	[pbi].[Dataflows] dfl INNER JOIN [pbi].[WorkspacesDashboards] wdfl
	ON dfl.Id = wdfl.Id