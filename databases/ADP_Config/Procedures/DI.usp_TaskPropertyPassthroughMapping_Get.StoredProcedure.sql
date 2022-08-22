/****** Object:  StoredProcedure [DI].[usp_TaskPropertyPassthroughMapping_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_TaskPropertyPassthroughMapping_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_TaskPropertyPassthroughMapping_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_TaskPropertyPassthroughMapping_Get]
(
	@TaskID INT
)

AS

SET NOCOUNT ON

BEGIN TRY
	
	-- Declare output variable 
	DECLARE 
		@Output AS NVARCHAR(MAX) = '[]'
		,@TaskList NVARCHAR(MAX) = ''

	-- Get the latest info fro mthe Data Factory Log

	DROP TABLE IF EXISTS #DFLog

	SELECT
		MAX(TIPrevious.TaskInstanceID) AS LatestTaskInstanceID
		,MAX(DFL.DataFactoryLogID) AS LatestDataFactoryLogID
		,T.TaskID
	INTO
		#DFLog
	FROM
		[DI].[DataFactoryLog] DFL
		INNER JOIN DI.TaskInstance TI ON DFL.TaskInstanceID = TI.TaskInstanceID
		INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
		INNER JOIN DI.TaskInstance TIPrevious ON T.TaskID = TIPrevious.TaskID
		INNER JOIN DI.TaskResult TR ON TIPrevious.TaskResultID = TR.TaskResultID
		INNER JOIN [DI].[TaskPropertyPassthroughMapping] TPass ON T.TaskID = TPass.TaskPassthroughID	
	WHERE
		TPass.TaskID = @TaskID
		AND TR.TaskResultName = 'Success'
		AND DFL.LogType = 'End'
	GROUP BY 
		T.TaskID

	SELECT
		@Output = '[' + STRING_AGG('{"TaskID":"' + CAST(TI.TaskID AS VARCHAR(255)) +  '", "TaskName":"' +  T.TaskName +  '","TaskProperty":' + DFL.OutputMessage + '}', ',') + ']'
	FROM
		[DI].[DataFactoryLog] DFL
		INNER JOIN DI.TaskInstance TI ON DFL.TaskInstanceID = TI.TaskInstanceID
		INNER JOIN #DFLog DFLog ON DFL.DataFactoryLogID = DFLog.LatestDataFactoryLogID
		INNER JOIN DI.Task T ON T.TaskID = TI.TaskID

	-- check if any of the tasks have never executed successfully

	SELECT
		@TaskList = STRING_AGG(T.TaskPassthroughID, ',')
	FROM
		(
		SELECT
			TaskPassthroughID
		FROM
			[DI].[TaskPropertyPassthroughMapping]
		WHERE
			TaskID = @TaskID

		EXCEPT

		SELECT
			TaskID
		FROM
			#DFLog
		) T

	-- Raise an error message if some of the tasks have never executed successfully

	IF @TaskList <> ''

	BEGIN
		
		DECLARE @ErrorMessage VARCHAR(MAX);
		SET @ErrorMessage = 'The following dependent Task IDs have not been run: ' + @TaskList
		RAISERROR (@ErrorMessage,11,1);

	END

	-- Select the output
	SELECT 
		@Output AS [output]

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
