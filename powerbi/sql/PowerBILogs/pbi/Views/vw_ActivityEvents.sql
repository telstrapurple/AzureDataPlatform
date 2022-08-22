CREATE VIEW pbi.vw_ActvityEvents AS 

SELECT 
	act.[Id]                    
    ,act.[RecordType]            
	,act.[CreationTime]			
	,act.[Operation]				
	,act.[OrganizationId]		
	,act.[UserType]				
	,act.[UserKey]				
	,act.[Workload]				
	,act.[UserId]				
	,act.[ClientIP]				
	,act.[UserAgent]				
	,act.[Activity]				
	,act.[IsSuccess]				
	,act.[RequestId]				
	,act.[ActivityId]			
	,act.[ItemName]				
	,act.[ItemType]				
	,act.[ObjectId]				
	,act.[WorkspaceName]			
	,act.[WorkspaceId]			
	,act.[ImportId]				
	,act.[ImportSource]			
	,act.[ImportType]			
	,act.[ImportDisplayName]		
	,act.[DatasetName]			
	,act.[DatasetId]	
	,dssrc.[DatasourceId]   AS DatasetDatasourceId
	,dssrc.[Name]			AS DatasetDatasourceName
	,dssrc.[ConnectionString] AS DatasetDatasourceConnectionString
	,dssrc.[DatasourceType] AS DatasetDatasourceType
	,dssrc.[GatewayId]		AS DatasetDatasourceGatewayId
	,dssrc.[Server]			AS DatasetDatasourceServer
	,dssrc.[Database]		AS DatasetDatasourceDatabase
	,dssrc.[Url]			AS DatasetDatasourceUrl
	,act.[DataConnectivityMode]	
	,act.[OrgAppPermission]		
	,act.[DashboardId]			
	,act.[DashboardName]			
	,act.[DataflowId]			
	,act.[DataflowName]			
	,act.[DataflowAccessTokenRequestParameters]			
	,act.[DataflowType]		
	,dfsrc.[DatasourceId]   AS DataflowDatasourceId
	,dfsrc.[Name]			AS DataflowDatasourceName
	,dfsrc.[ConnectionString] AS DataflowDatasourceConnectionString
	,dfsrc.[DatasourceType] AS DataflowDatasourceType
	,dfsrc.[GatewayId]		AS DataflowDatasourceGatewayId
	,dfsrc.[Server]			AS DataflowDatasourceServer
	,dfsrc.[Database]		AS DataflowDatasourceDatabase
	,dfsrc.[Url]			AS DataflowDatasourceUrl
	,act.[GatewayId]				
	,act.[GatewayName]			
	,act.[GatewayType]			
	,act.[ReportName]			
	,act.[ReportId]				
	,act.[ReportType]			
	,act.[FolderObjectId]		
	,act.[FolderDisplayName]		
	,act.[ArtifactName]			
	,act.[ArtifactId]			
	,act.[CapacityName]			
	,act.[CapacityUsers]			
	,act.[CapacityState]			
	,act.[DistributionMethod]	
	,act.[ConsumptionMethod]		
	,act.[RefreshType]			
	,act.[ExportEventStartDateTimeParameter]	 
	,act.[ExportEventEndDateTimeParameter]	
FROM 
	pbi.ActivityEvents act LEFT OUTER JOIN pbi.DatasetsDatasources dssrc 
	ON act.DatasetId = dssrc.DatasetId LEFT OUTER JOIN pbi.DataflowsDatasources dfsrc
	ON act.DataflowId = dfsrc.DataflowId