/****** Object:  StoredProcedure [DI].[usp_CDCLoadLog_Insert]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_CDCLoadLog_Insert]
GO
/****** Object:  StoredProcedure [DI].[usp_CDCLoadLog_Insert]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [DI].[usp_CDCLoadLog_Insert]
(
	@TaskInstanceID INT
	,@LatestLSNValue BINARY(10)
)

AS

SET NOCOUNT ON

BEGIN TRY

		-- Replace and insert 
		DELETE FROM DI.CDCLoadLog WHERE TaskInstanceID = @TaskInstanceID

		INSERT INTO DI.CDCLoadLog
		(
			TaskInstanceID,
			LatestLSNValue,
			SuccessIndicator
		)
		VALUES
		(
			@TaskInstanceID,
			@LatestLSNValue,
			0
		)

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
