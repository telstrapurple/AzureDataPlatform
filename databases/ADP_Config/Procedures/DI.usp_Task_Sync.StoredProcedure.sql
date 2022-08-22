/****** Object:  StoredProcedure [DI].[usp_Task_Sync]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_Task_Sync]
GO
/****** Object:  StoredProcedure [DI].[usp_Task_Sync]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [DI].[usp_Task_Sync]
(
	@TaskID INT = 0
	,@SystemID INT = 0
)

AS

SET NOCOUNT ON
	
BEGIN TRY

	DECLARE 
		@SyncString VARCHAR(MAX) = ''
		,@SelectString VARCHAR(MAX) = ''
		,@TaskName VARCHAR(100)
		,@SystemName VARCHAR(100) 

	IF NOT EXISTS (SELECT 1 FROM DI.Task T WHERE T.TaskID = @TaskID) AND @TaskID <> 0 
    BEGIN
		;
        THROW 51000, 'Please ensure that the task you are trying to sync exists', 1
        
    END

	IF NOT EXISTS (SELECT 1 FROM DI.Task T WHERE T.SystemID = @SystemID AND T.DeletedIndicator = 0) AND @SystemID <> 0 
    BEGIN
		;
        THROW 51000, 'Please ensure that there are tasks in the system you are trying to sync', 1
        
    END

	IF NOT EXISTS (SELECT 1 FROM DI.[System] S WHERE S.SystemID = @SystemID) AND @SystemID <> 0 
    BEGIN
		;
        THROW 51000, 'Please ensure that the system you are trying to sync exists', 1
        
    END

	SELECT
		@SystemName = S.SystemName
		,@TaskName = T.TaskName
	FROM
		DI.Task T
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
	WHERE
		(T.TaskID = @TaskID AND @TaskID <> 0)
		OR (S.SystemID = @SystemID AND @SystemID <> 0)

	SET @SyncString = '
	BEGIN TRY
		BEGIN TRANSACTION

		SET NOCOUNT ON

		DECLARE @ScheduleInterval TABLE(ScheduleIntervalID INT)
		DECLARE @Schedule TABLE(ScheduleID INT)
		DECLARE @TaskType TABLE(TaskTypeID INT)
		DECLARE @System TABLE(SystemID INT)
		DECLARE @Connection TABLE(ConnectionID INT, ConnectionName VARCHAR(100))
		DECLARE @Task TABLE(TaskID INT)

		DECLARE
			@SourceConnectionID INT
			,@ETLConnectionID INT
			,@StageConnectionID INT
			,@TargetConnectionID INT
			,@ScheduleID INT
			,@SystemID INT
			,@TaskTypeID INT
			,@TaskID INT

		PRINT(''Starting system ' + @SystemName + ' sync'')

		'

	-- Check if the system exists

	SELECT
		@SelectString = 'SELECT ''' + S.SystemName + ''' AS SystemName,' + CASE WHEN S.SystemDescription IS NULL THEN 'NULL' ELSE '''' + S.SystemDescription + '''' END + ' AS SystemDescription,' + CASE WHEN S.SystemCode IS NULL THEN 'NULL' ELSE '''' + S.SystemCode + '''' END + ' AS SystemCode'
	FROM
		(
		SELECT DISTINCT
			S.SystemName
			,S.SystemDescription
			,S.SystemCode
		FROM
			DI.Task T
			INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
		WHERE
			(T.TaskID = @TaskID AND @TaskID <> 0)
			OR (S.SystemID = @SystemID AND @SystemID <> 0)
		) S

	SET @SyncString += '
		DELETE FROM @System
		
		MERGE
			DI.System T
		USING
			(
				' + @SelectString + '
			) S ON T.SystemName = S.SystemName
		WHEN MATCHED THEN
		UPDATE
		SET
			T.SystemDescription = S.SystemDescription
			,T.SystemCode = S.SystemCode
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT
		(
			SystemName
			,SystemDescription
			,SystemCode
		)
		VALUES
		(
			S.SystemName
			,S.SystemDescription
			,S.SystemCode
		)
		OUTPUT 
			ISNULL([INSERTED].SystemID, [DELETED].SystemID) 
		INTO 
			@System
		;
		SELECT @SystemID = SystemID FROM @System

		PRINT(''System ' + @SystemName + ' sync completed'')
		'

	-- Check if the system properties exist

	SET @SelectString = ''

	SELECT
		@SelectString += 'SELECT @SystemID AS SystemID,''' + SP.SystemPropertyTypeName + ''' AS SystemPropertyTypeName,''' + REPLACE(SP.SystemPropertyValue, CHAR(39), '''''') + ''' AS SystemPropertyValue UNION ALL '
	FROM
		(
		SELECT DISTINCT
			SPT.SystemPropertyTypeName 
			,SP.SystemPropertyValue
		FROM 
			DI.Task T
			INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
			INNER JOIN DI.SystemProperty SP ON S.SystemID = SP.SystemID
			INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
		WHERE
			(T.TaskID = @TaskID AND @TaskID <> 0)
			OR (S.SystemID = @SystemID AND @SystemID <> 0)
		) SP

	SET @SyncString += '
		MERGE
			DI.SystemProperty T
		USING
			(
				SELECT 
					SP.*
					,SPT.SystemPropertyTypeID 
				FROM 
					(' + LEFT(@SelectString, LEN(@SelectString) - 10) + ') SP 
					INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeName = SPT.SystemPropertyTypeName
						AND SPT.DeletedIndicator = 0
			) S ON T.SystemID = S.SystemID
				AND T.SystemPropertyTypeID = S.SystemPropertyTypeID
		WHEN MATCHED THEN
		UPDATE
		SET
			T.SystemPropertyValue = S.SystemPropertyValue
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT 
		(
			SystemPropertyTypeID
			,SystemID
			,SystemPropertyValue
		)
		VALUES
		(
			S.SystemPropertyTypeID
			,S.SystemID
			,S.SystemPropertyValue
		)
		;
		'

	IF @SystemID <> 0

	BEGIN

		DECLARE Task_Cursor CURSOR FAST_FORWARD READ_ONLY FOR
		SELECT
			T.TaskID
		FROM
			DI.Task T
		WHERE
			T.SystemID = @SystemID
			AND T.DeletedIndicator = 0

		OPEN Task_Cursor

		FETCH NEXT FROM Task_Cursor INTO @TaskID

		WHILE @@fetch_status = 0

		BEGIN

			SELECT
				@TaskName = T.TaskName
			FROM
				DI.Task T
			WHERE
				T.TaskID = @TaskID
		
			-- Check if the schedule interval exists

			SET @SyncString += '
			PRINT(''Starting task ' + @TaskName + ' sync'')
			'

			SELECT
				@SelectString = 'SELECT ''' + SI.ScheduleIntervalName + ''' AS ScheduleIntervalName,' + CASE WHEN SI.ScheduleIntervalDescription IS NULL THEN 'NULL' ELSE '''' + SI.ScheduleIntervalDescription + '''' END + ' AS ScheduleIntervalDescription'
			FROM
				DI.Task T
				INNER JOIN DI.Schedule S ON T.ScheduleID = S.ScheduleID
				INNER JOIN DI.ScheduleInterval SI ON S.ScheduleIntervalID = SI.ScheduleIntervalID
			WHERE
				T.TaskID = @TaskID

			SET @SyncString += '
			DELETE FROM @ScheduleInterval

			MERGE
				DI.ScheduleInterval T
			USING
				(
					' + @SelectString + '
				) S ON T.ScheduleIntervalName = S.ScheduleIntervalName
			WHEN MATCHED THEN
			UPDATE
			SET
				T.ScheduleIntervalDescription = S.ScheduleIntervalDescription
			WHEN NOT MATCHED BY TARGET THEN 
			INSERT
			(
				 ScheduleIntervalName
				 ,ScheduleIntervalDescription
			)
			VALUES
			(
				S.ScheduleIntervalName
				,S.ScheduleIntervalDescription
			)
			OUTPUT 
				ISNULL([INSERTED].ScheduleIntervalID, [DELETED].ScheduleIntervalID) 
			INTO 
				@ScheduleInterval
			;
			'

			-- Check if the schedule exists

			SELECT
				@SelectString = 'SELECT ''' + S.ScheduleName + ''' AS ScheduleName,' + CASE WHEN S.ScheduleDescription IS NULL THEN 'NULL' ELSE '''' + S.ScheduleDescription + '''' END + ' AS ScheduleDescription,ScheduleIntervalID,' + CAST(S.Frequency AS VARCHAR(50)) + ' AS Frequency,''' + FORMAT(S.StartDate, 'yyyy-MM-dd HH:mm:ss') + ''' AS StartDate FROM @ScheduleInterval'
			FROM
				DI.Task T
				INNER JOIN DI.Schedule S ON T.ScheduleID = S.ScheduleID
			WHERE
				T.TaskID = @TaskID

			SET @SyncString += '
			DELETE FROM @Schedule

			MERGE
				DI.Schedule T
			USING
				(
					' + @SelectString + '
				) S ON T.ScheduleName = S.ScheduleName
			WHEN MATCHED THEN
			UPDATE
			SET
				T.ScheduleDescription = S.ScheduleDescription
				,T.ScheduleIntervalID = S.ScheduleIntervalID
				,T.Frequency = S.Frequency
				,T.StartDate = S.StartDate
			WHEN NOT MATCHED BY TARGET THEN 
			INSERT
			(
				ScheduleName
				,ScheduleDescription
				,ScheduleIntervalID
				,Frequency
				,StartDate
			)
			VALUES
			(
				S.ScheduleName
				,S.ScheduleDescription
				,S.ScheduleIntervalID
				,S.Frequency
				,S.StartDate
			)
			OUTPUT 
				ISNULL([INSERTED].ScheduleID, [DELETED].ScheduleID) 
			INTO 
				@Schedule
			;
			SELECT @ScheduleID = ScheduleID FROM @Schedule
			'

			-- Check if the task type exists

			SELECT
				@SelectString = 'SELECT ''' + TT.TaskTypeName + ''' AS TaskTypeName,' + CASE WHEN TT.TaskTypeDescription IS NULL THEN 'NULL' ELSE '''' + TT.TaskTypeDescription + '''' END + ' AS TaskTypeDescription,' + ISNULL(CAST(TT.ScriptIndicator AS VARCHAR(50)), 'NULL') + ' AS ScriptIndicator,' + CAST(TT.FileLoadIndicator AS VARCHAR(50)) + ' AS FileLoadIndicator,' + CAST(TT.DatabaseLoadIndicator AS VARCHAR(50)) + ' AS DatabaseLoadIndicator,''' + TT.RunType + ''' AS RunType'
			FROM
				DI.Task T
				INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
			WHERE
				T.TaskID = @TaskID

			SET @SyncString += '
			DELETE FROM @TaskType

			MERGE
				DI.TaskType T
			USING
				(
					' + @SelectString + '
				) S ON T.TaskTypeName = S.TaskTypeName
			WHEN MATCHED THEN
			UPDATE
			SET
				T.TaskTypeDescription = S.TaskTypeDescription
				,T.ScriptIndicator = S.ScriptIndicator
				,T.FileLoadIndicator = S.FileLoadIndicator
				,T.DatabaseLoadIndicator = S.DatabaseLoadIndicator
				,T.RunType = S.RunType
			WHEN NOT MATCHED BY TARGET THEN 
			INSERT
			(
				TaskTypeName
				,TaskTypeDescription
				,ScriptIndicator
				,FileLoadIndicator
				,DatabaseLoadIndicator
				,RunType
			)
			VALUES
			(
				S.TaskTypeName
				,S.TaskTypeDescription
				,S.ScriptIndicator
				,S.FileLoadIndicator
				,S.DatabaseLoadIndicator
				,S.RunType
			)
			OUTPUT 
				ISNULL([INSERTED].TaskTypeID, [DELETED].TaskTypeID) 
			INTO 
				@TaskType
			;
			SELECT @TaskTypeID = TaskTypeID FROM @TaskType
			'

			-- Check if the connections exist

			SELECT
				@SelectString = 'SELECT ''Source'' AS ConnectionType, ''' + C.ConnectionName + ''' AS ConnectionName,' + CASE WHEN C.ConnectionDescription IS NULL THEN 'NULL' ELSE '''' + C.ConnectionDescription + '''' END + ' AS ConnectionDescription,''' + CT.ConnectionTypeName + ''' AS ConnectionTypeName,''' + [AT].AuthenticationTypeName + ''' AS AuthenticationTypeName'
			FROM
				DI.Task T
				INNER JOIN DI.[Connection] C ON T.SourceConnectionID = C.ConnectionID
				INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
				INNER JOIN DI.AuthenticationType [AT] ON C.AuthenticationTypeID = [AT].AuthenticationTypeID
			WHERE
				T.TaskID = @TaskID

			SELECT
				@SelectString += ' UNION ALL SELECT ''ETL'' AS ConnectionType, ''' + C.ConnectionName + ''' AS ConnectionName,' + CASE WHEN C.ConnectionDescription IS NULL THEN 'NULL' ELSE '''' + C.ConnectionDescription + '''' END + ' AS ConnectionDescription,''' + CT.ConnectionTypeName + ''' AS ConnectionTypeName,''' + [AT].AuthenticationTypeName + ''' AS AuthenticationTypeName'
			FROM
				DI.Task T
				INNER JOIN DI.[Connection] C ON T.ETLConnectionID = C.ConnectionID
				INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
				INNER JOIN DI.AuthenticationType [AT] ON C.AuthenticationTypeID = [AT].AuthenticationTypeID
			WHERE
				T.TaskID = @TaskID

			SELECT
				@SelectString += ' UNION ALL SELECT ''Stage'' AS ConnectionType, ''' + C.ConnectionName + ''' AS ConnectionName,' + CASE WHEN C.ConnectionDescription IS NULL THEN 'NULL' ELSE '''' + C.ConnectionDescription + '''' END + ' AS ConnectionDescription,''' + CT.ConnectionTypeName + ''' AS ConnectionTypeName,''' + [AT].AuthenticationTypeName + ''' AS AuthenticationTypeName'
			FROM
				DI.Task T
				INNER JOIN DI.[Connection] C ON T.StageConnectionID = C.ConnectionID
				INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
				INNER JOIN DI.AuthenticationType [AT] ON C.AuthenticationTypeID = [AT].AuthenticationTypeID
			WHERE
				T.TaskID = @TaskID

			SELECT
				@SelectString += ' UNION ALL SELECT ''Target'' AS ConnectionType, ''' + C.ConnectionName + ''' AS ConnectionName,' + CASE WHEN C.ConnectionDescription IS NULL THEN 'NULL' ELSE '''' + C.ConnectionDescription + '''' END + ' AS ConnectionDescription,''' + CT.ConnectionTypeName + ''' AS ConnectionTypeName,''' + [AT].AuthenticationTypeName + ''' AS AuthenticationTypeName'
			FROM
				DI.Task T
				INNER JOIN DI.[Connection] C ON T.TargetConnectionID = C.ConnectionID
				INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
				INNER JOIN DI.AuthenticationType [AT] ON C.AuthenticationTypeID = [AT].AuthenticationTypeID
			WHERE
				T.TaskID = @TaskID

			SET @SyncString += '
			DELETE FROM @Connection

			MERGE
				DI.Connection T
			USING
				(
				SELECT DISTINCT
					ConnectionName
					,ConnectionDescription
					,CT.ConnectionTypeID
					,[AT].AuthenticationTypeID
				FROM
					(
						' + @SelectString + '
					) tmp 
					INNER JOIN DI.ConnectionType CT ON tmp.ConnectionTypeName = CT.ConnectionTypeName
						AND CT.DeletedIndicator = 0
					INNER JOIN DI.AuthenticationType [AT] ON tmp.AuthenticationTypeName = [AT].AuthenticationTypeName
						AND [AT].DeletedIndicator = 0
				) S ON T.ConnectionName = S.ConnectionName
			WHEN MATCHED THEN
			UPDATE
			SET
				T.ConnectionDescription = S.ConnectionDescription
				,T.ConnectionTypeID = S.ConnectionTypeID
				,T.AuthenticationTypeID = S.AuthenticationTypeID
			WHEN NOT MATCHED BY TARGET THEN 
			INSERT
			(
				ConnectionName
				,ConnectionDescription
				,ConnectionTypeID
				,AuthenticationTypeID
			)
			VALUES
			(
				S.ConnectionName
				,S.ConnectionDescription
				,S.ConnectionTypeID
				,S.AuthenticationTypeID
			)
			OUTPUT 
				ISNULL([INSERTED].ConnectionID, [DELETED].ConnectionID)
				,ISNULL([INSERTED].ConnectionName, [DELETED].ConnectionName)
			INTO 
				@Connection
			;

			SELECT @SourceConnectionID = ConnectionID FROM (' + @SelectString + ') S INNER JOIN DI.Connection C ON S.ConnectionName = C.ConnectionName AND C.DeletedIndicator = 0 AND S.ConnectionType = ''Source''
			SELECT @ETLConnectionID = ConnectionID FROM (' + @SelectString + ') S INNER JOIN DI.Connection C ON S.ConnectionName = C.ConnectionName AND C.DeletedIndicator = 0 AND ConnectionType = ''ETL''
			SELECT @StageConnectionID = ConnectionID FROM (' + @SelectString + ') S INNER JOIN DI.Connection C ON S.ConnectionName = C.ConnectionName AND C.DeletedIndicator = 0 AND ConnectionType = ''Stage''
			SELECT @TargetConnectionID = ConnectionID FROM (' + @SelectString + ') S INNER JOIN DI.Connection C ON S.ConnectionName = C.ConnectionName AND C.DeletedIndicator = 0 AND ConnectionType = ''Target''

			'

			-- Check if the task exists

			SELECT
				@SelectString = 'SELECT ''' + T.TaskName + ''' AS TaskName,' + CASE WHEN T.TaskDescription IS NULL THEN 'NULL' ELSE '''' + T.TaskDescription + '''' END + ' AS TaskDescription,@SystemID AS SystemID,@ScheduleID AS ScheduleID,@TaskTypeID AS TaskTypeID,@SourceConnectionID AS SourceConnectionID,@ETLConnectionID AS ETLConnectionID,@StageConnectionID AS StageConnectionID,@TargetConnectionID AS TargetConnectionID,' + ISNULL(CAST(T.TaskOrderID AS VARCHAR(50)), 'NULL') + ' AS TaskOrderID'
			FROM
				DI.Task T
				INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
			WHERE
				T.TaskID = @TaskID

			SET @SyncString += '
			DELETE FROM @Task
			;

			MERGE
				DI.Task T
			USING
				(
					' + @SelectString + '
				) S ON T.TaskName = S.TaskName
					AND T.SystemID = S.SystemID
			WHEN MATCHED THEN
			UPDATE
			SET
				T.TaskDescription = S.TaskDescription
				,T.ScheduleID = S.ScheduleID
				,T.TaskTypeID = S.TaskTypeID
				,T.SourceConnectionID = S.SourceConnectionID
				,T.ETLConnectionID = S.ETLConnectionID
				,T.StageConnectionID = S.StageConnectionID
				,T.TargetConnectionID = S.TargetConnectionID
				,T.TaskOrderID = S.TaskOrderID
			WHEN NOT MATCHED BY TARGET THEN 
			INSERT
			(
				TaskName
				,TaskDescription
				,SystemID
				,ScheduleID
				,TaskTypeID
				,SourceConnectionID
				,ETLConnectionID
				,StageConnectionID
				,TargetConnectionID
				,TaskOrderID
			)
			VALUES
			(
				S.TaskName
				,S.TaskDescription
				,S.SystemID
				,S.ScheduleID
				,S.TaskTypeID
				,S.SourceConnectionID
				,S.ETLConnectionID
				,S.StageConnectionID
				,S.TargetConnectionID
				,S.TaskOrderID
			)
			OUTPUT 
				ISNULL([INSERTED].TasKID, [DELETED].TaskID) 
			INTO 
				@Task
			;
			SELECT @TaskID = TaskID FROM @Task
			'

			-- Check if the task properties exist

			SET @SelectString = ''

			SELECT
				@SelectString += 'SELECT @TaskID AS TaskID, ''' + TPT.TaskPropertyTypeName + ''' AS TaskPropertyTypeName,''' + REPLACE(TP.TaskPropertyValue, CHAR(39), '''''') + ''' AS TaskPropertyValue UNION ALL '
			FROM
				DI.Task T
				INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
				INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
			WHERE
				T.TaskID = @TaskID

			SET @SyncString += '
			MERGE
				DI.TaskProperty T
			USING
				(
					SELECT 
						TP.*
						,TPT.TaskPropertyTypeID 
					FROM 
						(' + LEFT(@SelectString, LEN(@SelectString) - 10) + ') TP 
						INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeName = TPT.TaskPropertyTypeName
				) S ON T.TaskID = S.TaskID
					AND T.TaskPropertyTypeID = S.TaskPropertyTypeID
			WHEN MATCHED THEN
			UPDATE
			SET
				T.TaskPropertyTypeID = S.TaskPropertyTypeID
				,T.TaskPropertyValue = S.TaskPropertyValue
			WHEN NOT MATCHED BY TARGET THEN 
			INSERT
			(
				TaskPropertyTypeID
				,TaskID
				,TaskPropertyValue
			)
			VALUES
			(
				S.TaskPropertyTypeID
				,S.TaskID
				,S.TaskPropertyValue
			)
			;
			'

			-- Check if the task mappings exist

			SET @SelectString = ''

			SELECT
				@SelectString += 'SELECT @TaskID AS TaskID, ''' + FCM.SourceColumnName + ''' AS SourceColumnName,''' + FCM.TargetColumnName + ''' AS TargetColumnName,''' + FIDT.FileInterimDataTypeName + ''' AS FileInterimDataTypeName,' + CASE WHEN FCM.[DataLength] IS NULL THEN 'NULL' ELSE '''' + FCM.[DataLength] + '''' END + ' AS DataLength UNION ALL '
			FROM
				DI.Task T
				INNER JOIN DI.FileColumnMapping FCM ON T.TaskID = FCM.TaskID
				INNER JOIN DI.FileInterimDataType FIDT ON FCM.FileInterimDataTypeID = FIDT.FileInterimDataTypeID
			WHERE
				T.TaskID = @TaskID

			IF LEN(@SelectString) > 0

			BEGIN

				SET @SyncString += '
				MERGE
					DI.FileColumnMapping T
				USING
					(
						SELECT FCM.*,FIDT.FileInterimDataTypeID FROM (' + LEFT(@SelectString, LEN(@SelectString) - 10) + ') FCM INNER JOIN DI.FileInterimDataType FIDT ON FCM.FileInterimDataTypeName = FIDT.FileInterimDataTypeName
					) S ON T.TaskID = S.TaskID
						AND T.SourceColumnName = S.SourceColumnName
				WHEN MATCHED THEN
				UPDATE
				SET
					T.TargetColumnName = S.TargetColumnName
					,T.FileInterimDataTypeID = S.FileInterimDataTypeID
					,T.[DataLength] = S.[DataLength]
				WHEN NOT MATCHED BY TARGET THEN 
				INSERT
				(
					TaskID
					,SourceColumnName
					,TargetColumnName
					,FileInterimDataTypeID
					,[DataLength]
				)
				VALUES
				(
					S.TaskID
					,S.SourceColumnName
					,S.TargetColumnName
					,S.FileInterimDataTypeID
					,S.[DataLength]
				)
				;
				'

			END

			SET @SyncString += '
				PRINT(''Task ' + @TaskName + ' sync completed'')
				'

			FETCH NEXT FROM Task_Cursor INTO @TaskID

			END

			CLOSE Task_Cursor
			DEALLOCATE Task_Cursor

	END

	ELSE

	BEGIN

		-- Check if the schedule interval exists

		SET @SyncString += '
		PRINT(''Starting task ' + @TaskName + ' sync'')
		'

		SELECT
			@SelectString = 'SELECT ''' + SI.ScheduleIntervalName + ''' AS ScheduleIntervalName,' + CASE WHEN SI.ScheduleIntervalDescription IS NULL THEN 'NULL' ELSE '''' + SI.ScheduleIntervalDescription + '''' END + ' AS ScheduleIntervalDescription'
		FROM
			DI.Task T
			INNER JOIN DI.Schedule S ON T.ScheduleID = S.ScheduleID
			INNER JOIN DI.ScheduleInterval SI ON S.ScheduleIntervalID = SI.ScheduleIntervalID
		WHERE
			T.TaskID = @TaskID

		SET @SyncString += '
		DELETE FROM @ScheduleInterval

		MERGE
			DI.ScheduleInterval T
		USING
			(
				' + @SelectString + '
			) S ON T.ScheduleIntervalName = S.ScheduleIntervalName
		WHEN MATCHED THEN
		UPDATE
		SET
			T.ScheduleIntervalDescription = S.ScheduleIntervalDescription
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT
		(
				ScheduleIntervalName
				,ScheduleIntervalDescription
		)
		VALUES
		(
			S.ScheduleIntervalName
			,S.ScheduleIntervalDescription
		)
		OUTPUT 
			ISNULL([INSERTED].ScheduleIntervalID, [DELETED].ScheduleIntervalID) 
		INTO 
			@ScheduleInterval
		;
		'

		-- Check if the schedule exists

		SELECT
			@SelectString = 'SELECT ''' + S.ScheduleName + ''' AS ScheduleName,' + CASE WHEN S.ScheduleDescription IS NULL THEN 'NULL' ELSE '''' + S.ScheduleDescription + '''' END + ' AS ScheduleDescription,ScheduleIntervalID,' + CAST(S.Frequency AS VARCHAR(50)) + ' AS Frequency,''' + FORMAT(S.StartDate, 'yyyy-MM-dd HH:mm:ss') + ''' AS StartDate FROM @ScheduleInterval'
		FROM
			DI.Task T
			INNER JOIN DI.Schedule S ON T.ScheduleID = S.ScheduleID
		WHERE
			T.TaskID = @TaskID

		SET @SyncString += '
		DELETE FROM @Schedule

		MERGE
			DI.Schedule T
		USING
			(
				' + @SelectString + '
			) S ON T.ScheduleName = S.ScheduleName
		WHEN MATCHED THEN
		UPDATE
		SET
			T.ScheduleDescription = S.ScheduleDescription
			,T.ScheduleIntervalID = S.ScheduleIntervalID
			,T.Frequency = S.Frequency
			,T.StartDate = S.StartDate
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT
		(
			ScheduleName
			,ScheduleDescription
			,ScheduleIntervalID
			,Frequency
			,StartDate
		)
		VALUES
		(
			S.ScheduleName
			,S.ScheduleDescription
			,S.ScheduleIntervalID
			,S.Frequency
			,S.StartDate
		)
		OUTPUT 
			ISNULL([INSERTED].ScheduleID, [DELETED].ScheduleID) 
		INTO 
			@Schedule
		;
		SELECT @ScheduleID = ScheduleID FROM @Schedule
		'

		-- Check if the task type exists

		SELECT
			@SelectString = 'SELECT ''' + TT.TaskTypeName + ''' AS TaskTypeName,' + CASE WHEN TT.TaskTypeDescription IS NULL THEN 'NULL' ELSE '''' + TT.TaskTypeDescription + '''' END + ' AS TaskTypeDescription,' + ISNULL(CAST(TT.ScriptIndicator AS VARCHAR(50)), 'NULL') + ' AS ScriptIndicator,' + CAST(TT.FileLoadIndicator AS VARCHAR(50)) + ' AS FileLoadIndicator,' + CAST(TT.DatabaseLoadIndicator AS VARCHAR(50)) + ' AS DatabaseLoadIndicator,''' + TT.RunType + ''' AS RunType'
		FROM
			DI.Task T
			INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
		WHERE
			T.TaskID = @TaskID

		SET @SyncString += '
		DELETE FROM @TaskType

		MERGE
			DI.TaskType T
		USING
			(
				' + @SelectString + '
			) S ON T.TaskTypeName = S.TaskTypeName
		WHEN MATCHED THEN
		UPDATE
		SET
			T.TaskTypeDescription = S.TaskTypeDescription
			,T.ScriptIndicator = S.ScriptIndicator
			,T.FileLoadIndicator = S.FileLoadIndicator
			,T.DatabaseLoadIndicator = S.DatabaseLoadIndicator
			,T.RunType = S.RunType
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT
		(
			TaskTypeName
			,TaskTypeDescription
			,ScriptIndicator
			,FileLoadIndicator
			,DatabaseLoadIndicator
			,RunType
		)
		VALUES
		(
			S.TaskTypeName
			,S.TaskTypeDescription
			,S.ScriptIndicator
			,S.FileLoadIndicator
			,S.DatabaseLoadIndicator
			,S.RunType
		)
		OUTPUT 
			ISNULL([INSERTED].TaskTypeID, [DELETED].TaskTypeID) 
		INTO 
			@TaskType
		;
		SELECT @TaskTypeID = TaskTypeID FROM @TaskType
		'

		-- Check if the connections exist

		SELECT
			@SelectString = 'SELECT ''Source'' AS ConnectionType, ''' + C.ConnectionName + ''' AS ConnectionName,' + CASE WHEN C.ConnectionDescription IS NULL THEN 'NULL' ELSE '''' + C.ConnectionDescription + '''' END + ' AS ConnectionDescription,''' + CT.ConnectionTypeName + ''' AS ConnectionTypeName,''' + [AT].AuthenticationTypeName + ''' AS AuthenticationTypeName'
		FROM
			DI.Task T
			INNER JOIN DI.[Connection] C ON T.SourceConnectionID = C.ConnectionID
			INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
			INNER JOIN DI.AuthenticationType [AT] ON C.AuthenticationTypeID = [AT].AuthenticationTypeID
		WHERE
			T.TaskID = @TaskID

		SELECT
			@SelectString += ' UNION ALL SELECT ''ETL'' AS ConnectionType, ''' + C.ConnectionName + ''' AS ConnectionName,' + CASE WHEN C.ConnectionDescription IS NULL THEN 'NULL' ELSE '''' + C.ConnectionDescription + '''' END + ' AS ConnectionDescription,''' + CT.ConnectionTypeName + ''' AS ConnectionTypeName,''' + [AT].AuthenticationTypeName + ''' AS AuthenticationTypeName'
		FROM
			DI.Task T
			INNER JOIN DI.[Connection] C ON T.ETLConnectionID = C.ConnectionID
			INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
			INNER JOIN DI.AuthenticationType [AT] ON C.AuthenticationTypeID = [AT].AuthenticationTypeID
		WHERE
			T.TaskID = @TaskID

		SELECT
			@SelectString += ' UNION ALL SELECT ''Stage'' AS ConnectionType, ''' + C.ConnectionName + ''' AS ConnectionName,' + CASE WHEN C.ConnectionDescription IS NULL THEN 'NULL' ELSE '''' + C.ConnectionDescription + '''' END + ' AS ConnectionDescription,''' + CT.ConnectionTypeName + ''' AS ConnectionTypeName,''' + [AT].AuthenticationTypeName + ''' AS AuthenticationTypeName'
		FROM
			DI.Task T
			INNER JOIN DI.[Connection] C ON T.StageConnectionID = C.ConnectionID
			INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
			INNER JOIN DI.AuthenticationType [AT] ON C.AuthenticationTypeID = [AT].AuthenticationTypeID
		WHERE
			T.TaskID = @TaskID

		SELECT
			@SelectString += ' UNION ALL SELECT ''Target'' AS ConnectionType, ''' + C.ConnectionName + ''' AS ConnectionName,' + CASE WHEN C.ConnectionDescription IS NULL THEN 'NULL' ELSE '''' + C.ConnectionDescription + '''' END + ' AS ConnectionDescription,''' + CT.ConnectionTypeName + ''' AS ConnectionTypeName,''' + [AT].AuthenticationTypeName + ''' AS AuthenticationTypeName'
		FROM
			DI.Task T
			INNER JOIN DI.[Connection] C ON T.TargetConnectionID = C.ConnectionID
			INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
			INNER JOIN DI.AuthenticationType [AT] ON C.AuthenticationTypeID = [AT].AuthenticationTypeID
		WHERE
			T.TaskID = @TaskID

		SET @SyncString += '
		DELETE FROM @Connection

		MERGE
			DI.Connection T
		USING
			(
			SELECT DISTINCT
				ConnectionName
				,ConnectionDescription
				,CT.ConnectionTypeID
				,[AT].AuthenticationTypeID
			FROM
				(
					' + @SelectString + '
				) tmp 
				INNER JOIN DI.ConnectionType CT ON tmp.ConnectionTypeName = CT.ConnectionTypeName
					AND CT.DeletedIndicator = 0
				INNER JOIN DI.AuthenticationType [AT] ON tmp.AuthenticationTypeName = [AT].AuthenticationTypeName
					AND [AT].DeletedIndicator = 0
			) S ON T.ConnectionName = S.ConnectionName
		WHEN MATCHED THEN
		UPDATE
		SET
			T.ConnectionDescription = S.ConnectionDescription
			,T.ConnectionTypeID = S.ConnectionTypeID
			,T.AuthenticationTypeID = S.AuthenticationTypeID
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT
		(
			ConnectionName
			,ConnectionDescription
			,ConnectionTypeID
			,AuthenticationTypeID
		)
		VALUES
		(
			S.ConnectionName
			,S.ConnectionDescription
			,S.ConnectionTypeID
			,S.AuthenticationTypeID
		)
		OUTPUT 
			ISNULL([INSERTED].ConnectionID, [DELETED].ConnectionID)
			,ISNULL([INSERTED].ConnectionName, [DELETED].ConnectionName)
		INTO 
			@Connection
		;

		SELECT @SourceConnectionID = ConnectionID FROM (' + @SelectString + ') S INNER JOIN DI.Connection C ON S.ConnectionName = C.ConnectionName AND C.DeletedIndicator = 0 AND S.ConnectionType = ''Source''
		SELECT @ETLConnectionID = ConnectionID FROM (' + @SelectString + ') S INNER JOIN DI.Connection C ON S.ConnectionName = C.ConnectionName AND C.DeletedIndicator = 0 AND ConnectionType = ''ETL''
		SELECT @StageConnectionID = ConnectionID FROM (' + @SelectString + ') S INNER JOIN DI.Connection C ON S.ConnectionName = C.ConnectionName AND C.DeletedIndicator = 0 AND ConnectionType = ''Stage''
		SELECT @TargetConnectionID = ConnectionID FROM (' + @SelectString + ') S INNER JOIN DI.Connection C ON S.ConnectionName = C.ConnectionName AND C.DeletedIndicator = 0 AND ConnectionType = ''Target''

		'

		-- Check if the task exists

		SELECT
			@SelectString = 'SELECT ''' + T.TaskName + ''' AS TaskName,' + CASE WHEN T.TaskDescription IS NULL THEN 'NULL' ELSE '''' + T.TaskDescription + '''' END + ' AS TaskDescription,@SystemID AS SystemID,@ScheduleID AS ScheduleID,@TaskTypeID AS TaskTypeID,@SourceConnectionID AS SourceConnectionID,@ETLConnectionID AS ETLConnectionID,@StageConnectionID AS StageConnectionID,@TargetConnectionID AS TargetConnectionID,' + ISNULL(CAST(T.TaskOrderID AS VARCHAR(50)), 'NULL') + ' AS TaskOrderID'
		FROM
			DI.Task T
			INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
		WHERE
			T.TaskID = @TaskID

		SET @SyncString += '
		DELETE FROM @Task
		;

		MERGE
			DI.Task T
		USING
			(
				' + @SelectString + '
			) S ON T.TaskName = S.TaskName
				AND T.SystemID = S.SystemID
		WHEN MATCHED THEN
		UPDATE
		SET
			T.TaskDescription = S.TaskDescription
			,T.ScheduleID = S.ScheduleID
			,T.TaskTypeID = S.TaskTypeID
			,T.SourceConnectionID = S.SourceConnectionID
			,T.ETLConnectionID = S.ETLConnectionID
			,T.StageConnectionID = S.StageConnectionID
			,T.TargetConnectionID = S.TargetConnectionID
			,T.TaskOrderID = S.TaskOrderID
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT
		(
			TaskName
			,TaskDescription
			,SystemID
			,ScheduleID
			,TaskTypeID
			,SourceConnectionID
			,ETLConnectionID
			,StageConnectionID
			,TargetConnectionID
			,TaskOrderID
		)
		VALUES
		(
			S.TaskName
			,S.TaskDescription
			,S.SystemID
			,S.ScheduleID
			,S.TaskTypeID
			,S.SourceConnectionID
			,S.ETLConnectionID
			,S.StageConnectionID
			,S.TargetConnectionID
			,S.TaskOrderID
		)
		OUTPUT 
			ISNULL([INSERTED].TasKID, [DELETED].TaskID) 
		INTO 
			@Task
		;
		SELECT @TaskID = TaskID FROM @Task
		'

		-- Check if the task properties exist

		SET @SelectString = ''

		SELECT
			@SelectString += 'SELECT @TaskID AS TaskID, ''' + TPT.TaskPropertyTypeName + ''' AS TaskPropertyTypeName,''' + REPLACE(TP.TaskPropertyValue, CHAR(39), '''''') + ''' AS TaskPropertyValue UNION ALL '
		FROM
			DI.Task T
			INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
			INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
		WHERE
			T.TaskID = @TaskID

		SET @SyncString += '
		MERGE
			DI.TaskProperty T
		USING
			(
				SELECT 
					TP.*
					,TPT.TaskPropertyTypeID 
				FROM 
					(' + LEFT(@SelectString, LEN(@SelectString) - 10) + ') TP 
					INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeName = TPT.TaskPropertyTypeName
			) S ON T.TaskID = S.TaskID
				AND T.TaskPropertyTypeID = S.TaskPropertyTypeID
		WHEN MATCHED THEN
		UPDATE
		SET
			T.TaskPropertyTypeID = S.TaskPropertyTypeID
			,T.TaskPropertyValue = S.TaskPropertyValue
		WHEN NOT MATCHED BY TARGET THEN 
		INSERT
		(
			TaskPropertyTypeID
			,TaskID
			,TaskPropertyValue
		)
		VALUES
		(
			S.TaskPropertyTypeID
			,S.TaskID
			,S.TaskPropertyValue
		)
		;
		'

		-- Check if the task mappings exist

		SET @SelectString = ''

		SELECT
			@SelectString += 'SELECT @TaskID AS TaskID, ''' + FCM.SourceColumnName + ''' AS SourceColumnName,''' + FCM.TargetColumnName + ''' AS TargetColumnName,''' + FIDT.FileInterimDataTypeName + ''' AS FileInterimDataTypeName,' + CASE WHEN FCM.[DataLength] IS NULL THEN 'NULL' ELSE '''' + FCM.[DataLength] + '''' END + ' AS DataLength UNION ALL '
		FROM
			DI.Task T
			INNER JOIN DI.FileColumnMapping FCM ON T.TaskID = FCM.TaskID
			INNER JOIN DI.FileInterimDataType FIDT ON FCM.FileInterimDataTypeID = FIDT.FileInterimDataTypeID
		WHERE
			T.TaskID = @TaskID

		IF LEN(@SelectString) > 0

		BEGIN

			SET @SyncString += '
			MERGE
				DI.FileColumnMapping T
			USING
				(
					SELECT FCM.*,FIDT.FileInterimDataTypeID FROM (' + LEFT(@SelectString, LEN(@SelectString) - 10) + ') FCM INNER JOIN DI.FileInterimDataType FIDT ON FCM.FileInterimDataTypeName = FIDT.FileInterimDataTypeName
				) S ON T.TaskID = S.TaskID
					AND T.SourceColumnName = S.SourceColumnName
			WHEN MATCHED THEN
			UPDATE
			SET
				T.TargetColumnName = S.TargetColumnName
				,T.FileInterimDataTypeID = S.FileInterimDataTypeID
				,T.[DataLength] = S.[DataLength]
			WHEN NOT MATCHED BY TARGET THEN 
			INSERT
			(
				TaskID
				,SourceColumnName
				,TargetColumnName
				,FileInterimDataTypeID
				,[DataLength]
			)
			VALUES
			(
				S.TaskID
				,S.SourceColumnName
				,S.TargetColumnName
				,S.FileInterimDataTypeID
				,S.[DataLength]
			)
			;
			'

		END

		SET @SyncString += '
			PRINT(''Task ' + @TaskName + ' sync completed'')
			'
	END

	SET @SyncString += '
		COMMIT TRANSACTION
	END TRY
		
	BEGIN CATCH
		
		ROLLBACK TRANSACTION

		DECLARE @Error VARCHAR(MAX)
		SET @Error = ERROR_MESSAGE()
		;
		THROW 51000, @Error, 1 
	END CATCH'

	SELECT
		@SyncString AS Script

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
