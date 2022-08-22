/****** Object:  StoredProcedure [DI].[usp_CDC_LSN_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_CDC_LSN_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_CDC_LSN_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   PROCEDURE [DI].[usp_CDC_LSN_Get]
(
	@TaskInstanceID INT
)

AS

SET NOCOUNT ON

BEGIN TRY

	DECLARE @TaskID AS INT;

	-- Get Task ID
	SET @TaskID = (SELECT TOP 1 TaskID FROM DI.TaskInstance TI WHERE TI.TaskInstanceID = @TaskInstanceID)

	-- Get Latest LSN
	SELECT 
		CONVERT( VARCHAR(MAX), MAX(CDC.LatestLSNValue), 1 ) AS LatestLSNValue
	FROM
		DI.CDCLoadLog CDC INNER JOIN DI.TaskInstance TI ON CDC.TaskInstanceID = TI.TaskInstanceID
		INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
	WHERE 
		T.TaskID = @TaskID
		AND CDC.SuccessIndicator = 1
		AND CDC.DeletedIndicator = 0
		
END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
