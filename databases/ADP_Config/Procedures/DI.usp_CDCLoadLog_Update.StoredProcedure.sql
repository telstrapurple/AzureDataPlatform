/****** Object:  StoredProcedure [DI].[usp_CDCLoadLog_Update]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_CDCLoadLog_Update]
GO
/****** Object:  StoredProcedure [DI].[usp_CDCLoadLog_Update]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [DI].[usp_CDCLoadLog_Update]
(
	@TaskInstanceID INT
)

AS

SET NOCOUNT ON

BEGIN TRY

		-- Update 
		UPDATE DI.CDCLoadLog 
		SET SuccessIndicator = 1 
		WHERE TaskInstanceID = @TaskInstanceID

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
