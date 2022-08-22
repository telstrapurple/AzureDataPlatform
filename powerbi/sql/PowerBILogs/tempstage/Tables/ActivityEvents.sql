﻿CREATE TABLE [tempstage].[ActivityEvents] (
    [Id]                    NVARCHAR (MAX) NULL,
    [RecordType]            INT   NULL,
	[CreationTime]			NVARCHAR(MAX)   NULL,
	[Operation]				NVARCHAR (MAX)   NULL,
	[OrganizationId]		NVARCHAR (MAX) NULL,
	[UserType]				INT NULL,
	[UserKey]				NVARCHAR (MAX) NULL,
	[Workload]				NVARCHAR (MAX) NULL,
	[UserId]				NVARCHAR (MAX) NULL,
	[ClientIP]				NVARCHAR (MAX) NULL,
	[UserAgent]				NVARCHAR (MAX) NULL,
	[Activity]				NVARCHAR (MAX) NULL,
	[IsSuccess]				NVARCHAR (MAX) NULL,
	[RequestId]				NVARCHAR (MAX) NULL,
	[ActivityId]			NVARCHAR (MAX) NULL,
	[ItemName]				NVARCHAR (MAX) NULL, 
	[ItemType]				NVARCHAR (MAX) NULL, 
	[ObjectId]				NVARCHAR (MAX) NULL, 
	[WorkspaceName]			NVARCHAR(MAX) NULL,
	[WorkspaceId]			NVARCHAR(MAX) NULL,
	[ImportId]				NVARCHAR(MAX) NULL,
	[ImportSource]			NVARCHAR(MAX) NULL,
	[ImportType]			NVARCHAR(MAX) NULL,
	[ImportDisplayName]		NVARCHAR(MAX) NULL,
	[DatasetName]			NVARCHAR(MAX) NULL,
	[DatasetId]				NVARCHAR(MAX) NULL,
	[DataConnectivityMode]	NVARCHAR(MAX) NULL,
	[OrgAppPermission]		NVARCHAR(MAX) NULL,
	[DashboardId]			NVARCHAR(MAX) NULL,
	[DashboardName]			NVARCHAR(MAX) NULL,
	[DataflowId]			NVARCHAR(MAX) NULL,
	[DataflowName]			NVARCHAR(MAX) NULL,
	[DataflowAccessTokenRequestParameters]			NVARCHAR(MAX) NULL,
	[DataflowType]			NVARCHAR(MAX) NULL,
	[GatewayId]				NVARCHAR(MAX) NULL,
	[GatewayName]			NVARCHAR(MAX) NULL,
	[GatewayType]			NVARCHAR(MAX) NULL,
	[ReportName]			NVARCHAR(MAX) NULL,
	[ReportId]				NVARCHAR(MAX) NULL,
	[ReportType]			NVARCHAR(MAX) NULL,
	[FolderObjectId]		NVARCHAR(MAX) NULL ,
	[FolderDisplayName]		NVARCHAR(MAX) NULL ,
	[ArtifactName]			NVARCHAR(MAX) NULL,
	[ArtifactId]			NVARCHAR(MAX) NULL,
	[CapacityName]			NVARCHAR(MAX) NULL ,
	[CapacityUsers]			NVARCHAR(MAX) NULL, 
	[CapacityState]			NVARCHAR(MAX) NULL,
	[DistributionMethod]	NVARCHAR(MAX) NULL,
	[ConsumptionMethod]		NVARCHAR(MAX) NULL,
	[RefreshType]			NVARCHAR(MAX) NULL,
	[ExportEventStartDateTimeParameter]	 NVARCHAR(50) NULL,
	[ExportEventEndDateTimeParameter]	 NVARCHAR(50) NULL
) 