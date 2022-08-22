/****** Object:  StoredProcedure [DI].[usp_System_Run]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_System_Run]
GO
/****** Object:  StoredProcedure [DI].[usp_System_Run]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_System_Run]
(
	@System NVARCHAR(100)
	,@TaskType NVARCHAR(100)
	,@Sequential BIT = 0
	,@Schedule NVARCHAR(MAX) 
)

AS

SET NOCOUNT ON

BEGIN TRY

		--Insert the new schedule instances if required--

		CREATE TABLE #SchedIns
		(
			ScheduleInstanceID INT,
			ScheduleID INT
		)

		INSERT INTO DI.ScheduleInstance
		(
			ScheduleID
			,RunDate
		)

		OUTPUT 
			[INSERTED].ScheduleInstanceID
			,[INSERTED].ScheduleID
		INTO 
			#SchedIns

		SELECT DISTINCT
			T.ScheduleID
			,SYSUTCDATETIME()
		FROM
			DI.Task T
			INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
			INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
			INNER JOIN DI.Schedule Sch ON T.ScheduleID = Sch.ScheduleID
			INNER JOIN DI.ScheduleInterval SInt ON Sch.ScheduleIntervalID = SInt.ScheduleIntervalID
			LEFT OUTER JOIN 
			(
			SELECT 
				ScheduleID
				,MAX(ScheduleInstanceID) AS ScheduleInstanceID
			FROM
				DI.ScheduleInstance
			WHERE
				EnabledIndicator = 1
				AND DeletedIndicator = 0
			GROUP BY 
				ScheduleID
			) SILatest ON T.ScheduleID = SILatest.ScheduleID
			LEFT OUTER JOIN DI.ScheduleInstance SI ON SILatest.ScheduleInstanceID = SI.ScheduleInstanceID
		WHERE
			S.SystemName = @System
			AND TT.TaskTypeName = @TaskType
			AND T.EnabledIndicator = 1
			AND T.DeletedIndicator = 0
			AND CASE
					WHEN @Sequential = 1
					THEN T.TaskOrderID
					ELSE ''
				END IS NOT NULL
			AND CASE
					WHEN @Sequential = 0
					THEN T.TaskOrderID
					ELSE NULL
				END IS NULL
			AND Sch.EnabledIndicator = 1
			AND Sch.DeletedIndicator = 0
			AND Sch.ScheduleName = @Schedule
			--Schedule has not been created or is new--
			AND (SI.ScheduleInstanceID IS NULL OR
					(SI.ScheduleInstanceID IS NOT NULL AND
						(
						CASE SInt.ScheduleIntervalName
							WHEN 'Minutes'
							THEN DATEDIFF(MINUTE, ISNULL(SI.RunDate, Sch.StartDate), SYSUTCDATETIME())
						END >= Sch.Frequency
						OR
						CASE SInt.ScheduleIntervalName
							WHEN 'Hours'
							THEN DATEDIFF(HOUR, ISNULL(SI.RunDate, Sch.StartDate), SYSUTCDATETIME())
						END >= Sch.Frequency
						 OR
						CASE SInt.ScheduleIntervalName
							WHEN 'Days'
							THEN DATEDIFF(DAY, ISNULL(SI.RunDate, Sch.StartDate), SYSUTCDATETIME())
						END >= Sch.Frequency
						OR
						CASE SInt.ScheduleIntervalName
							WHEN 'Months'
							THEN DATEDIFF(MONTH, ISNULL(SI.RunDate, Sch.StartDate), SYSUTCDATETIME())
						END >= Sch.Frequency
						OR
						CASE SInt.ScheduleIntervalName
							WHEN 'Weeks'
							THEN DATEDIFF(WEEK, ISNULL(SI.RunDate, Sch.StartDate), SYSUTCDATETIME())
						END >= Sch.Frequency
						)
					)
				)

		--Disable all the schedule instances where new schedule instances have been created--

		UPDATE 
			SI
		SET
			EnabledIndicator = 0
			,DateModified = SYSUTCDATETIME()
		FROM 
			DI.ScheduleInstance SI
			INNER JOIN #SchedIns SINew ON SI.ScheduleID = SINew.ScheduleID
		WHERE
			SI.ScheduleInstanceID <> SINew.ScheduleInstanceID
			AND SI.EnabledIndicator = 1

		--Insert the new Task Instances--

		INSERT INTO DI.TaskInstance
		(
			TaskID
			,ScheduleInstanceID
			,RunDate
			,TaskResultID
		)

		SELECT DISTINCT
			T.TaskID
			,SI.ScheduleInstanceID
			,SYSUTCDATETIME()
			,(SELECT TR.TaskResultID FROM DI.TaskResult TR WHERE TR.TaskResultName = 'Untried')
		FROM
			DI.Task T
			INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
			INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
			INNER JOIN DI.Schedule Sch ON T.ScheduleID = Sch.ScheduleID
			INNER JOIN DI.ScheduleInterval SInt ON Sch.ScheduleIntervalID = SInt.ScheduleIntervalID
			LEFT OUTER JOIN 
			--Get the latest task instance per task
			(
			SELECT 
				TaskID
				,S.ScheduleID
				,MAX(TaskInstanceID) AS TaskInstanceID
			FROM
				DI.TaskInstance TI
				INNER JOIN DI.ScheduleInstance SI ON TI.ScheduleInstanceID = SI.ScheduleInstanceID
				INNER JOIN DI.Schedule S ON SI.ScheduleID = S.ScheduleID
			WHERE
				S.EnabledIndicator = 1
				AND S.DeletedIndicator = 0
				AND SI.EnabledIndicator = 1
				AND SI.DeletedIndicator = 0
			GROUP BY 
				TaskID
				,S.ScheduleID
			) TILatest ON T.TaskID = TILatest.TaskID
				AND Sch.ScheduleID = TILatest.ScheduleID
			LEFT OUTER JOIN DI.TaskInstance TI ON TILatest.TaskInstanceID = TI.TaskInstanceID
			LEFT OUTER JOIN DI.TaskResult TR ON TI.TaskResultID = TR.TaskResultID
			--Get the latest schedule instance per schedule--
			INNER JOIN  
			(
			SELECT 
				ScheduleID
				,MAX(ScheduleInstanceID) AS ScheduleInstanceID
			FROM
				DI.ScheduleInstance
			WHERE
				EnabledIndicator = 1
				AND DeletedIndicator = 0
			GROUP BY 
				ScheduleID
			) SILatest ON T.ScheduleID = SILatest.ScheduleID
			LEFT OUTER JOIN DI.ScheduleInstance SI ON SILatest.ScheduleInstanceID = SI.ScheduleInstanceID
		WHERE
			S.SystemName = @System
			AND TT.TaskTypeName = @TaskType
			AND CASE
					WHEN @Sequential = 1
					THEN T.TaskOrderID
					ELSE ''
				END IS NOT NULL
			AND CASE
					WHEN @Sequential = 0
					THEN T.TaskOrderID
					ELSE NULL
				END IS NULL
			AND T.EnabledIndicator = 1
			AND T.DeletedIndicator = 0
			AND Sch.EnabledIndicator = 1
			AND Sch.DeletedIndicator = 0
			AND SInt.EnabledIndicator = 1
			AND SInt.DeletedIndicator = 0
			AND Sch.ScheduleName = @Schedule
			--Task failed or has not been tried--
			AND (TR.RetryIndicator = 1 OR TR.TaskResultName IS NULL) AND
				(
					(
					CASE SInt.ScheduleIntervalName
						WHEN 'Minutes'
						THEN DATEDIFF(MINUTE, ISNULL(TI.RunDate, Sch.StartDate), SYSUTCDATETIME())
					END >= Sch.Frequency
					OR
					CASE SInt.ScheduleIntervalName
						WHEN 'Hours'
						THEN DATEDIFF(HOUR, ISNULL(TI.RunDate, Sch.StartDate), SYSUTCDATETIME())
					END >= Sch.Frequency
						OR
					CASE SInt.ScheduleIntervalName
						WHEN 'Days'
						THEN DATEDIFF(DAY, ISNULL(TI.RunDate, Sch.StartDate), SYSUTCDATETIME())
					END >= Sch.Frequency
					OR
					CASE SInt.ScheduleIntervalName
						WHEN 'Months'
						THEN DATEDIFF(MONTH, ISNULL(TI.RunDate, Sch.StartDate), SYSUTCDATETIME())
					END >= Sch.Frequency
					OR
					CASE SInt.ScheduleIntervalName
						WHEN 'Weeks'
						THEN DATEDIFF(WEEK, ISNULL(TI.RunDate, Sch.StartDate), SYSUTCDATETIME())
					END >= Sch.Frequency
					)
				)

		--Get the list of task instances that need to be run--

		IF @Sequential = 0
		BEGIN 
			SELECT
				S.SystemID
				,TI.ScheduleInstanceID
				,T.TaskID
				,TI.TaskInstanceID
			FROM
				DI.TaskInstance TI
				INNER JOIN 
				(
				SELECT 
					TaskID
					,S.ScheduleID
					,MAX(TaskInstanceID) AS TaskInstanceID
				FROM
					DI.TaskInstance TI
					INNER JOIN DI.ScheduleInstance SI ON TI.ScheduleInstanceID = SI.ScheduleInstanceID
					INNER JOIN DI.Schedule S ON SI.ScheduleID = S.ScheduleID
				WHERE
					SI.EnabledIndicator = 1
					AND SI.DeletedIndicator = 0
					AND S.EnabledIndicator = 1
					AND S.DeletedIndicator = 0
				GROUP BY 
					TaskID
					,S.ScheduleID
				) TILatest ON TI.TaskInstanceID = TILatest.TaskInstanceID
				INNER JOIN DI.Schedule Sch ON TILatest.ScheduleID = Sch.ScheduleID
				INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
				INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
				INNER JOIN DI.TaskResult TR ON TI.TaskResultID = TR.TaskResultID
				INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
			WHERE	
				TR.RetryIndicator = 1
				AND T.TaskOrderID IS NULL 
				AND S.SystemName = @System
				AND TT.TaskTypeName = @TaskType
				AND Sch.EnabledIndicator = 1
				AND Sch.DeletedIndicator = 0
				AND T.EnabledIndicator = 1
				AND T.DeletedIndicator = 0
				AND Sch.ScheduleName = @Schedule
		END

		IF @Sequential = 1
		BEGIN
			SELECT
				S.SystemID
				,TI.ScheduleInstanceID
				,T.TaskID
				,TI.TaskInstanceID
			FROM
				DI.TaskInstance TI
				INNER JOIN 
				(
				SELECT 
					TaskID
					,S.ScheduleID
					,MAX(TaskInstanceID) AS TaskInstanceID
				FROM
					DI.TaskInstance TI
					INNER JOIN DI.ScheduleInstance SI ON TI.ScheduleInstanceID = SI.ScheduleInstanceID
					INNER JOIN DI.Schedule S ON SI.ScheduleID = S.ScheduleID
				WHERE
					SI.EnabledIndicator = 1
					AND SI.DeletedIndicator = 0
					AND S.EnabledIndicator = 1
					AND S.DeletedIndicator = 0
				GROUP BY 
					TaskID
					,S.ScheduleID
				) TILatest ON TI.TaskInstanceID = TILatest.TaskInstanceID
				INNER JOIN DI.Schedule Sch ON TILatest.ScheduleID = Sch.ScheduleID
				INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
				INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
				INNER JOIN DI.TaskResult TR ON TI.TaskResultID = TR.TaskResultID
				INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
			WHERE	
				TR.RetryIndicator = 1
				AND T.TaskOrderID IS NOT NULL 
				AND S.SystemName = @System
				AND TT.TaskTypeName = @TaskType
				AND Sch.EnabledIndicator = 1
				AND Sch.DeletedIndicator = 0
				AND T.EnabledIndicator = 1
				AND T.DeletedIndicator = 0
				AND Sch.ScheduleName = @Schedule
			ORDER BY 
				T.TaskOrderID ASC
		END


END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
