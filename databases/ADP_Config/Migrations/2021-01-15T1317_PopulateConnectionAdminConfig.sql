--Databricks ETL cluster--

IF NOT EXISTS (	SELECT
					1
				FROM 
					DI.[ConnectionProperty] CP
					INNER JOIN DI.[Connection] C ON CP.ConnectionID = C.ConnectionID
					INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
					INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
				WHERE 
					C.ConnectionName = 'Databricks ETL Cluster'
					AND CPT.ConnectionPropertyTypeName = 'Databricks Cluster ID')
BEGIN

	INSERT [DI].[ConnectionProperty]
	(
		[ConnectionPropertyTypeID]
	   ,[ConnectionID]
	   ,[ConnectionPropertyValue]
	)
	SELECT
		CPT.ConnectionPropertyTypeID
		,C.ConnectionID
		,'$DatabricksStandardClusterID$'
	FROM 
		DI.[Connection] C
		INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
		CROSS JOIN DI.ConnectionPropertyType CPT
	WHERE 
		C.ConnectionName = 'Databricks ETL Cluster'
		AND CPT.ConnectionPropertyTypeName = 'Databricks Cluster ID'

END

--Databricks workspace URL--

IF NOT EXISTS (	SELECT
					1
				FROM 
					DI.[ConnectionProperty] CP
					INNER JOIN DI.[Connection] C ON CP.ConnectionID = C.ConnectionID
					INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
					INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
				WHERE 
					C.ConnectionName = 'Databricks ETL Cluster'
					AND CPT.ConnectionPropertyTypeName = 'Databricks URL')
BEGIN

	INSERT [DI].[ConnectionProperty]
	(
		[ConnectionPropertyTypeID]
	   ,[ConnectionID]
	   ,[ConnectionPropertyValue]
	)
	SELECT
		CPT.ConnectionPropertyTypeID
		,C.ConnectionID
		,'$DatabricksWorkspaceURL$'
	FROM 
		DI.[Connection] C
		INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
		CROSS JOIN DI.ConnectionPropertyType CPT
	WHERE 
		C.ConnectionName = 'Databricks ETL Cluster'
		AND CPT.ConnectionPropertyTypeName = 'Databricks URL'

END

--Data Lake service endpoint--

IF NOT EXISTS (	SELECT
					1
				FROM 
					DI.[ConnectionProperty] CP
					INNER JOIN DI.[Connection] C ON CP.ConnectionID = C.ConnectionID
					INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
					INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
				WHERE 
					C.ConnectionName = 'ADS Data Lake'
					AND CPT.ConnectionPropertyTypeName = 'Service Endpoint')
BEGIN

	INSERT [DI].[ConnectionProperty]
	(
		[ConnectionPropertyTypeID]
	   ,[ConnectionID]
	   ,[ConnectionPropertyValue]
	)
	SELECT
		CPT.[ConnectionPropertyTypeID]
		,C.[ConnectionID]
		,'$DataLakeStorageEndpoint$'
	FROM 
		DI.[Connection] C
		INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
		CROSS JOIN DI.ConnectionPropertyType CPT
	WHERE 
		C.ConnectionName = 'ADS Data Lake'
		AND CPT.ConnectionPropertyTypeName = 'Service Endpoint'

END

--Data Lake date mask--

IF NOT EXISTS (	SELECT
					1
				FROM 
					DI.[ConnectionProperty] CP
					INNER JOIN DI.[Connection] C ON CP.ConnectionID = C.ConnectionID
					INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
					INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
				WHERE 
					C.ConnectionName = 'ADS Data Lake'
					AND CPT.ConnectionPropertyTypeName = 'Data Lake Date Mask')
BEGIN

	INSERT [DI].[ConnectionProperty]
	(
		[ConnectionPropertyTypeID]
	   ,[ConnectionID]
	   ,[ConnectionPropertyValue]
	)
	SELECT
		CPT.[ConnectionPropertyTypeID]
		,C.[ConnectionID]
		,'$DataLakeDateMask$'
	FROM 
		DI.[Connection] C
		INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
		CROSS JOIN DI.ConnectionPropertyType CPT
	WHERE 
		C.ConnectionName = 'ADS Data Lake'
		AND CPT.ConnectionPropertyTypeName = 'Data Lake Date Mask'

END

--Web application administrator--

IF NOT EXISTS (SELECT 1 FROM DI.[User] U WHERE U.UserID = '$WebAppAdminUserID$' AND '$WebAppAdminUserID$' <> '') 
BEGIN

	INSERT INTO DI.[User]
	(
		[UserID]
		,[UserName]
		,[EmailAddress]
		,[EnabledIndicator]
		,[AdminIndicator]
	)
	VALUES
	(
		'$WebAppAdminUserID$'
		,'$WebAppAdminUsername$'
		,'$WebAppAdminUPN$'
		,1
		,1
	)

END