/****** Object:  StoredProcedure [DI].[usp_SQLWhereClause_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_SQLWhereClause_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_SQLWhereClause_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [DI].[usp_SQLWhereClause_Get] (@TaskInstanceID INT)

AS

SET NOCOUNT ON

BEGIN TRY

	DECLARE  
		@TaskID INT
		,@IncrementalValue VARCHAR(100)
		,@IncrementalColumn VARCHAR(50)
		,@WhereClause VARCHAR(1000)
		,@RunType VARCHAR(50)

	--Get Task Id
	SELECT 
		@TaskID = TaskID 
	FROM
		DI.TaskInstance TI
	WHERE
		TI.TaskInstanceID = @TaskInstanceID

	--Check the task type

	SELECT 
		@RunType = TT.RunType
	FROM 
		DI.Task T 
		INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
	WHERE
		T.TaskID = @TaskID
	
	--Get Incremental Value

	IF @RunType LIKE 'Database to%'

	BEGIN
	
		SELECT @IncrementalValue = [DI].[udf_GetIncrementalLoadValue](@TaskInstanceID,'SQL')

	END

	ELSE

	BEGIN
	
		 SELECT @IncrementalValue = [DI].[udf_GetIncrementalLoadValue](@TaskInstanceID,'') 

	END

	--Get Increment Column 
	SELECT 
		@IncrementalColumn = TP.TaskPropertyValue
	FROM
		DI.Task T 
		INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
		INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
			AND TPT.TaskPropertyTypeName = 'Incremental Column'  
			AND T.TaskID = @TaskID
			
	SET @WhereClause = ' WHERE [' + @IncrementalColumn + '] >= ' + @IncrementalValue 

	SELECT 
		@WhereClause AS [WhereClause]

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1
END CATCH
GO
