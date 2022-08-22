/****** Object:  View [DI].[vw_TaskInstanceConfig]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP VIEW IF EXISTS [DI].[vw_TaskInstanceConfig]
GO
/****** Object:  View [DI].[vw_TaskInstanceConfig]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  VIEW [DI].[vw_TaskInstanceConfig]

AS

SELECT
	'Source' AS ConnectionStage
	,TI.TaskInstanceID
	,SPT.SystemPropertyTypeName AS SystemPropertyType
	,SP.SystemPropertyValue
	,TT.TaskTypeName AS TaskType
	,TPT.TaskPropertyTypeName AS TaskPropertyType
	,TP.TaskPropertyValue
	,CT.ConnectionTypeName AS ConnectionType
	,AuT.AuthenticationTypeName AS AuthenticationType
	,CPT.ConnectionPropertyTypeName AS ConnectionPropertyType
	,CP.ConnectionPropertyValue
FROM
	DI.TaskInstance TI
	INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
	INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
	INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
	INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
	INNER JOIN DI.[Connection] C ON T.SourceConnectionID = C.ConnectionID
	INNER JOIN DI.AuthenticationType AuT ON AuT.AuthenticationTypeID = C.AuthenticationTypeID
	INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
	INNER JOIN DI.[ConnectionProperty] CP ON C.ConnectionID = CP.ConnectionID
	INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
	INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
	LEFT OUTER JOIN DI.SystemProperty SP ON S.SystemID = SP.SystemID AND SP.DeletedIndicator = 0
	LEFT OUTER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
WHERE
	TP.DeletedIndicator = 0
	AND CP.DeletedIndicator = 0

UNION ALL

SELECT
	'ETL' AS ConnectionStage
	,TI.TaskInstanceID
	,SPT.SystemPropertyTypeName AS SystemPropertyType
	,SP.SystemPropertyValue
	,TT.TaskTypeName AS TaskType
	,TPT.TaskPropertyTypeName AS TaskPropertyType
	,TP.TaskPropertyValue
	,CT.ConnectionTypeName AS ConnectionType
	,AuT.AuthenticationTypeName AS AuthenticationType
	,CPT.ConnectionPropertyTypeName AS ConnectionPropertyType
	,CP.ConnectionPropertyValue
FROM
	DI.TaskInstance TI
	INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
	INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
	INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
	INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
	INNER JOIN DI.[Connection] C ON T.ETLConnectionID = C.ConnectionID
	INNER JOIN DI.AuthenticationType AuT ON AuT.AuthenticationTypeID = C.AuthenticationTypeID
	INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
	INNER JOIN DI.[ConnectionProperty] CP ON C.ConnectionID = CP.ConnectionID
	INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
	INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
	LEFT OUTER JOIN DI.SystemProperty SP ON S.SystemID = SP.SystemID AND SP.DeletedIndicator = 0
	LEFT OUTER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
WHERE
	TP.DeletedIndicator = 0
	AND CP.DeletedIndicator = 0

UNION ALL

SELECT
	'Staging' AS ConnectionStage
	,TI.TaskInstanceID
	,SPT.SystemPropertyTypeName AS SystemPropertyType
	,SP.SystemPropertyValue
	,TT.TaskTypeName AS TaskType
	,TPT.TaskPropertyTypeName AS TaskPropertyType
	,TP.TaskPropertyValue
	,CT.ConnectionTypeName AS ConnectionType
	,AuT.AuthenticationTypeName AS AuthenticationType
	,CPT.ConnectionPropertyTypeName AS ConnectionPropertyType
	,CP.ConnectionPropertyValue
FROM
	DI.TaskInstance TI
	INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
	INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
	INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
	INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
	INNER JOIN DI.[Connection] C ON T.StageConnectionID = C.ConnectionID
	INNER JOIN DI.AuthenticationType AuT ON AuT.AuthenticationTypeID = C.AuthenticationTypeID
	INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
	INNER JOIN DI.[ConnectionProperty] CP ON C.ConnectionID = CP.ConnectionID
	INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
	INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
	LEFT OUTER JOIN DI.SystemProperty SP ON S.SystemID = SP.SystemID AND SP.DeletedIndicator = 0
	LEFT OUTER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
WHERE
	TP.DeletedIndicator = 0
	AND CP.DeletedIndicator = 0

UNION ALL

SELECT
	'Target' AS ConnectionStage
	,TI.TaskInstanceID
	,SPT.SystemPropertyTypeName AS SystemPropertyType
	,SP.SystemPropertyValue
	,TT.TaskTypeName AS TaskType
	,TPT.TaskPropertyTypeName AS TaskPropertyType
	,TP.TaskPropertyValue
	,CT.ConnectionTypeName AS ConnectionType
	,AuT.AuthenticationTypeName AS AuthenticationType
	,CPT.ConnectionPropertyTypeName AS ConnectionPropertyType
	,CP.ConnectionPropertyValue
FROM
	DI.TaskInstance TI
	INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
	INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
	INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
	INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
	INNER JOIN DI.[Connection] C ON T.TargetConnectionID = C.ConnectionID
	INNER JOIN DI.AuthenticationType AuT ON AuT.AuthenticationTypeID = C.AuthenticationTypeID
	INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
	INNER JOIN DI.[ConnectionProperty] CP ON C.ConnectionID = CP.ConnectionID
	INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
	INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
	LEFT OUTER JOIN DI.SystemProperty SP ON S.SystemID = SP.SystemID AND SP.DeletedIndicator = 0
	LEFT OUTER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
WHERE
	TP.DeletedIndicator = 0
	AND CP.DeletedIndicator = 0
GO
