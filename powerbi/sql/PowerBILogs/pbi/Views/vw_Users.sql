CREATE VIEW pbi.vw_Users AS 

SELECT 
	[Identifier]		
	,[WorkspaceId]		
	,[AccessRight]		
	,[UserPrincipalName] 
	,[PrincipalType]		
FROM 
	pbi.WorkspacesUsers