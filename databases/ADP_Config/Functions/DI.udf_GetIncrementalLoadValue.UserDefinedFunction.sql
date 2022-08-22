/*
Description
***********

This function get the watermark column value for the Incremental Load

*/



CREATE OR ALTER   FUNCTION [DI].[udf_GetIncrementalLoadValue] 
(
	@TaskInstanceID INT
	,@Entity VARCHAR(100)
)

RETURNS NVARCHAR(100)
AS

BEGIN

	DECLARE @ReturnValue VARCHAR(100)
		   ,@TaskID INT
		   ,@IncrementalDataType VARCHAR(50)
		   ,@IncrementalValue VARCHAR(50) = 0
		   ,@FileLoadIndicator INT
		   ,@SQLSelectCommand CHAR(1)
		   ,@IncrementalFormat VARCHAR(50)

	SELECT
		@TaskID = TI.TaskID
		,@FileLoadIndicator = TT.FileLoadIndicator
		,@SQLSelectCommand = ISNULL(MAX(CASE WHEN (TPT.TaskPropertyTypeName = 'SQL Command' AND TP.TaskPropertyValue LIKE '%SELECT%' AND TP.TaskPropertyValue LIKE '%FROM%') OR (TPT.TaskPropertyTypeName = 'Source Table' AND TP.TaskPropertyValue IS NOT NULL) THEN 'Y' ELSE 'N' END), 'N')
	FROM
		DI.TaskInstance TI
		INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
		INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
		INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
		LEFT OUTER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
			AND TPT.TaskPropertyTypeName IN('Source Table', 'SQL Command')
	WHERE
		TaskInstanceID = @TaskInstanceID
	GROUP BY 
		TI.TaskID
		,TT.FileLoadIndicator

	-- Get the data type for the incremental column
	IF @Entity = 'SQL' AND @SQLSelectCommand = 'Y'

	BEGIN

		SELECT
			@IncrementalDataType = Temp.DataType
		FROM
			(
			SELECT
				TP.TaskPropertyValue AS [IncrementalColumn]
				,DTC.DataType
			FROM 
				DI.Task T
				INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
				INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
					AND TPT.TaskPropertyTypeName = 'Incremental Column'
				OUTER APPLY 
				(
				-- Get the source table name
				SELECT
					MAX(CASE WHEN CHARINDEX('|', FT.FullTableName) > 0 THEN LEFT(FT.FullTableName, CHARINDEX('|', FT.FullTableName) - 1) ELSE '' END) AS [SourceSchema]
					,MAX(CASE WHEN CHARINDEX('|', FT.FullTableName) > 0 THEN RIGHT(FT.FullTableName, LEN(FT.FullTableName) - CHARINDEX('|', FT.FullTableName)) ELSE FT.FullTableName END) AS [SourceTableName]
				FROM 
					DI.Task T
					INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
					INNER JOIN DI.TaskProperty AS TP ON T.TaskID = TP.TaskID
					INNER JOIN DI.TaskPropertyType AS TPT ON TPT.TaskPropertyTypeID = TP.TaskPropertyTypeID
					INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
					OUTER APPLY
					(
					SELECT
						CASE
							WHEN TPT.TaskPropertyTypeName = 'SQL Command'
							THEN REPLACE(REPLACE(REPLACE(REPLACE(RIGHT(TP.TaskPropertyValue, LEN(TP.TaskPropertyValue) - CHARINDEX('FROM ', TP.TaskPropertyValue) - 4), '"', ''), '[', ''), ']', ''), '.', '|')
							WHEN TPT.TaskPropertyTypeName = 'Source Table'
							THEN REPLACE(TRIM(REPLACE(REPLACE(REPLACE(TP.TaskPropertyValue, '"', ''), '[', ''), ']', '')), '.', '|')
						END AS FullTableName
					) FT
				WHERE
					T.TaskID = @TaskID
					AND TaskPropertyTypeName IN('Source Table', 'SQL Command')
					AND TP.DeletedIndicator = 0
				) SRC
				INNER JOIN SRC.DatabaseTableColumn DTC ON T.SourceConnectionID = DTC.ConnectionID
					AND TP.TaskPropertyValue = DTC.ColumnName
					AND DTC.[Schema] = SRC.SourceSchema
					AND DTC.TableName = SRC.SourceTableName
			WHERE 
				T.TaskID = @TaskID
			) Temp

	END

	ELSE

	BEGIN

		SELECT
			@IncrementalDataType = FIDT.FileInterimDataTypeName
		FROM
			DI.Task T
			INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
			INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
			INNER JOIN DI.FileColumnMapping FCM ON T.TaskID = FCM.TaskID
				AND TPT.TaskPropertyTypeName = 'Incremental Column'
				AND TP.TaskPropertyValue = FCM.TargetColumnName
			INNER JOIN DI.FileInterimDataType FIDT ON FCM.FileInterimDataTypeID = FIDT.FileInterimDataTypeID
		WHERE
			T.TaskID = @TaskID

	END

	-- Get the incremental load value for overlap
	SELECT
		@IncrementalValue = TP.TaskPropertyValue
	FROM
		DI.Task T
		INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
		INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
	WHERE
		T.TaskID = @TaskID
		AND TPT.TaskPropertyTypeName = 'Incremental Value'

	-- Get the incremental format
	SELECT
		@IncrementalFormat = TP.TaskPropertyValue
	FROM
		DI.Task T
		INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
		INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
	WHERE
		T.TaskID = @TaskID
		AND TPT.TaskPropertyTypeName = 'Incremental Column Format'


	BEGIN

		-- Get latest successful Value 
		SELECT
			@ReturnValue = MAX(LatestValue)
		FROM
			--[DI].CRMEntityLoadLog CLL
			[DI].[IncrementalLoadLog] CLL
		WHERE
			SuccessIndicator = 1
				AND [TaskInstanceID] IN 
				(SELECT
					TaskInstanceID
				FROM 
					DI.TaskInstance
				WHERE 
					[TaskID] = @TaskID
				)

	END

	SELECT
		@ReturnValue =
		CASE
			WHEN @IncrementalDataType LIKE 'Date%' AND
				ISNULL(@ReturnValue, '') <> '' 
			THEN '''' + FORMAT(DATEADD(DAY, 0 - ISNULL(@IncrementalValue, 0), CAST(@ReturnValue AS DATETIME2)), 'yyyy-MM-dd HH:mm:ss') + ''''
			WHEN @IncrementalDataType LIKE 'Date%' AND @IncrementalFormat = 'yyyy.MM.dd'
			THEN '''1800.01.01'''
			WHEN @IncrementalDataType LIKE 'Date%' 
			THEN '''1800-01-01'''
			WHEN @IncrementalDataType NOT LIKE 'Date%' AND
				TRY_CAST(@ReturnValue AS DECIMAL(38,20)) > ISNULL(TRY_CAST(@IncrementalValue AS DECIMAL(38,20)), 0) 
			THEN CAST(TRY_CAST(@ReturnValue AS DECIMAL(38,20)) - TRY_CAST(@IncrementalValue AS DECIMAL(38,20)) AS VARCHAR(50))
			WHEN @IncrementalDataType NOT LIKE 'Date%' THEN '0'
		END

	RETURN @ReturnValue

END
