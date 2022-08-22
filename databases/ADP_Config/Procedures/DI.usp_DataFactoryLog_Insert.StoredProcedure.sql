/****** Object:  StoredProcedure [DI].[usp_DataFactoryLog_Insert]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_DataFactoryLog_Insert]
GO
/****** Object:  StoredProcedure [DI].[usp_DataFactoryLog_Insert]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_DataFactoryLog_Insert]
(
	@TaskInstanceID INT = NULL
	,@LogType VARCHAR(50) = 'Start'
	,@DataFactoryName VARCHAR(50) 
	,@PipelineName VARCHAR(100)
	,@PipelineRunID VARCHAR(100)
	,@PipelineTriggerID VARCHAR(100)
	,@PipelineTriggerName VARCHAR(100)
	,@PipelineTriggerTime VARCHAR(100)
	,@PipelineTriggerType VARCHAR(100)
	,@ActivityName VARCHAR(100)
	,@OutputMessage NVARCHAR(MAX)
	,@ErrorMessage NVARCHAR(MAX)
	,@FileLoadLogID INT = NULL
)

AS

BEGIN TRY

	INSERT INTO DI.DataFactoryLog
	(
		[TaskInstanceID]
		,[LogType]
		,[DataFactoryName]
		,[PipelineName]
		,[PipelineRunID]
		,[PipelineTriggerID]
		,[PipelineTriggerName]
		,[PipelineTriggerTime]
		,[PipelineTriggerType]
		,[ActivityName]
		,[OutputMessage]
		,[ErrorMessage]
		,[FileLoadLogID]
	)
	SELECT 
		@TaskInstanceID
		,@LogType
		,@DataFactoryName
		,@PipelineName
		,@PipelineRunID
		,@PipelineTriggerID
		,@PipelineTriggerName
		,@PipelineTriggerTime
		,@PipelineTriggerType
		,@ActivityName
		,@OutputMessage
		,@ErrorMessage
		,@FileLoadLogID

	IF @LogType = 'End'

	BEGIN

		--Set the TaskInstance result to Success

		UPDATE
			DI.TaskInstance
		SET
			TaskResultID = (SELECT TR.TaskResultID FROM DI.TaskResult TR WHERE TR.TaskResultName = 'Success')
			,DateModified = SYSUTCDATETIME()
		WHERE
			TaskInstanceID = @TaskInstanceID

	END

	ELSE IF @LogType = 'Error'

	BEGIN

		--Set the TaskInstance result to Success

		UPDATE
			DI.TaskInstance
		SET
			TaskResultID = (SELECT TR.TaskResultID FROM DI.TaskResult TR WHERE TR.TaskResultName = 'Failure - Retry')
			,DateModified = SYSUTCDATETIME()
		WHERE
			TaskInstanceID = @TaskInstanceID

		-- Throw Error 
		DECLARE @Error VARCHAR(MAX)
		SET @Error = 'Activity Run has failed. Pipeline Name: ' + @PipelineName + ' Activity Name: ' + @ActivityName + '.'
		;
		THROW 51000, @Error, 1 

	END

	SELECT 
		IDENT_CURRENT('DI.DataFactoryLog') AS DataFactoryLogID

END TRY

BEGIN CATCH

	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
