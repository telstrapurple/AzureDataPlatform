/****** Object:  StoredProcedure [DI].[usp_TaskInstanceStatus_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_TaskInstanceStatus_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_TaskInstanceStatus_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [DI].[usp_TaskInstanceStatus_Get]
(
	@TaskInstanceID INT
)

AS

BEGIN TRY
	
	IF EXISTS ( 
		SELECT
			DFL.LogType,
			DFL.PipelineRunID
		FROM 
			DI.DataFactoryLog DFL
		WHERE
			DFL.TaskInstanceID = @TaskInstanceID
			AND DFL.DataFactoryLogID = (SELECT MAX(DFL.DataFactoryLogID) FROM DI.DataFactoryLog DFL WHERE DFL.TaskInstanceID = @TaskInstanceID) 
	)
	BEGIN
		SELECT
			DFL.LogType,
			DFL.PipelineRunID
		FROM 
			DI.DataFactoryLog DFL
		WHERE
			DFL.TaskInstanceID = @TaskInstanceID
			AND DFL.DataFactoryLogID = (SELECT MAX(DFL.DataFactoryLogID) FROM DI.DataFactoryLog DFL WHERE DFL.TaskInstanceID = @TaskInstanceID) 
	END

	ELSE 

	BEGIN
		SELECT
			NULL AS LogType,
			'00000000-0000-0000-0000-000000000000' AS PipelineRunID
	END
	


END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
