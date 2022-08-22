/****** Object:  StoredProcedure [ETL].[usp_StagingTable_Load]    Script Date: 1/12/2020 11:55:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ETL].[usp_StagingTable_Load]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [ETL].[usp_StagingTable_Load] AS' 
END
GO
ALTER PROCEDURE [ETL].[usp_StagingTable_Load]
(
	@TaskConfig VARCHAR(MAX)
	,@TaskSchema VARCHAR(MAX)
)

AS


BEGIN TRY

	BEGIN TRANSACTION

	DECLARE 
		@SchemaDrift CHAR(1)
		,@TargetTable VARCHAR(100)
		,@HistoryTargetTable VARCHAR(110)
		,@TargetTempTable VARCHAR(100)
		,@LoadType VARCHAR(50)
		,@AlterSQL NVARCHAR(MAX) = ''
		,@DeleteSQL NVARCHAR(MAX) = ''
		,@UpdateSQL NVARCHAR(MAX) = ''
		,@InsertSQL NVARCHAR(MAX) = ''
		,@InsertSQLMain NVARCHAR(MAX) = ''
		,@InsertSQLWhere NVARCHAR(MAX) = ''
		,@AlterHistorySQL NVARCHAR(MAX) = ''
		,@SourceFileFormat VARCHAR(50)
		,@ErrorMessage VARCHAR(500)
		,@TaskInstanceID VARCHAR(50)
		,@AutoSchemaDetection CHAR(1)
		,@IncludeSQLDataLineage CHAR(1)
		,@HistoryTable VARCHAR(50)
		,@UseSQLCDC VARCHAR(50)
		,@TargetCDCTempTable VARCHAR(255)


	-- Get TaskConfig Target connection stage variables
	SELECT 
		@SchemaDrift = JSON_VALUE(TaskConfig.[value], '$.AllowSchemaDrift')
		,@TargetTable = JSON_VALUE(TaskConfig.[value], '$.TargetTable')
		,@HistoryTargetTable = CONCAT(LEFT(@TargetTable, LEN(@TargetTable) - 1 ), '_history]')
		,@TargetTempTable = JSON_VALUE(TaskConfig.[value], '$.TargetTempTable')
		,@LoadType = JSON_VALUE(TaskConfig.[value], '$.LoadType')
		,@TaskInstanceID = JSON_VALUE(TaskConfig.[value], '$.TaskInstanceID')
		,@IncludeSQLDataLineage = JSON_VALUE(TaskConfig.[value], '$.IncludeSQLDataLineage')
		,@HistoryTable = JSON_VALUE(TaskConfig.[value], '$.HistoryTable')
	FROM 
		OPENJSON(@TaskConfig) TaskConfig
	WHERE
		JSON_VALUE(TaskConfig.[value], '$.ConnectionStage') = 'Target'

	-- Get CDC temp table 
	SET @TargetCDCTempTable = PARSENAME(@TargetTempTable,2) + '.' + PARSENAME(@TargetTempTable,1) + '_cdc'
	
	-- Get TaskConfig Source connection stage variables
	SELECT 
		@SourceFileFormat = JSON_VALUE(TaskConfig.[value], '$.SourceFileFormat') -- Check if we are doing a file load
		,@AutoSchemaDetection = JSON_VALUE(TaskConfig.[value], '$.AutoSchemaDetection') -- Check if we have auto schema detection from the source
		,@UseSQLCDC = JSON_VALUE(TaskConfig.[value], '$.UseSQLCDC')
	FROM 
		OPENJSON(@TaskConfig) TaskConfig
	WHERE
		JSON_VALUE(TaskConfig.[value], '$.ConnectionStage') = 'Source'

	--Throw a custom error if we don't have any column level metadata for the table
	IF ISNULL(@TaskSchema, '') = ''
    BEGIN
		SET @ErrorMessage = 'No column metadata available for table ' + @TargetTable + '. Please check source database permissions'
        		
		-- Raise the error
		RAISERROR (@ErrorMessage, 16, 1);     
    END

	-- Get the source and target schemas
	DROP TABLE IF EXISTS #TargetSchema 

	SELECT 
		ISNULL(TargetTable.OriginalColumnName, TempTable.OriginalColumnName) AS OriginalColumnName
	   ,ISNULL(TargetTable.TargetColumnName, TempTable.TempColumnName) AS TargetColumnName
	   ,CASE
			WHEN TargetTable.OriginalColumnName IS NULL	AND TempTable.TempColumnName <> 'ETL_Operation'
			THEN 'Add'
			WHEN TempTable.OriginalColumnName IS NULL AND NOT(@IncludeSQLDataLineage = 'Y' AND TargetTable.OriginalColumnName LIKE 'ADS!_%' ESCAPE '!')
			THEN 'Delete'
			WHEN ISNULL(TempTable.TempColumnName, '') <> 'ETL_Operation'
			THEN 'Update'
		END AS ColumnAction
	   ,TempTable.TempColumnName
	   ,TempTable.NewColumnName
	   ,TempTable.TargetDataType
	   ,TargetTable.KeyColumn
	   ,TargetTable.AllowNull
	INTO
		#TargetSchema
	FROM 
		(
		SELECT
			Col.OriginalColumnName
			,C.COLUMN_NAME AS TargetColumnName
			,CASE
				WHEN IC.IndexColumnName IS NOT NULL 
				THEN 'Y'
				ELSE 'N'
			END AS KeyColumn
			,CASE C.IS_NULLABLE
				WHEN 'YES'
				THEN 'Y'
				WHEN 'NO'
				THEN 'N'
			END AS AllowNull
		FROM
			INFORMATION_SCHEMA.[COLUMNS] C
			CROSS APPLY OPENJSON(@TaskSchema) TaskSchema
			CROSS APPLY
			(
			SELECT
				JSON_VALUE(TaskSchema.[value], '$.OriginalColumnName') AS OriginalColumnName
				,JSON_VALUE(TaskSchema.[value], '$.TransformedColumnName') AS TransformedColumnName
			) Col
			LEFT OUTER JOIN 
			(
			SELECT
				SCHEMA_NAME(T.[schema_id]) AS TABLE_SCHEMA
				,T.[name] AS TABLE_NAME
				,C.[name] AS IndexColumnName
			FROM
				sys.tables T
				INNER JOIN sys.indexes I ON T.[object_id] = I.[object_id]
				INNER JOIN sys.index_columns IC ON I.[object_id] = IC.[object_id]
					AND I.index_id = IC.index_id
				INNER JOIN sys.[columns] C ON T.[object_id] = C.[object_id]
					AND IC.column_id = C.column_id
			WHERE
				I.is_unique = 1
			) IC ON C.TABLE_SCHEMA = IC.TABLE_SCHEMA
				AND C.TABLE_NAME = IC.TABLE_NAME
				AND C.COLUMN_NAME = IC.IndexColumnName
		WHERE
	 		C.TABLE_SCHEMA = PARSENAME(@TargetTable, 2)
			AND C.TABLE_NAME = PARSENAME(@TargetTable, 1)
			AND C.COLUMN_NAME = Col.OriginalColumnName

		UNION ALL

		--Get the ADS data lineage columns
		SELECT
			C.COLUMN_NAME AS OriginalColumnName
			,C.COLUMN_NAME AS TargetColumnName
			,'N' AS KeyColumn
			,CASE C.IS_NULLABLE
				WHEN 'YES'
				THEN 'Y'
				WHEN 'NO'
				THEN 'N'
			END AS AllowNull
		FROM
			INFORMATION_SCHEMA.[COLUMNS] C
		WHERE
	 		C.TABLE_SCHEMA = PARSENAME(@TargetTable, 2)
			AND C.TABLE_NAME = PARSENAME(@TargetTable, 1)
			AND C.COLUMN_NAME LIKE 'ADS!_%' ESCAPE '!'
		) TargetTable
		FULL OUTER JOIN
		(
		SELECT
			Col.OriginalColumnName
			,C.COLUMN_NAME AS TempColumnName
			,JSON_VALUE(TaskSchema.[value], '$.SQLDataType') AS TargetDataType
			,CASE
				WHEN @AutoSchemaDetection = 'Y'
				THEN Col.OriginalColumnName
				ELSE Col.TransformedColumnName
			END AS NewColumnName
		FROM
			INFORMATION_SCHEMA.[COLUMNS] C
			CROSS APPLY OPENJSON(@TaskSchema) TaskSchema
			CROSS APPLY
			(
			SELECT
				JSON_VALUE(TaskSchema.[value], '$.OriginalColumnName') AS OriginalColumnName
				,JSON_VALUE(TaskSchema.[value], '$.TransformedColumnName') AS TransformedColumnName
			) Col
		WHERE
	 		C.TABLE_SCHEMA = PARSENAME(@TargetTempTable, 2)
			AND C.TABLE_NAME = PARSENAME(@TargetTempTable, 1)
			AND C.COLUMN_NAME = Col.TransformedColumnName

		UNION ALL

		-- Get the ETL_Operation Column
		SELECT
			C.COLUMN_NAME AS OriginalColumnName
			,C.COLUMN_NAME AS TempColumnName
			,'' AS TargetDataType
			,'' AS NewColumnName
		FROM
			INFORMATION_SCHEMA.[COLUMNS] C
		WHERE
	 		C.TABLE_SCHEMA = PARSENAME(@TargetTempTable, 2)
			AND C.TABLE_NAME = PARSENAME(@TargetTempTable, 1)
			AND C.COLUMN_NAME = 'ETL_Operation'
		) TempTable ON TargetTable.OriginalColumnName = TempTable.OriginalColumnName

	IF @HistoryTable = 'True' 

	BEGIN 
		-- Create HistoryTargetSchema table
		DROP TABLE IF EXISTS #HistoryTargetSchema

		SELECT 
			ISNULL(HistoryTargetTable.OriginalColumnName, HistoryTempTable.OriginalColumnName) AS OriginalColumnName
		   ,ISNULL(HistoryTargetTable.TargetColumnName, HistoryTempTable.TempColumnName) AS TargetColumnName
		   ,CASE
				WHEN HistoryTargetTable.OriginalColumnName IS NULL	AND HistoryTempTable.TempColumnName <> 'ETL_Operation'
				THEN 'Add'
				WHEN HistoryTempTable.OriginalColumnName IS NULL AND NOT(HistoryTargetTable.OriginalColumnName LIKE 'ADS!_%' ESCAPE '!' OR HistoryTargetTable.OriginalColumnName LIKE '__$%')
				THEN 'Delete'
				ELSE 'Update'
			END AS ColumnAction
		   ,ISNULL(HistoryTargetTable.TempColumnName, HistoryTempTable.TempColumnName) AS TempColumnName
		   ,HistoryTempTable.NewColumnName
		   ,ISNULL(HistoryTargetTable.TargetDataType, HistoryTempTable.TargetDataType) AS TargetDataType 
		   ,HistoryTargetTable.KeyColumn
		   ,HistoryTargetTable.AllowNull
		INTO
			#HistoryTargetSchema
		FROM 
			(
			SELECT
				Col.OriginalColumnName
				,C.COLUMN_NAME AS TargetColumnName
				,NULL AS TempColumnName
				,NULL AS TargetDataType
				,CASE
					WHEN IC.IndexColumnName IS NOT NULL 
					THEN 'Y'
					ELSE 'N'
				END AS KeyColumn
				,CASE C.IS_NULLABLE
					WHEN 'YES'
					THEN 'Y'
					WHEN 'NO'
					THEN 'N'
				END AS AllowNull
			FROM
				INFORMATION_SCHEMA.[COLUMNS] C
				CROSS APPLY OPENJSON(@TaskSchema) TaskSchema
				CROSS APPLY
				(
				SELECT
					JSON_VALUE(TaskSchema.[value], '$.OriginalColumnName') AS OriginalColumnName
					,JSON_VALUE(TaskSchema.[value], '$.TransformedColumnName') AS TransformedColumnName
				) Col
				LEFT OUTER JOIN 
				(
				SELECT
					SCHEMA_NAME(T.[schema_id]) AS TABLE_SCHEMA
					,T.[name] AS TABLE_NAME
					,C.[name] AS IndexColumnName
				FROM
					sys.tables T
					INNER JOIN sys.indexes I ON T.[object_id] = I.[object_id]
					INNER JOIN sys.index_columns IC ON I.[object_id] = IC.[object_id]
						AND I.index_id = IC.index_id
					INNER JOIN sys.[columns] C ON T.[object_id] = C.[object_id]
						AND IC.column_id = C.column_id
				WHERE
					I.is_unique = 1
				) IC ON C.TABLE_SCHEMA = IC.TABLE_SCHEMA
					AND C.TABLE_NAME = IC.TABLE_NAME
					AND C.COLUMN_NAME = IC.IndexColumnName
			WHERE
	 			C.TABLE_SCHEMA = PARSENAME(@HistoryTargetTable, 2)
				AND C.TABLE_NAME = PARSENAME(@HistoryTargetTable, 1)
				AND C.COLUMN_NAME = Col.OriginalColumnName

			UNION ALL

			--Get the ADS data lineage columns
			SELECT
				C.COLUMN_NAME AS OriginalColumnName
				,C.COLUMN_NAME AS TargetColumnName
				,NULL AS TempColumnName
				,NULL AS TargetDataType
				,'N' AS KeyColumn
				,CASE C.IS_NULLABLE
					WHEN 'YES'
					THEN 'Y'
					WHEN 'NO'
					THEN 'N'
				END AS AllowNull
			FROM
				INFORMATION_SCHEMA.[COLUMNS] C
			WHERE
	 			C.TABLE_SCHEMA = PARSENAME(@HistoryTargetTable, 2)
				AND C.TABLE_NAME = PARSENAME(@HistoryTargetTable, 1)
				AND C.COLUMN_NAME LIKE 'ADS!_%' ESCAPE '!'

			UNION ALL

			--Get the CDC columns
			SELECT
				C.COLUMN_NAME AS OriginalColumnName
				,C.COLUMN_NAME AS TargetColumnName
				,C.COLUMN_NAME AS TempColumnName
				,CASE WHEN C.CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN C.DATA_TYPE + '(' + CASE WHEN C.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'max' ELSE CAST(C.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(MAX)) END + ')' WHEN C.DATA_TYPE = 'datetimeoffset' THEN  C.DATA_TYPE + '(' + CAST(C.DATETIME_PRECISION AS VARCHAR(MAX))  + ')'  ELSE  C.DATA_TYPE END AS TargetDataType
				,'N' AS KeyColumn
				,CASE C.IS_NULLABLE
					WHEN 'YES'
					THEN 'Y'
					WHEN 'NO'
					THEN 'N'
				END AS AllowNull
			FROM
				INFORMATION_SCHEMA.[COLUMNS] C
			WHERE
	 			C.TABLE_SCHEMA = PARSENAME(@HistoryTargetTable, 2)
				AND C.TABLE_NAME = PARSENAME(@HistoryTargetTable, 1)
				AND C.COLUMN_NAME LIKE '__$%'
			) HistoryTargetTable
			FULL OUTER JOIN
			(
			SELECT
				Col.OriginalColumnName
				,C.COLUMN_NAME AS TempColumnName
				,JSON_VALUE(TaskSchema.[value], '$.SQLDataType') AS TargetDataType
				,CASE
					WHEN @AutoSchemaDetection = 'Y'
					THEN Col.OriginalColumnName
					ELSE Col.TransformedColumnName
				END AS NewColumnName
			FROM
				INFORMATION_SCHEMA.[COLUMNS] C
				CROSS APPLY OPENJSON(@TaskSchema) TaskSchema
				CROSS APPLY
				(
				SELECT
					JSON_VALUE(TaskSchema.[value], '$.OriginalColumnName') AS OriginalColumnName
					,JSON_VALUE(TaskSchema.[value], '$.TransformedColumnName') AS TransformedColumnName
				) Col
			WHERE
	 			C.TABLE_SCHEMA = PARSENAME(CASE WHEN @UseSQLCDC = 'True' THEN @TargetCDCTempTable ELSE @TargetTempTable END, 2)
				AND C.TABLE_NAME = PARSENAME(CASE WHEN @UseSQLCDC = 'True' THEN @TargetCDCTempTable ELSE @TargetTempTable END, 1)
				AND C.COLUMN_NAME = Col.TransformedColumnName

			UNION ALL

			-- Get the ETL_Operation Column
			SELECT
				C.COLUMN_NAME AS OriginalColumnName
				,C.COLUMN_NAME AS TempColumnName
				,'varchar(255)' AS TargetDataType
				,'' AS NewColumnName
			FROM
				INFORMATION_SCHEMA.[COLUMNS] C
			WHERE
	 			C.TABLE_SCHEMA = PARSENAME(CASE WHEN @UseSQLCDC = 'True' THEN @TargetCDCTempTable ELSE @TargetTempTable END, 2)
				AND C.TABLE_NAME = PARSENAME(CASE WHEN @UseSQLCDC = 'True' THEN @TargetCDCTempTable ELSE @TargetTempTable END, 1)
				AND C.COLUMN_NAME = 'ETL_Operation'
			) HistoryTempTable ON HistoryTargetTable.OriginalColumnName = HistoryTempTable.OriginalColumnName

			
			
	END
	--PRINT @UseSQLCDC 
	--PRINT @TargetCDCTempTable
	--SELECT * FROM #HistoryTargetSchema
	--RETURN 

	-- Fail the ETL if schema drift is not allowed and schema has changed

	IF @SchemaDrift = 'N'

	BEGIN

		IF EXISTS (SELECT 1 FROM #TargetSchema TS WHERE TS.ColumnAction = 'Add') 
        BEGIN

			SELECT 
				@ErrorMessage = 'Schema drift not allowed and column/s added/renamed in ' + @TargetTable + ': ' + STRING_AGG(TS.NewColumnName, ',')
			FROM 
				#TargetSchema TS 
			WHERE 
				TS.ColumnAction = 'Add'
        		
			-- Raise the error
			
			RAISERROR (@ErrorMessage, 16, 1); 
        
        END

	END

	-- If schema drift is allowed, add any missing columns to the target table
	
	ELSE IF @SchemaDrift = 'Y'

	BEGIN

		SELECT
			@AlterSQL = 'ALTER TABLE ' + @TargetTable + ' ADD ' + STRING_AGG('[' + TS.NewColumnName + '] ' + TS.TargetDataType, ',') + ';'
		FROM 
			#TargetSchema TS 
		WHERE 
			TS.ColumnAction = 'Add'

		EXEC sys.sp_executesql @AlterSQL

		IF @HistoryTable = 'True'

		BEGIN 

			SELECT
				@AlterHistorySQL = 'ALTER TABLE ' + @HistoryTargetTable + ' ADD ' + STRING_AGG('[' + TS.NewColumnName + '] ' + TS.TargetDataType, ',') + ';'
			FROM 
				#HistoryTargetSchema TS 
			WHERE 
				TS.ColumnAction = 'Add'

			EXEC sys.sp_executesql @AlterHistorySQL

		END 

	END

	-- If data lineage is enabled and the columns don't exist, then add them
	IF @IncludeSQLDataLineage = 'Y' AND NOT EXISTS(SELECT 1 FROM #TargetSchema TS WHERE TS.OriginalColumnName LIKE 'ADS!_%' ESCAPE '!')

	BEGIN

		SELECT
			@AlterSQL = 'ALTER TABLE ' + @TargetTable + ' ADD [ADS_DateCreated] DATETIMEOFFSET,[ADS_TaskInstanceID] INT'

		EXEC sys.sp_executesql @AlterSQL

		-- Insert the column metadata into the #TargetSchema table

		INSERT INTO #TargetSchema
		(
			OriginalColumnName
			,TargetColumnName
			,ColumnAction
			,TempColumnName
			,TargetDataType
			,KeyColumn
			,AllowNull
		)
		SELECT
			'ADS_DateCreated'
			,'ADS_DateCreated'
			,'Update'
			,NULL
			,'DATETIMEOFFSET'
			,'N'
			,'Y'
		UNION ALL
		SELECT
			'ADS_TaskInstanceID'
			,'ADS_TaskInstanceID'
			,'Update'
			,NULL
			,'INT'
			,'N'
			,'Y'

	END

	-- Load the data

	-- Generate the SQL insert statement

	DECLARE
		@ETLColumnExists BIT = ISNULL((SELECT 1 FROM #TargetSchema TS WHERE TS.TempColumnName = 'ETL_Operation'), 0)

	IF @AutoSchemaDetection = 'N'

	BEGIN

		-- Do type casts for manual schema specification

		SELECT
			@InsertSQLMain = 'INSERT INTO ' + CAST(@TargetTable AS NVARCHAR(MAX)) + '(' + STRING_AGG('[' + CAST(TS.TargetColumnName AS NVARCHAR(MAX)) + ']', ',') + 
			') SELECT ' + STRING_AGG( +	CASE
											WHEN @IncludeSQLDataLineage = 'Y' AND TS.TargetColumnName = 'ADS_DateCreated'
											THEN 'SYSUTCDATETIME()'
											WHEN @IncludeSQLDataLineage = 'Y' AND TS.TargetColumnName = 'ADS_TaskInstanceID'
											THEN @TaskInstanceID
											WHEN TS.TargetDataType LIKE '%date%'
											THEN 'TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ')'
											--Added to remove scientific notation issues
											WHEN TS.TargetDataType LIKE '%decimal%' OR TS.TargetDataType LIKE '%numeric%'
											THEN 'CASE WHEN TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ') IS NULL AND [' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] IS NOT NULL THEN CAST(CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS FLOAT) AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ') ELSE [' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] END'
											WHEN TS.TargetDataType = 'geography'
											THEN 'geography::STGeomFromText([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '], 4326)'
											WHEN TS.TargetDataType = 'geometry'
											THEN 'geometry::STGeomFromText([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '], 4326)'
											WHEN TS.TargetDataType NOT LIKE '%char%'
											THEN 'TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ')'
											ELSE '[' + TS.TempColumnName + ']'
										END , ',') + ' FROM ' + CAST(@TargetTempTable AS NVARCHAR(MAX)) + CASE WHEN @ETLColumnExists = 1 THEN ' WHERE [ETL_Operation] <> ''Delete''' ELSE '' END
		FROM
			#TargetSchema TS
		WHERE
			TS.ColumnAction IN('Update','Add')

	END

	ELSE

	BEGIN

		SELECT
			@InsertSQLMain = 'INSERT INTO ' + CAST(@TargetTable AS NVARCHAR(MAX)) + '(' + STRING_AGG('[' + CAST(TargetCol.TargetColumnName AS NVARCHAR(MAX)) + ']', ',')  +							
			') SELECT ' + STRING_AGG( +	CASE
											WHEN @IncludeSQLDataLineage = 'Y' AND TargetCol.TargetColumnName = 'ADS_DateCreated'
											THEN 'SYSUTCDATETIME()'
											WHEN @IncludeSQLDataLineage = 'Y' AND TargetCol.TargetColumnName = 'ADS_TaskInstanceID'
											THEN @TaskInstanceID
											WHEN TS.TargetDataType LIKE '%date%'
											THEN 'TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ')'
											--Added to remove scientific notation issues
											WHEN TS.TargetDataType LIKE '%decimal%' OR TS.TargetDataType LIKE '%numeric%'
											THEN 'CASE WHEN TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ') IS NULL AND [' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] IS NOT NULL THEN CAST(CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS FLOAT) AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ') ELSE [' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] END'
											WHEN TS.TargetDataType = 'geography'
											THEN 'geography::STGeomFromText([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '], 4326)'
											WHEN TS.TargetDataType = 'geometry'
											THEN 'geometry::STGeomFromText([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '], 4326)'
											ELSE '[' + TS.TempColumnName + ']'
										END , ',') + ' FROM ' + CAST(@TargetTempTable AS NVARCHAR(MAX)) + CASE WHEN @ETLColumnExists = 1 THEN ' WHERE [ETL_Operation] <> ''Delete''' ELSE '' END
		FROM
			#TargetSchema TS
			CROSS APPLY
			(
			SELECT
				CASE
					WHEN TS.ColumnAction = 'Add'
					THEN TS.NewColumnName
					ELSE TS.TargetColumnName
				END AS TargetColumnName
			) TargetCol
		WHERE
			TS.ColumnAction IN('Update','Add')

	END

	-- Add WHERE clause to exclude invalid dates where columns don't allow nulls

	IF EXISTS(SELECT 1 FROM #TargetSchema TS WHERE TS.AllowNull = 'N' AND TS.TargetDataType LIKE 'date%')

	BEGIN

		SELECT
			@InsertSQLWhere = CASE WHEN @ETLColumnExists = 1 THEN ' AND ' ELSE ' WHERE ' END + 
			STRING_AGG(
			CASE
				WHEN TS.TargetDataType LIKE 'date%'
				THEN 'TRY_CAST([' + TS.TempColumnName + '] AS ' + TS.TargetDataType + ') IS NOT NULL'
				ELSE ''
			END , ' AND ')
		FROM
			#TargetSchema TS
		WHERE
			TS.AllowNull = 'N'
			AND TS.TargetDataType LIKE 'date%'

	END

	SET @InsertSQL = @InsertSQLMain + @InsertSQLWhere

	-- Do a full load if there is no primary key or unique index or this is the first load for a table

	IF NOT EXISTS (SELECT 1 FROM #TargetSchema TS WHERE TS.KeyColumn = 'Y') 
		OR (NOT EXISTS (SELECT 1 FROM #TargetSchema TS WHERE TS.TempColumnName = 'ETL_Operation') AND @LoadType = 'Full')
    BEGIN
    
    	EXEC('TRUNCATE TABLE ' + @TargetTable)

		EXEC sys.sp_executesql @InsertSQL
		--PRINT @InsertSQL

    END

	ELSE

	-- There is a key and an ETL operation so do Insert, Update and Delete

	BEGIN

		-- Delete missing data

		SELECT
			@DeleteSQL = 'DELETE T FROM ' + @TargetTempTable + ' S INNER JOIN ' + @TargetTable + ' T ON ' + 
			STRING_AGG(
			CASE
				WHEN TS.AllowNull = 'Y'
				THEN
				CASE
					WHEN TS.TargetDataType LIKE '%decimal%' OR TS.TargetDataType LIKE '%numeric%'
					THEN 'COALESCE(S.[' + TS.TempColumnName + '], CAST(0 AS DECIMAL(36,12))) = COALESCE(T.[' + TS.TargetColumnName + '], CAST(0 AS DECIMAL(36,12)))'
					WHEN TS.TargetDataType LIKE '%int%' OR TS.TargetDataType LIKE '%money%' OR TS.TargetDataType IN('real', 'float')
					THEN 'COALESCE(S.[' + TS.TempColumnName + '], 0) = COALESCE(T.[' + TS.TargetColumnName + '], 0)'
					WHEN TS.TargetDataType LIKE 'date%'
					THEN 'COALESCE(TRY_CAST(S.[' + TS.TempColumnName + '] AS ' + TS.TargetDataType + '), '''') = COALESCE(TRY_CAST(T.[' + TS.TargetColumnName + '] AS ' + TS.TargetDataType + '), '''')'
					ELSE 'COALESCE(S.[' + TS.TempColumnName + '], '''') = COALESCE(T.[' + TS.TargetColumnName + '], '''')'
				END
				ELSE 'S.[' + TS.TempColumnName + '] = T.[' + TS.TargetColumnName + ']'
			END, ' AND ')
		FROM
			#TargetSchema TS
		WHERE
			TS.KeyColumn = 'Y'

		-- Don't do updates as they are slow, rather do a delete and insert
		
		-- Remove changed data

		EXEC sys.sp_executesql @DeleteSQL
		--PRINT @DeleteSQL

		-- Insert new data

		EXEC sys.sp_executesql @InsertSQL
		--PRINT @InsertSQL

	END

	-- Insert to the history table if HistoryTable is enabled 
	IF @HistoryTable = 'True'  
	BEGIN 

		-- Generate history table insert sql statement 
		IF @AutoSchemaDetection = 'N'

		BEGIN

			-- Do type casts for manual schema specification
			
			SELECT
				@InsertSQLMain = 'INSERT INTO ' + CAST(@HistoryTargetTable AS NVARCHAR(MAX)) + '(' + STRING_AGG('[' + CAST(TS.TargetColumnName AS NVARCHAR(MAX)) + ']', ',') + 
				') SELECT ' + STRING_AGG( +	CASE
												WHEN TS.TargetColumnName = 'ADS_DateCreated'
												THEN 'SYSUTCDATETIME()'
												WHEN TS.TargetColumnName = 'ADS_TaskInstanceID'
												THEN @TaskInstanceID
												WHEN TS.TargetDataType LIKE '%date%'
												THEN 'TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ')'
												--Added to remove scientific notation issues
												WHEN TS.TargetDataType LIKE '%decimal%' OR TS.TargetDataType LIKE '%numeric%'
												THEN 'CASE WHEN TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ') IS NULL AND [' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] IS NOT NULL THEN CAST(CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS FLOAT) AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ') ELSE [' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] END'
												WHEN TS.TargetDataType = 'geography'
												THEN 'geography::STGeomFromText([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '], 4326)'
												WHEN TS.TargetDataType = 'geometry'
												THEN 'geometry::STGeomFromText([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '], 4326)'
												WHEN TS.TargetDataType NOT LIKE '%char%'
												THEN 'TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ')'
												ELSE '[' + TS.TempColumnName + ']'
											END , ',') + ' FROM ' + CAST(CASE WHEN @UseSQLCDC = 'True' THEN @TargetCDCTempTable ELSE @TargetTempTable END  AS NVARCHAR(MAX))
			FROM
				#HistoryTargetSchema TS
			WHERE
				TS.ColumnAction IN('Update','Add')

		END

		ELSE

		BEGIN
			--SELECT * FROM #HistoryTargetSchema
			--RETURN 
			SELECT
				@InsertSQLMain = 'INSERT INTO ' + CAST(@HistoryTargetTable AS NVARCHAR(MAX)) + '(' + STRING_AGG('[' + CAST(TargetCol.TargetColumnName AS NVARCHAR(MAX)) + ']', ',') +
				') SELECT ' + STRING_AGG( +	CASE
												WHEN TargetCol.TargetColumnName = 'ADS_DateCreated'
												THEN 'SYSUTCDATETIME()'
												WHEN TargetCol.TargetColumnName = 'ADS_TaskInstanceID'
												THEN @TaskInstanceID
												WHEN TS.TargetDataType LIKE '%date%'
												THEN 'TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ')'
												--Added to remove scientific notation issues
												WHEN TS.TargetDataType LIKE '%decimal%' OR TS.TargetDataType LIKE '%numeric%'
												THEN 'CASE WHEN TRY_CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ') IS NULL AND [' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] IS NOT NULL THEN CAST(CAST([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] AS FLOAT) AS ' + CAST(TS.TargetDataType AS NVARCHAR(MAX)) + ') ELSE [' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '] END'
												WHEN TS.TargetDataType = 'geography'
												THEN 'geography::STGeomFromText([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '], 4326)'
												WHEN TS.TargetDataType = 'geometry'
												THEN 'geometry::STGeomFromText([' + CAST(TS.TempColumnName AS NVARCHAR(MAX)) + '], 4326)'
												ELSE '[' + TS.TempColumnName + ']'
											END , ',') + ' FROM ' + CAST(CASE WHEN @UseSQLCDC = 'True' THEN @TargetCDCTempTable ELSE @TargetTempTable END AS NVARCHAR(MAX))
			FROM
				#HistoryTargetSchema TS
				CROSS APPLY
				(
				SELECT
					CASE
						WHEN TS.ColumnAction = 'Add'
						THEN TS.NewColumnName
						ELSE TS.TargetColumnName
					END AS TargetColumnName
				) TargetCol
			WHERE
				TS.ColumnAction IN('Update','Add')
		END

		IF EXISTS(SELECT 1 FROM #HistoryTargetSchema TS WHERE TS.AllowNull = 'N' AND TS.TargetDataType LIKE 'date%')

		BEGIN

			SELECT
				@InsertSQLWhere = ' WHERE ' + 
				STRING_AGG(
				CASE
					WHEN TS.TargetDataType LIKE 'date%'
					THEN 'TRY_CAST([' + TS.TempColumnName + '] AS ' + TS.TargetDataType + ') IS NOT NULL'
					ELSE ''
				END , ' AND ')
			FROM
				#HistoryTargetSchema TS
			WHERE
				TS.AllowNull = 'N'
				AND TS.TargetDataType LIKE 'date%'

		END

		SET @InsertSQL = @InsertSQLMain + @InsertSQLWhere

		--PRINT @InsertSQL
		--RETURN

		-- Delete task instance Id that exist in history table 
		SET @DeleteSQL = 'DELETE FROM ' + @HistoryTargetTable + ' WHERE ADS_TaskInstanceID = ' + @TaskInstanceID
		EXEC sys.sp_executesql @DeleteSQL

		-- Execute insert sql statement 
		EXEC sys.sp_executesql @InsertSQL
		--PRINT @InsertSQL

	END

	COMMIT TRANSACTION

END TRY

BEGIN CATCH

	ROLLBACK TRANSACTION

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
