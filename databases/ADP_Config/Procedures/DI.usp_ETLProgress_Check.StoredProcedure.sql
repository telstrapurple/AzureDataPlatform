/****** Object:  StoredProcedure [DI].[usp_ETLProgress_Check]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_ETLProgress_Check]
GO
/****** Object:  StoredProcedure [DI].[usp_ETLProgress_Check]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [DI].[usp_ETLProgress_Check]
(
	@RunStartDate DATETIME
)

AS

SELECT
	SystemName
	,ISNULL(MAX([No of Tasks]), 0) - COUNT(DISTINCT TI.ErrorTaskInstance) AS [No of Tasks Remaining]
	,COUNT(DISTINCT [StartTaskInstance]) - COUNT(DISTINCT [EndTaskInstance]) - COUNT(DISTINCT TI.ErrorTaskInstance) AS [In Progress Count]
	,COUNT(DISTINCT [EndTaskInstance]) AS [Completed Count]
	,COUNT(DISTINCT TI.ErrorTaskInstance) AS [Error Count]
FROM
	(
	SELECT
		S.SystemName
		,CASE WHEN DFL.LogType = 'Start' THEN DFL.TaskInstanceID END AS [StartTaskInstance]
		,CASE WHEN DFL.LogType = 'End' THEN DFL.TaskInstanceID END AS [EndTaskInstance]
		,CASE WHEN DFL.LogType = 'Error' THEN DFL.TaskInstanceID END AS [ErrorTaskInstance]
		,TaskCount.[No of Tasks]
	FROM
		DI.DataFactoryLog DFL
		INNER JOIN DI.TaskInstance TI ON DFL.TaskInstanceID = TI.TaskInstanceID
		INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
		INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
		OUTER APPLY
		(
		SELECT 
			COUNT(*) AS [No of Tasks]
		FROM
			DI.Task
			INNER JOIN DI.TaskInstance TI1 ON Task.TaskID = TI1.TaskID
		WHERE
			T.EnabledIndicator = 1
			AND Task.TaskTypeID = T.TaskTypeID
			AND Task.SystemID = T.SystemID
			AND TI.ScheduleInstanceID = TI1.ScheduleInstanceID
			AND TI1.TaskResultID <> 1
		) TaskCount
	WHERE
		CAST(DFL.DateCreated AT TIME ZONE 'W. Australia Standard Time' AS DATETIME) >= @RunStartDate
		AND DFL.TaskInstanceID IS NOT NULL
	) TI
GROUP BY 
	SystemName
ORDER BY 
	SystemName
GO
