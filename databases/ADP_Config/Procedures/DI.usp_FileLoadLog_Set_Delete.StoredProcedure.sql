/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Set_Delete]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_FileLoadLog_Set_Delete]
GO
/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Set_Delete]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [DI].[usp_FileLoadLog_Set_Delete]
(
	@TaskInstanceID INT
)

AS

SET NOCOUNT ON

BEGIN TRY
		-- Get TaskID
		DECLARE @TaskID INT; 
		SET @TaskID = 
		(
			SELECT 
				MAX(TI.TaskID)
			FROM 
				DI.TaskInstance TI
			WHERE 
				TI.TaskInstanceID = @TaskInstanceID
		)

		UPDATE DI.FileLoadLog
		SET DeletedIndicator = 1
		FROM 
			DI.FileLoadLog FLL
			INNER JOIN 
			DI.TaskInstance TI
			ON FLL.TaskInstanceID = TI.TaskInstanceID
		WHERE 
			TI.TaskID = @TaskID
		
		SELECT 'Success' 

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
