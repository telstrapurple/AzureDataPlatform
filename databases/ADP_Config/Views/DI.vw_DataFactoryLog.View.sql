/****** Object:  View [DI].[vw_DataFactoryLog]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP VIEW IF EXISTS [DI].[vw_DataFactoryLog]
GO
/****** Object:  View [DI].[vw_DataFactoryLog]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [DI].[vw_DataFactoryLog]
AS
SELECT
	A.DataFactoryLogID
   ,A.TaskInstanceID
   ,A.LogType
   ,A.DataFactoryName
   ,A.PipelineName
   ,A.PipelineRunID
   ,A.PipelineTriggerID
   ,A.PipelineTriggerName
   ,A.PipelineTriggerTime
   ,A.PipelineTriggerType
   ,A.ActivityName
   ,A.OutputMessage
   ,A.ErrorMessage
   ,A.DateCreated
   ,A.EmailSentIndicator
   ,C.TaskName
   ,C.TaskDescription
   ,C.EnabledIndicator AS TaskEnabledIndicator
   ,C.DeletedIndicator AS TaskDeletedIndicator
   ,D.ScheduleName
   ,D.ScheduleDescription
   ,D.Frequency
   ,D.EnabledIndicator AS ScheduleEnabledIndicator
   ,D.DeletedIndicator AS ScheduleDeletedIndicator
   ,I.ScheduleIntervalName
   ,I.ScheduleIntervalDescription
   ,I.EnabledIndicator AS ScheduleIntervalEnabledIndicator
   ,I.DeletedIndicator AS ScheduleIntervalDeletedIndicator
   ,E.TaskTypeName
   ,E.TaskTypeDescription
   ,E.EnabledIndicator AS TaskTypeEnabledIndicator
   ,E.DeletedIndicator AS TaskTypeDeletedIndicator
   ,F.SystemName
   ,F.SystemDescription
   ,F.SystemCode
   ,F.SystemID
   ,F.EnabledIndicator AS SystemEnabledIndicator
   ,F.DeletedIndicator AS SystemDeletedIndicator
   ,G.ConnectionName AS SourceConnectionName
   ,G.ConnectionDescription AS SourceConnectionDescription
   ,H.ConnectionName AS TargetConnectionName
   ,H.ConnectionDescription AS TargetConnectionDescription
   ,CASE
		WHEN I.ScheduleIntervalName = 'Months' THEN FORMAT(A.PipelineTriggerTime, 'yyyy-MM')
		WHEN I.ScheduleIntervalName = 'Weeks' THEN FORMAT(A.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, A.DateCreated)
			AS VARCHAR)
		WHEN I.ScheduleIntervalName = 'Days' THEN FORMAT(A.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, A.DateCreated) AS VARCHAR) + FORMAT(A.PipelineTriggerTime, '-dd')
		WHEN I.ScheduleIntervalName = 'Hours' THEN FORMAT(A.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, A.DateCreated) AS VARCHAR) + FORMAT(A.PipelineTriggerTime, '-dd-HH')
		WHEN I.ScheduleIntervalName = 'Minutes' THEN FORMAT(A.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, A.DateCreated) AS VARCHAR) + FORMAT(A.PipelineTriggerTime, '-dd-HH-mm')
	END AS Schedule
	,DATEDIFF(MINUTE, LogStart.DateCreated, A.DateCreated) AS [Runtime in Mins]
FROM
	DI.DataFactoryLog AS A
	INNER JOIN DI.TaskInstance AS B ON A.TaskInstanceID = B.TaskInstanceID
	INNER JOIN DI.Task AS C ON B.TaskID = C.TaskID
	INNER JOIN DI.Schedule AS D ON C.ScheduleID = D.ScheduleID
	INNER JOIN DI.TaskType AS E ON C.TaskTypeID = E.TaskTypeID
	INNER JOIN DI.System AS F ON C.SystemID = F.SystemID
	INNER JOIN DI.Connection AS G ON C.SourceConnectionID = G.ConnectionID
	LEFT OUTER JOIN DI.Connection AS H ON C.TargetConnectionID = H.ConnectionID
	INNER JOIN DI.ScheduleInterval AS I ON D.ScheduleIntervalID = I.ScheduleIntervalID
	LEFT OUTER JOIN 
	(
	SELECT 
		DFL.DataFactoryLogID
		,DFL.TaskInstanceID
		,DFL.LogType
		,LAG(DFL.DateCreated, 1) OVER(PARTITION BY DFL.TaskInstanceID ORDER BY DFL.DataFactoryLogID) AS DateCreated
	FROM 
		DI.DataFactoryLog DFL
	) LogStart ON A.DataFactoryLogID = LogStart.DataFactoryLogID
GO
