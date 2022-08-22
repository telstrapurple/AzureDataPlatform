/****** Object:  StoredProcedure [DI].[usp_DeltaSQL_Get]    Script Date: 1/11/2021 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_DeltaSQL_Get] 
GO
/****** Object:  StoredProcedure [DI].[usp_DeltaSQL_Get]    Script Date: 1/12/2021 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE    PROCEDURE [DI].[usp_DeltaSQL_Get] (@TaskInstanceID INT)

AS

SET NOCOUNT ON

BEGIN TRY

	DECLARE 
		@TaskID INT
		,@IncrColFormat VARCHAR(500)
		,@Format VARCHAR
		,@IncrementalValue VARCHAR(100)
		,@TaskLoadType VARCHAR(500)
		,@SourceColumnList VARCHAR(MAX)
		,@ODBCConnectionType VARCHAR(50)
		,@ColumnDelimiter CHAR(1) = '"'
		

	SELECT 
		@TaskID = TaskID 
	FROM
		DI.TaskInstance TI
	WHERE
		TI.TaskInstanceID = @TaskInstanceID

	SELECT  
		@TaskLoadType = TaskPropertyValue 
	FROM
		[DI].[TaskProperty] TP
		INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
	WHERE
		TP.TaskID = @TaskID
		AND TPT.TaskPropertyTypeName = 'Task Load Type'
		AND TP.DeletedIndicator = 0

	SELECT
	--	A.singh 03/02/2022 --
	--  DevOps Task: 58654 Applied fix to cast column as a larger object type --

	--	@SourceColumnList = STRING_AGG(@ColumnDelimiter + FCM.SourceColumnName + @ColumnDelimiter, ',')
		@SourceColumnList = STRING_AGG(@ColumnDelimiter + CAST(FCM.SourceColumnName AS VARCHAR(MAX)) + @ColumnDelimiter, ',')
		
	FROM
		[DI].[FileColumnMapping] FCM
	WHERE
		FCM.TaskID = @TaskID
		AND FCM.DeletedIndicator = 0

	IF @TaskLoadType = 'Full'

	BEGIN

		SELECT 
			MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Source Table' THEN 'SELECT ' + @SourceColumnList + ' FROM ' + TP.TaskPropertyValue WHEN TPT.TaskPropertyTypeName = 'SQL Command' THEN TP.TaskPropertyValue END) AS Result
		FROM 
			[DI].[TaskProperty] TP
			INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
		WHERE
			TP.TaskID = @TaskID
			AND TP.DeletedIndicator = 0

	END

	ELSE IF @TaskLoadType = 'Incremental'

	BEGIN

		SELECT  
			@IncrColFormat = TaskPropertyValue 
		FROM
			[DI].[TaskProperty] TP
			INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
		WHERE
			TP.TaskID = @TaskID
			AND TPT.TaskPropertyTypeName = 'Incremental Column Format'
			AND TP.DeletedIndicator = 0

		-- Raise an error if no format has been specified

		IF ISNULL(@IncrColFormat, '') = ''

		BEGIN

			;
			THROW 51000, 'Make sure to capture an incremental column format in the task properties', 1 

		END

		SELECT 
			@Format =
			CASE 
				WHEN @IncrColFormat LIKE '#%' 
				THEN '#'
				ELSE ''''
			END

		-- Get the latest incremental value

		SELECT @IncrementalValue = REPLACE([DI].[udf_GetIncrementalLoadValue] (@TaskInstanceID, 'ODBC'), CHAR(39), '')

		-- Format the incremental value based on the date format specified

		SELECT
			@IncrementalValue = 
								CASE
									WHEN @IncrColFormat LIKE '%dd%'
									THEN FORMAT(CAST(@IncrementalValue AS DATE), REPLACE(@IncrColFormat, '#', ''))
									WHEN @IncrColFormat = 'Number'
									THEN CAST(CAST(CAST(@IncrementalValue AS float) as INT) AS VARCHAR(100))
								END

		SELECT
			MAX(SC.SQLCommand) AS Result


		FROM
			--Gets the Properties for the task Instance 
			(
			SELECT 
				MAX(
				CASE
					WHEN TPT.TaskPropertyTypeName = 'SQL Command'
					THEN REPLACE(REPLACE(REPLACE(RIGHT(TP.TaskPropertyValue, LEN(TP.TaskPropertyValue) - CHARINDEX('FROM ', TP.TaskPropertyValue) - 4), '"', ''), '[', ''), ']', '')
					WHEN TPT.TaskPropertyTypeName = 'Source Table' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(TP.TaskPropertyValue, '"', ''), '[', ''), ']', ''))
				END) AS [TableName]
				,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Source Table' THEN 'SELECT ' + @SourceColumnList + ' FROM ' + TP.TaskPropertyValue WHEN TPT.TaskPropertyTypeName = 'SQL Command' THEN TP.TaskPropertyValue END) AS [SQLCommand]
				,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Incremental Column' THEN TP.TaskPropertyValue END) AS [IncrementalColumn]
				,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Task Load Type' THEN TP.TaskPropertyValue END) AS [TaskLoadType]
			FROM 
				[DI].[TaskProperty] TP
				INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
			WHERE
				TP.TaskID = @TaskID
				AND TP.DeletedIndicator = 0
			) Props
			CROSS APPLY
			(
			SELECT
				CASE
					-- There is a where clause and a group by clause
					WHEN [Props].[SQLCommand] LIKE '%WHERE%' AND [Props].[SQLCommand] LIKE '%GROUP BY%'
					THEN LEFT([Props].[SQLCommand], CHARINDEX('GROUP BY', [Props].[SQLCommand]) - 1) + ' AND (' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' >= ' + @Format +	
						CASE
							WHEN @IncrementalValue LIKE '%1900%' AND ISDATE(@IncrementalValue) = 1
							THEN @IncrementalValue + @Format + ' OR ' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' IS NULL'
							ELSE @IncrementalValue + @Format
						END + ')' + SUBSTRING([Props].[SQLCommand], CHARINDEX('GROUP BY', [Props].[SQLCommand]) - 1, LEN([Props].[SQLCommand]))
					-- There is a subquery and a where clause after the last closing bracket
					WHEN [Props].[SQLCommand] LIKE '%WHERE%' AND [Props].[SQLCommand] LIKE '%)%' AND REVERSE(LEFT(REVERSE([Props].[SQLCommand]), CHARINDEX(')', REVERSE([Props].[SQLCommand])))) LIKE '%WHERE%'
					THEN [Props].[SQLCommand] + ' AND (' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' >= ' + @Format +	
						CASE
							WHEN @IncrementalValue LIKE '%1900%' AND ISDATE(@IncrementalValue) = 1
							THEN @IncrementalValue + @Format + ' OR ' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' IS NULL'
							ELSE @IncrementalValue + @Format
						END + ')'
					-- There is a subquery and no where clause after the last closing bracket
					WHEN [Props].[SQLCommand] LIKE '%WHERE%' AND [Props].[SQLCommand] LIKE '%)%' AND REVERSE(LEFT(REVERSE([Props].[SQLCommand]), CHARINDEX(')', REVERSE([Props].[SQLCommand])))) NOT LIKE '%WHERE%'
					THEN [Props].[SQLCommand] + ' WHERE (' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' >= ' + @Format +	
						CASE
							WHEN @IncrementalValue LIKE '%1900%' AND ISDATE(@IncrementalValue) = 1
							THEN @IncrementalValue + @Format + ' OR ' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' IS NULL'
							ELSE @IncrementalValue + @Format
						END + ')'
					WHEN [Props].[SQLCommand] LIKE '%WHERE%'
					THEN [Props].[SQLCommand] + ' AND (' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' >= ' + @Format +	
						CASE
							WHEN @IncrementalValue LIKE '%1900%' AND ISDATE(@IncrementalValue) = 1
							THEN @IncrementalValue + @Format + ' OR ' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' IS NULL'
							ELSE @IncrementalValue + @Format
						END + ')'
					ELSE [Props].[SQLCommand] + ' WHERE ' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' >= ' + @Format +	
						CASE
							WHEN @IncrementalValue LIKE '%1900%' AND ISDATE(@IncrementalValue) = 1
							THEN @IncrementalValue + @Format + ' OR ' + @ColumnDelimiter + Props.[IncrementalColumn] + @ColumnDelimiter + ' IS NULL'
							ELSE @IncrementalValue + @Format
						END
				END AS [SQLCommand]
			) SC

		END

	END TRY

	BEGIN CATCH

		DECLARE @Error VARCHAR(MAX)
		SET @Error = ERROR_MESSAGE()
		;
		THROW 51000, @Error, 1
	END CATCH
GO
