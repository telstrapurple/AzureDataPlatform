/****** Object:  View [DI].[vw_DataFactoryLogSystem]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP VIEW IF EXISTS [DI].[vw_DataFactoryLogSystem]
GO
/****** Object:  View [DI].[vw_DataFactoryLogSystem]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [DI].[vw_DataFactoryLogSystem]
AS
SELECT
	DFL.SystemName
   ,DFL.SystemCode
   ,DFL.SystemID
   ,DFL.ScheduleName
   ,CASE
		WHEN DFL.ScheduleIntervalName = 'Months' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM')
		WHEN DFL.ScheduleIntervalName = 'Weeks' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, DFL.DateCreated) AS VARCHAR)
		WHEN DFL.ScheduleIntervalName = 'Days' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, DFL.DateCreated) AS VARCHAR) + FORMAT(DFL.PipelineTriggerTime, '-dd')
		WHEN DFL.ScheduleIntervalName = 'Hours' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, DFL.DateCreated) AS VARCHAR) + FORMAT(DFL.PipelineTriggerTime, '-dd-HH')
		WHEN DFL.ScheduleIntervalName = 'Minutes' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, DFL.DateCreated) AS VARCHAR) + FORMAT(DFL.PipelineTriggerTime, '-dd-HH-mm')
	END AS Schedule
   ,MIN(DFL.DateCreated) AS StartDateTime
   ,DATEDIFF(MINUTE, MIN(DFL.DateCreated), MAX(DFL.DateCreated)) AS RunTimeMinute
   ,MIN(CASE
			WHEN DFL.LogType = 'End'
			THEN 'Succeeded'
			WHEN DFL.LogType = 'Error'
			THEN 'Failed'
		END) AS SystemStatus
   ,COUNT(DISTINCT DFL.TaskInstanceID) AS TaskCount
FROM
	DI.vw_DataFactoryLog AS DFL
GROUP BY
	DFL.SystemName
   ,DFL.SystemCode
   ,DFL.SystemID
   ,DFL.ScheduleName
   ,CASE
		WHEN DFL.ScheduleIntervalName = 'Months' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM')
		WHEN DFL.ScheduleIntervalName = 'Weeks' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, DFL.DateCreated) AS VARCHAR)
		WHEN DFL.ScheduleIntervalName = 'Days' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, DFL.DateCreated) AS VARCHAR) + FORMAT(DFL.PipelineTriggerTime, '-dd')
		WHEN DFL.ScheduleIntervalName = 'Hours' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, DFL.DateCreated) AS VARCHAR) + FORMAT(DFL.PipelineTriggerTime, '-dd-HH')
		WHEN DFL.ScheduleIntervalName = 'Minutes' THEN FORMAT(DFL.PipelineTriggerTime, 'yyyy-MM-') + CAST(DATEPART(WEEK, DFL.DateCreated) AS VARCHAR) + FORMAT(DFL.PipelineTriggerTime, '-dd-HH-mm')
	END
GO
