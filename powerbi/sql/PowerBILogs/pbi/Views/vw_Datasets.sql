CREATE VIEW pbi.vw_Datasets AS

SELECT 
	dst.[Id]                    
	,wdst.WorkspaceId
    ,dst.[Name]                  
	,dst.[ConfiguredBy]          
	,dst.[DefaultRetentionPolicy]
	,dst.[AddRowsApiEnabled]		
	,dst.[Tables]				
	,dst.[WebUrl]				
	,dst.[Relationships]				
	,dst.[Datasources]				
	,dst.[DefaultMode]				
	,dst.[IsRefreshable]				
	,dst.[IsEffectiveIdentityRequired]	
	,dst.[IsEffectiveIdentityRolesRequired]	
	,dst.[IsOnPremGatewayRequired]	
	,dst.[TargetStorageMode]
	,dst.[ActualStorage]	
	,dst.[CreatedDate]
	,dst.[ContentProviderType]
FROM 
	[pbi].[Datasets] dst INNER JOIN [pbi].[WorkspacesDatasets] wdst
	ON dst.Id = wdst.Id