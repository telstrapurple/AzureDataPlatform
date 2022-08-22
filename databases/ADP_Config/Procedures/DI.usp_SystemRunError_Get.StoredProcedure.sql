/****** Object:  StoredProcedure [DI].[usp_SystemRunError_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_SystemRunError_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_SystemRunError_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_SystemRunError_Get]
(
	@System VARCHAR(50)
	,@TaskType VARCHAR(50)
	,@ConfigPipelineName VARCHAR(100) = 'N/A'
)

AS

SET NOCOUNT ON

BEGIN TRY

	DECLARE 
		@ScheduleInstanceID INT
		,@SystemID INT
		,@PipelineRunID VARCHAR(50)

	-- Do the check for normal system errors

	IF ISNULL(@ConfigPipelineName, 'N/A') = 'N/A'

	BEGIN

		-- Get the latest schedule for the system

		SELECT 
			@ScheduleInstanceID = MAX(TI.ScheduleInstanceID)
			,@SystemID = MAX(S.SystemID)
		FROM 
			DI.Task T 
			INNER JOIN DI.TaskInstance TI ON T.TaskID = TI.TaskID
			INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
			INNER JOIN DI.[System] S ON T.SystemID = S.SystemID 
		WHERE 
			S.SystemName = @System
			AND TT.TaskTypeName = @TaskType

		-- Only get the first 100 errors

		-- Return a blank row to ADF if there are no errors

		IF NOT EXISTS (	SELECT 
							1 
						FROM DI.DataFactoryLog DFL
							INNER JOIN DI.TaskInstance TI ON DFL.TaskInstanceID = TI.TaskInstanceID
							INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
							INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
							INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
						WHERE
							DFL.LogType = 'Error'
							AND S.SystemName = @System
							AND TT.TaskTypeName = @TaskType
							AND TI.ScheduleInstanceID = @ScheduleInstanceID
							AND DFL.EmailSentIndicator = 0) 
		BEGIN
    
    		SELECT
				'' AS [Subject]
				,'' AS [Importance]
				,'' AS [Body]
				,@ScheduleInstanceID AS ScheduleInstanceID
				,@SystemID AS SystemID
				,'' AS PipelineRunID
    
		END

		ELSE

		BEGIN

			SELECT 
				Errors.[Subject]
			   ,Errors.[Importance]
			   ,'<html>
				<head>
				<style>
				table {
				  font-family: arial, sans-serif;
				  border-collapse: collapse;
				  width: 100%;
				}

				td, th {
				  border: 1px solid #dddddd;
				  text-align: left;
				  padding: 8px;
				}

				tr:nth-child(even) {
				  background-color: #dddddd;
				}
				</style>
				</head>
				<body>

				<h3>Error List - Top 100 most recent errors. Please see task log for additional errors</h3>
				<table>
				  <tr>
					<th>System</th>
					<th>Task</th>
					<th>Task Instance</th>
					<th>Date (UTC)</th>
					<th>Data Factory Name</th>
					<th>Pipeline Name</th>
					<th>Activity Name</th>' + 
					CASE
						WHEN MAX(LEN(Errors.[FileName])) > 0
						THEN '<th>Source File Name</th>'
						ELSE ''
					END + '
					<th>Error</th>
				  </tr>' + STRING_AGG('<tr><td>' + Errors.SystemName + '</td><td>' 
												 + Errors.TaskName + '</td><td>' 
												 + Errors.TaskInstanceID + '</td><td>' 
												 + Errors.ErrorDate + '</td><td>'
												 + Errors.DataFactoryName + '</td><td>'
												 + Errors.PipelineName + '</td><td>'
												 + Errors.ActivityName + '</td><td>'
												 +	CASE
														WHEN LEN(Errors.[FileName]) > 0
														THEN Errors.[FileName] + '</td><td>'
														ELSE ''
													END
												 + Errors.ErrorMessage + '</td></tr>'
									 , '') 
												 + '</table>' AS [Body]
				,@ScheduleInstanceID AS ScheduleInstanceID
				,@SystemID AS SystemID
				,'' AS PipelineRunID
			FROM 
				(
				SELECT
					'ADS Go Fast error log for System: ' + S.SystemName + ', Task Type: ' + TT.TaskTypeName AS [Subject]
					,'High' AS [Importance]
					,S.SystemName
					,T.TaskName
					,CAST(TI.TaskInstanceID AS VARCHAR(50)) AS TaskInstanceID 
					,CONVERT(VARCHAR(20), DFL.DateCreated, 113) AS ErrorDate
					,DFL.DataFactoryName
					,DFL.PipelineName
					,DFL.ActivityName
					,COALESCE(FLL.[FileName], '') AS [FileName]
					,REPLACE(DFL.ErrorMessage, '"', '''') AS ErrorMessage
					,ROW_NUMBER() OVER(ORDER BY DFL.DateCreated) AS RowID
				FROM
					DI.DataFactoryLog DFL
					INNER JOIN DI.TaskInstance TI ON DFL.TaskInstanceID = TI.TaskInstanceID
					INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
					INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
					INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
					LEFT OUTER JOIN DI.FileLoadLog FLL ON DFL.FileLoadLogID = FLL.FileLoadLogID
				WHERE
					DFL.LogType = 'Error'
					AND S.SystemName = @System
					AND TT.TaskTypeName = @TaskType
					AND TI.ScheduleInstanceID = @ScheduleInstanceID
					AND DFL.EmailSentIndicator = 0
				) Errors
			WHERE
				Errors.RowID <= 100
			GROUP BY 
				Errors.[Subject]
			   ,Errors.[Importance]

		END

	END

	ELSE

	BEGIN

		SELECT 
			@PipelineRunID = DFL.PipelineRunID
		FROM 
			DI.DataFactoryLog DFL
			INNER JOIN 
			(
			SELECT 
				DFL.PipelineRunID
				,ROW_NUMBER() OVER(ORDER BY DFL.DateCreated DESC) AS RowID
			FROM 
				DI.DataFactoryLog DFL
			WHERE
				DFL.TaskInstanceID IS NULL
				AND DFL.PipelineName = @ConfigPipelineName
			) LatestRun ON DFL.PipelineRunID = LatestRun.PipelineRunID
		WHERE
			LatestRun.RowID = 1

		-- Get the latest pipeline run id

		IF NOT EXISTS(	SELECT 
							1 
						FROM 
							DI.DataFactoryLog DFL
						WHERE
							DFL.PipelineRunID = @PipelineRunID
							AND DFL.LogType = 'Error'
							AND DFL.EmailSentIndicator = 0
					)
					
		BEGIN
			
			SELECT
				'' AS [Subject]
				,'' AS [Importance]
				,'' AS [Body]
				,0 AS ScheduleInstanceID
				,0 AS SystemID
				,'' AS PipelineRunID

		END

		ELSE

		BEGIN

			SELECT 
				Errors.[Subject]
			   ,Errors.[Importance]
			   ,'<html>
				<head>
				<style>
				table {
				  font-family: arial, sans-serif;
				  border-collapse: collapse;
				  width: 100%;
				}

				td, th {
				  border: 1px solid #dddddd;
				  text-align: left;
				  padding: 8px;
				}

				tr:nth-child(even) {
				  background-color: #dddddd;
				}
				</style>
				</head>
				<body>

				<h3>Error List - Top 100 most recent errors. Please see task log for additonal errors</h3>
				<table>
				  <tr>
					<th>Pipeline Name</th>
					<th>Pipeline Run ID</th>
					<th>Date (UTC)</th>
					<th>Data Factory Name</th>
					<th>Activity Name</th>
					<th>Error</th>
				  </tr>' + STRING_AGG('<tr><td>' + Errors.PipelineName + '</td><td>' 
												 + Errors.PipelineRunID + '</td><td>' 
												 + Errors.ErrorDate + '</td><td>'
												 + Errors.DataFactoryName + '</td><td>'
												 + Errors.ActivityName + '</td><td>'
												 + Errors.ErrorMessage + '</td></tr>'
									 , '') 
												 + '</table>' AS [Body]
				,0 AS ScheduleInstanceID
				,0 AS SystemID
				,@PipelineRunID AS PipelineRunID
			FROM 
				(
				SELECT
					'ADS Go Fast system errors encountered for config extract in pipeline ' + DFL.PipelineName AS [Subject]
					,'High' AS [Importance]
					,DFL.PipelineName
					,DFL.PipelineRunID
					,CONVERT(VARCHAR(20), DFL.DateCreated, 113) AS ErrorDate
					,DFL.DataFactoryName
					,DFL.ActivityName
					,REPLACE(DFL.ErrorMessage, '"', '''') AS ErrorMessage
					,ROW_NUMBER() OVER(ORDER BY DFL.DateCreated) AS RowID
				FROM
					DI.DataFactoryLog DFL
				WHERE
					DFL.PipelineRunID = @PipelineRunID
					AND DFL.LogType = 'Error'
					AND DFL.EmailSentIndicator = 0
				) Errors
			WHERE
				Errors.RowID <= 100
			GROUP BY 
				Errors.[Subject]
			   ,Errors.[Importance]

		END

	END

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
