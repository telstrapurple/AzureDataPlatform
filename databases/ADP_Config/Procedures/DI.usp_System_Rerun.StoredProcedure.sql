/****** Object:  StoredProcedure [DI].[usp_System_Rerun]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_System_Rerun]
GO
/****** Object:  StoredProcedure [DI].[usp_System_Rerun]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_System_Rerun]
(
	@System VARCHAR(100)
	,@TaskType VARCHAR(100)
)

AS

SET NOCOUNT ON

BEGIN TRY

	UPDATE
		TI
	SET
		TI.TaskResultID = (SELECT TR.TaskResultID FROM DI.TaskResult TR WHERE TR.TaskResultName = 'Failure - Retry')
	FROM
		DI.TaskInstance TI
		INNER JOIN 
		(
		SELECT
			T.TaskID
			,MAX(TI.TaskInstanceID) AS TaskInstanceID
		FROM
			DI.Task T
			INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
			INNER JOIN DI.TaskInstance TI ON T.TaskID = TI.TaskID
			INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
			INNER JOIN DI.TaskResult TR ON TI.TaskResultID = TR.TaskResultID
		WHERE
			S.SystemName = @System
			AND TT.TaskTypeName = @TaskType
			AND T.EnabledIndicator = 1
			AND TR.TaskResultName = 'Success'
		GROUP BY 
			T.TaskID
		) LatestRI ON TI.TaskInstanceID = LatestRI.TaskInstanceID

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
