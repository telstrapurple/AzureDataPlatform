/****** Object:  StoredProcedure [DI].[usp_SystemRunErrorLog_Update]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_SystemRunErrorLog_Update]
GO
/****** Object:  StoredProcedure [DI].[usp_SystemRunErrorLog_Update]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_SystemRunErrorLog_Update]
(
	@ScheduleInstanceID INT
	,@SystemID INT
	,@PipelineRunID VARCHAR(50) = ''
)

AS

SET NOCOUNT ON

BEGIN TRY

	-- Update the log to indicate that the email has been sent

	UPDATE
		DFL
	SET
		EmailSentIndicator = 1
	FROM 
		DI.DataFactoryLog DFL
		LEFT OUTER JOIN DI.TaskInstance TI ON DFL.TaskInstanceID = TI.TaskInstanceID
		LEFT OUTER JOIN DI.Task T ON TI.TaskID = T.TaskID
	WHERE
		DFL.LogType = 'Error'
		AND ((T.SystemID = @SystemID AND TI.ScheduleInstanceID = @ScheduleInstanceID)
		 OR (@SystemID = 0 AND DFL.PipelineRunID = @PipelineRunID))

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
