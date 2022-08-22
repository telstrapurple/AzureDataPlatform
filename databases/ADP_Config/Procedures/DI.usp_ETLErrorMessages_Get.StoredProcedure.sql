/****** Object:  StoredProcedure [DI].[usp_ETLErrorMessages_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_ETLErrorMessages_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_ETLErrorMessages_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_ETLErrorMessages_Get]
(
	@RunStartDate DATETIME
)

AS

SELECT
	S.SystemName
   ,T.TaskID
   ,DFL.TaskInstanceID
   ,T.TaskName
   ,C.ConnectionName
   ,DFL.ActivityName
   ,DFL.DateCreated	
   ,DFL.ErrorMessage
FROM
	DI.DataFactoryLog DFL
	INNER JOIN DI.TaskInstance TI ON DFL.TaskInstanceID = TI.TaskInstanceID
	INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
	INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
	INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
	INNER JOIN DI.[Connection] C ON T.SourceConnectionID = C.ConnectionID
	CROSS APPLY (SELECT
			COUNT(*) AS [No of Tasks]
		FROM DI.Task
		WHERE T.EnabledIndicator = 1
		AND Task.TaskTypeID = T.TaskTypeID
		AND Task.SystemID = T.SystemID) TaskCount
WHERE
	CAST(DFL.DateCreated AT TIME ZONE 'W. Australia Standard Time' AS DATETIME) >= @RunStartDate
	AND DFL.TaskInstanceID IS NOT NULL
	AND DFL.LogType = 'Error'
ORDER BY 
	DFL.DateCreated DESC
	,S.SystemName
	,T.TaskName
	,DFL.TaskInstanceID
GO
