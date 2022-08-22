/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Task_Update]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_FileLoadLog_Task_Update]
GO
/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Task_Update]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [DI].[usp_FileLoadLog_Task_Update]
(
	@TaskID INT,
	@SuccessIndicator BIT
)

AS

SET NOCOUNT ON

BEGIN TRY
		
		-- Update FileLoadLog
		UPDATE 
			DI.FileLoadLog 
		SET SuccessIndicator = @SuccessIndicator
		FROM 
			DI.FileLoadLog FLL INNER JOIN 
			DI.TaskInstance TI ON FLL.TaskInstanceID = TI.TaskInstanceID
		WHERE 
			TI.TaskID = @TaskID
			AND 
			FLL.DeletedIndicator = 0
		-- Return 1 
		SELECT 'Success'

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
