﻿CREATE TABLE [pbi].[ActivityEvents] (
    [Id]                    VARCHAR (50) NOT NULL,
    [RecordType]            INT   NULL,
	[CreationTime]			VARCHAR(50)   NULL,
	[Operation]				VARCHAR (200)   NULL,
	[OrganizationId]		VARCHAR (50) NULL,
	[UserType]				INT NULL,
	[UserKey]				VARCHAR (50) NULL,
	[Workload]				VARCHAR (50) NULL,
	[UserId]				VARCHAR (2000) NULL,
	[ClientIP]				VARCHAR (200) NULL,
	[UserAgent]				VARCHAR (1000) NULL,
	[Activity]				VARCHAR (500) NULL,
	[IsSuccess]				VARCHAR (25) NULL,
	[RequestId]				VARCHAR (50) NULL,
	[ActivityId]			VARCHAR (50) NULL,
	[ItemName]				NVARCHAR (500) NULL, 
	[ItemType]				NVARCHAR (100) NULL, 
	[ObjectId]				VARCHAR (500) NULL, 
	[WorkspaceName]			NVARCHAR(500) NULL,
	[WorkspaceId]			VARCHAR(50) NULL,
	[ImportId]				VARCHAR(50) NULL,
	[ImportSource]			VARCHAR(200) NULL,
	[ImportType]			VARCHAR(50) NULL,
	[ImportDisplayName]		NVARCHAR(1000) NULL,
	[DatasetName]			NVARCHAR(1000) NULL,
	[DatasetId]				VARCHAR(50) NULL,
	[DataConnectivityMode]	VARCHAR(500) NULL,
	[OrgAppPermission]		VARCHAR(500) NULL,
	[DashboardId]			VARCHAR(50) NULL,
	[DashboardName]			NVARCHAR(4000) NULL,
	[DataflowId]			VARCHAR(50) NULL,
	[DataflowName]			NVARCHAR(4000) NULL,
	[DataflowAccessTokenRequestParameters]			VARCHAR(4000) NULL,
	[DataflowType]			VARCHAR(500) NULL,
	[GatewayId]				VARCHAR(50) NULL,
	[GatewayName]			NVARCHAR(1000) NULL,
	[GatewayType]			VARCHAR(100) NULL,
	[ReportName]			NVARCHAR(1000) NULL,
	[ReportId]				VARCHAR(50) NULL,
	[ReportType]			VARCHAR(100) NULL,
	[FolderObjectId]		VARCHAR(50) NULL ,
	[FolderDisplayName]		NVARCHAR(2000) NULL ,
	[ArtifactName]			NVARCHAR(2000) NULL,
	[ArtifactId]			VARCHAR(50) NULL,
	[CapacityName]			VARCHAR(500) NULL ,
	[CapacityUsers]			NVARCHAR(MAX) NULL, 
	[CapacityState]			VARCHAR(100) NULL,
	[DistributionMethod]	VARCHAR(200) NULL,
	[ConsumptionMethod]		VARCHAR(200) NULL,
	[RefreshType]			VARCHAR(200) NULL,
	[ExportEventStartDateTimeParameter]	 VARCHAR(50) NULL,
	[ExportEventEndDateTimeParameter]	 VARCHAR(50) NULL
	CONSTRAINT [PK_PBI_ActivityEvents] PRIMARY KEY CLUSTERED ([Id] ASC)
) 
