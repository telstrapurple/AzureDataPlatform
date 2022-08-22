/*
#### ADS GO FAST ###

Description
--------------------

This stored procedure is used to generate the schema and table definitions for all tasks

Input
--------------------

@TaskID:		ID for the task
@SchemaOnly:    Indicator to return just the schema or the full set of create scripts

*/


CREATE OR ALTER PROCEDURE  [DI].[usp_StagingTableScript_Generate]
(
	@TaskID INT
	,@SchemaOnly BIT = 0
)

AS

BEGIN TRY

	SET NOCOUNT ON

	DROP TABLE IF EXISTS #Result

	DECLARE 
		@ConnectionID INT 
		,@SystemID INT
		,@TargetSchema VARCHAR(50)
		,@Error VARCHAR(MAX)
		,@UseSQLCDC AS VARCHAR(50)

	SELECT 
		@ConnectionID = T.SourceConnectionID
		,@SystemID = T.SystemID
	FROM 
		DI.Task T 
	WHERE 
		T.TaskID = @TaskID

	SET @UseSQLCDC = (
		SELECT 
			MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Use SQL CDC' THEN TP1.TaskPropertyValue END) AS UseSQLCDC
		FROM 
			DI.TaskProperty TP1 
			INNER JOIN DI.TaskPropertyType TPT ON TP1.TaskPropertyTypeID = TPT.TaskPropertyTypeID 
		WHERE
			TP1.TaskID = @TaskID AND TP1.DeletedIndicator = 0
	)

	--Check if the target schema has been set on the task level

	SELECT 
		@TargetSchema = TP.TaskPropertyValue
	FROM 
		DI.Task T
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
		INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
		INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
	WHERE
		T.TaskID = @TaskID
		AND TPT.TaskPropertyTypeName = 'Target Schema Overwrite' 
		AND TP.DeletedIndicator = 0

	IF TRIM(ISNULL(@TargetSchema, '')) = ''

	BEGIN

		--Set the target schema from the system properties

		SELECT 
			@TargetSchema = SP.SystemPropertyValue
		FROM 
			DI.Task T
			INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
			INNER JOIN DI.SystemProperty SP ON S.SystemID = SP.SystemID
			INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
		WHERE
			T.TaskID = @TaskID
			AND SPT.SystemPropertyTypeName = 'Target Schema' 

	END

	--Raise an error if there is no target schema

	IF TRIM(ISNULL(@TargetSchema, '')) = ''

	BEGIN

		SET @Error = 'Make sure to capture a Target Schema in the task or system properties';
		THROW 51000, @Error, 1 

	END

	-- Get the column level data for database and file loads

	;
	WITH TableColumn AS
	(

	-- Get the database column level data

	SELECT 
		[Schema]
		,TableName
		,ColumnID
		,ColumnName
		,DataType
		,NULL AS ColMappingDataLength
		,[DataLength]
		,DataPrecision
		,DataScale
		,Nullable
		,ComputedIndicator
		,'Database' AS LoadType
		,ColumnName AS TargetColumnName
		,'' AS SourceFileFormat
		,'N' AS KeyColumnIndicator
	FROM 
		SRC.DatabaseTableColumn DTC
	WHERE
		ConnectionID = @ConnectionID

	UNION ALL

	-- Get the column level data for the file loads

	SELECT
		'' AS [Schema]
	   ,TPTT.[TableName]
	   ,ROW_NUMBER() OVER (PARTITION BY T.TaskID ORDER BY FCM.FileColumnMappingID) AS ColumnID
	   ,FCM.SourceColumnName AS [ColumnName]
	   ,FIDT.FileInterimDataTypeName AS [DataType]
	   ,FCM.[DataLength] AS ColMappingDataLength
	   ,NULL AS [DataLength]
	   ,NULL AS DataPrecision
	   ,NULL AS DataScale
	   ,'Y' AS [Nullable]
	   ,NULL AS ComputedIndicator
	   ,'File' AS LoadType
	   ,FCM.TargetColumnName
	   ,TPFF.TaskPropertyValue AS SourceFileFormat
	   ,CASE
			WHEN TargetColumnKey.KeyColumnName IS NOT NULL
			THEN 'Y'
			ELSE 'N'
		END AS KeyColumnIndicator
	FROM
		DI.FileColumnMapping AS FCM
		INNER JOIN DI.Task AS T ON T.TaskID = FCM.TaskID
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
		INNER JOIN DI.FileInterimDataType FIDT ON FIDT.FileInterimDataTypeID = FCM.FileInterimDataTypeID
		LEFT OUTER JOIN 
		(
		SELECT
			TPFF.TaskID
			,TPFF.TaskPropertyValue
		FROM DI.TaskProperty TPFF
			INNER JOIN DI.TaskPropertyType TPTFF ON TPFF.TaskPropertyTypeID = TPTFF.TaskPropertyTypeID
		WHERE
			TPTFF.TaskPropertyTypeName = 'File Format'
		) TPFF ON T.TaskID = TPFF.TaskID
		LEFT OUTER JOIN 
		(
		SELECT
			TPTT.TaskID
			,REPLACE(REPLACE(REPLACE(TPTT.TaskPropertyValue, '"', ''), '[', ''), ']', '') AS [TableName]
		FROM
			DI.TaskProperty TPTT
			INNER JOIN DI.TaskPropertyType TPTTT ON TPTT.TaskPropertyTypeID = TPTTT.TaskPropertyTypeID
				AND TPTTT.TaskPropertyTypeName = 'Target Table'
		WHERE
			TPTT.TaskID = @TaskID
		) TPTT ON T.TaskID = TPTT.TaskID 
		LEFT OUTER JOIN 
		(
		SELECT DISTINCT
			Cols.[value] AS KeyColumnName
		FROM 
			DI.TaskProperty TP1 
			INNER JOIN DI.TaskPropertyType TPT ON TP1.TaskPropertyTypeID = TPT.TaskPropertyTypeID 
			CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(REPLACE(TP1.TaskPropertyValue, '[', ''), ']', ''), '"', ''), ',') Cols
		WHERE
			TP1.TaskID = @TaskID
			AND TPT.TaskPropertyTypeName = 'Target Key Column List'
		) TargetColumnKey ON FCM.TargetColumnName = TargetColumnKey.KeyColumnName
	WHERE
		T.TaskID = @TaskID
		AND FCM.DeletedIndicator = 0
		AND FIDT.DeletedIndicator = 0
	)

	SELECT 
		-- Generate create schema script if it does not exist 
		'IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name = ''' + @TargetSchema + ''') EXEC(''CREATE SCHEMA ' + @TargetSchema + ' AUTHORIZATION DBO'')' AS SchemaCreateScript
		,
		-- Generate create table script if it does not exist 
		CASE
			WHEN TT.TaskTypeName NOT LIKE '%to Synapse'
			THEN 'IF OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + ''') IS NULL
					BEGIN
						CREATE TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '] (' + TabCols.ColumnList + DL.DataLineageColumns + ') ' + 'WITH( DATA_COMPRESSION=PAGE ); 
					END '
			ELSE 'IF OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + ''') IS NULL
					BEGIN
						CREATE TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '] (' + TabCols.ColumnList + DL.DataLineageColumns + ') ' + 'WITH(HEAP); 
					END '
		END
		+
		CASE 		
			WHEN ISNULL(TaskProp.IgnoreSourceKey, 'N') = 'N' AND TabConstaint.ConstraintScript IS NOT NULL AND TT.TaskTypeName NOT LIKE '%to Synapse'
			THEN ' IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + ''') AND is_unique = 1)
					BEGIN
						' + ISNULL('EXEC(''' + TabConstaint.ConstraintScript + ''')', 'SELECT 1')  + '
					END;
					' 
			ELSE ''
		END	
		+	
		CASE 
			WHEN FileLoad.ConstraintScript IS NOT NULL AND ISNULL(TaskProp.IgnoreSourceKey, 'N') = 'N' AND TabConstaint.ConstraintScript IS NULL AND TT.TaskTypeName NOT LIKE '%to Synapse'
			THEN 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + ''') AND is_unique = 1)
					BEGIN
						' + ISNULL('EXEC(''' + FileLoad.ConstraintScript + ''')', 'SELECT 1')  + '
					END;
					' 
			ELSE ''
		END 
		+
		--Synapse
		CASE 
			WHEN FileLoad.ConstraintScript IS NOT NULL AND ISNULL(TaskProp.IgnoreSourceKey, 'N') = 'N' AND TabConstaint.ConstraintScript IS NULL AND TT.TaskTypeName LIKE '%to Synapse'
			THEN 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + ''') AND is_unique = 1)
					BEGIN
						' + ISNULL('EXEC(''' + SynapseLoad.ConstraintScript + ''')', 'SELECT 1')  + '
					END;
					' 
			ELSE ''
		END 
		+
		CASE 
			WHEN TaskProp.ClusteredColumnstoreIndex  = 'Y'  AND TT.TaskTypeName NOT LIKE '%to Synapse'
			THEN 'IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + ''') AND (type = 1 OR type = 5))
					BEGIN
						' + ISNULL('EXEC(''' + CCI.ClusteredColumnstoreIndex + ''')', 'SELECT 1')  + '
					END' 
			ELSE ''
		END AS TableCreateScript
		,
		-- Generate create history table script if it does not exist 
		CASE
			WHEN TaskProp.HistoryTable = 'True' AND TaskProp.UseSQLCDC != 'True'
			THEN 'IF OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + '_history'') IS NULL
					BEGIN
						CREATE TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '_history] (' + TabCols.ColumnList + HT.HistoryTableColumns + ') ' + 'WITH( DATA_COMPRESSION=PAGE );  
					END '
			WHEN TaskProp.HistoryTable = 'True' AND TaskProp.UseSQLCDC = 'True'
			THEN 'IF OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + '_history'') IS NULL
					BEGIN
						CREATE TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '_history] (' + CDC_HT.CDCHistoryTableColumns + TabCols.ColumnList + HT.HistoryTableColumns + ') ' + 'WITH( DATA_COMPRESSION=PAGE );  
					END '
			ELSE ''
		END
		+
		CASE 
			WHEN TaskProp.HistoryTable = 'True' AND ISNULL(TaskProp.IgnoreSourceKey, 'N') = 'N' AND TaskProp.UseSQLCDC != 'True' AND HTConstraint.HistoryTableConstraint IS NOT NULL
			THEN ' IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + '_history'') AND is_unique = 1)
					BEGIN
						' + ISNULL('EXEC(''' + HTConstraint.HistoryTableConstraint + ''')', 'SELECT 1')  + '
					END;
					' 
			WHEN TaskProp.HistoryTable = 'True' AND ISNULL(TaskProp.IgnoreSourceKey, 'N') = 'N' AND TaskProp.UseSQLCDC = 'True' AND CDC_HTConstraint.CDCHistoryTableConstraint IS NOT NULL
			THEN ' IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + '_history'') AND is_unique = 1)
					BEGIN
						' + ISNULL('EXEC(''' + CDC_HTConstraint.CDCHistoryTableConstraint + ''')', 'SELECT 1')  + '
					END;
					' 
			ELSE ''
		END
		+
		CASE 
			WHEN TaskProp.HistoryTable = 'True' AND FileLoad.ConstraintScript IS NOT NULL AND ISNULL(TaskProp.IgnoreSourceKey, 'N') = 'N' AND HTConstraint.HistoryTableConstraint IS NULL
			THEN 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + '_history'') AND is_unique = 1)
					BEGIN
						' + ISNULL('EXEC(''' + FileLoad_HT.ConstraintScript + ''')', 'SELECT 1')  + '
					END;
					' 
			ELSE ''
		END 
		+
		CASE 
			WHEN TaskProp.HistoryTable = 'True' AND TaskProp.ClusteredColumnstoreIndex  = 'Y'
			THEN 'IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(''' + @TargetSchema + '.' + TP.TargetTableName + '_history'') AND (type = 1 OR type = 5))
					BEGIN
						' + ISNULL('EXEC(''' + HistoryTableCCI.ClusteredColumnstoreIndex + ''')', 'SELECT 1')  + '
					END' 
			ELSE ''
		END AS HistoryTableCreateScript
		-- Generate json schema 
		,TabCols.SchemaJson
		-- Generate column list 
		,TabCols.SelectColumnList
		-- Unique Constraint indicator 
		,CASE
			WHEN (TabConstaint.ConstraintScript IS NULL AND TaskProp.KeyColumnList IS NULL) OR TaskProp.IgnoreSourceKey = 'Y'
			THEN 'N'
			ELSE 'Y'
		END AS UniqueConstraintIndicator
		,CASE
			WHEN TaskProp.IgnoreSourceKey = 'Y'
			THEN '' 
			ELSE ISNULL([TCCL].[KeyColumnList], TaskProp.KeyColumnList)
		END AS [UniqueConstraintColumns]
		-- Check if the history table is enabled
		,CASE
			WHEN TaskProp.HistoryTable = 'True' 
			THEN 'Y'
			ELSE 'N'
		END AS HistoryTableIndicator
	INTO
		#Result
	FROM
		DI.Task T
		INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
		OUTER APPLY
		(
		SELECT 
			MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Target Key Column List' AND TP1.TaskPropertyValue <> '' THEN REPLACE(TP1.TaskPropertyValue, '"', '') END) AS KeyColumnList
			,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Ignore Source Key' AND TP1.TaskPropertyValue = 'Y' THEN TP1.TaskPropertyValue END) AS IgnoreSourceKey
			,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Clustered Columnstore Index' AND TP1.TaskPropertyValue = 'Y' THEN TP1.TaskPropertyValue END) AS ClusteredColumnstoreIndex
			,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'History Table' THEN TP1.TaskPropertyValue END) AS HistoryTable
			,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Use SQL CDC' THEN TP1.TaskPropertyValue END) AS UseSQLCDC
			,ISNULL(MAX(CASE WHEN (TPT.TaskPropertyTypeName = 'SQL Command' AND TP1.TaskPropertyValue LIKE '%SELECT%' AND TP1.TaskPropertyValue LIKE '%FROM%') OR (TPT.TaskPropertyTypeName = 'Source Table' AND TP1.TaskPropertyValue IS NOT NULL) THEN 'Y' ELSE 'N' END), 'N') AS SQLSelectCommand
		FROM 
			DI.TaskProperty TP1 
			INNER JOIN DI.TaskPropertyType TPT ON TP1.TaskPropertyTypeID = TPT.TaskPropertyTypeID 
		WHERE
			TP1.TaskID = @TaskID AND TP1.DeletedIndicator = 0 ) TaskProp
		OUTER APPLY
		(
		SELECT 
			MAX(CASE WHEN SPT.SystemPropertyTypeName = 'Include SQL Data Lineage' AND SP.SystemPropertyValue = 'Y' THEN SP.SystemPropertyValue END) AS IncludeSQLDataLineage
		FROM 
			DI.SystemProperty SP
			INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
		WHERE
			SP.SystemID = @SystemID) SystemProp
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
		OUTER APPLY 
		(
		-- Get the target table name
		SELECT
			MAX(FT.TargetTableName) AS [TargetTableName]
			,MAX(CASE WHEN TT.RunType LIKE 'Database to%' AND TT.RunType <> 'Database to DW Stage' AND CHARINDEX('|', FT.FullTableName) > 0 THEN LEFT(FT.FullTableName, CHARINDEX('|', FT.FullTableName) - 1) ELSE '' END) AS [SourceSchema]
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
				,CASE
					WHEN TPT.TaskPropertyTypeName = 'Target Table' 
					THEN REPLACE(REPLACE(REPLACE(TP.TaskPropertyValue, '"', ''), '[', ''), ']', '') 
				END AS [TargetTableName]
			) FT
		WHERE
			T.TaskID = @TaskID
			AND TaskPropertyTypeName IN('Target Table', 'Source Table', 'SQL Command')
		) TP 
		OUTER APPLY
		(
		SELECT
			CASE 
				WHEN SystemProp.IncludeSQLDataLineage = 'Y'
				THEN ',[ADS_DateCreated] DATETIMEOFFSET NULL , [ADS_TaskInstanceID] INT NOT NULL' 
				ELSE ''
			END AS DataLineageColumns
		) DL
		LEFT OUTER JOIN 
		(
		SELECT
			DTC.ConstraintName
			,DTC.[Schema]
			,DTC.TableName
			,ROW_NUMBER() OVER(PARTITION BY DTC.ConnectionID, DTC.[Schema], DTC.TableName ORDER BY DTC.ConstraintType) AS RowID
		FROM 
			SRC.DatabaseTableConstraint DTC
		WHERE
			DTC.ConnectionID = @ConnectionID
		) DTC ON TP.[SourceSchema] = DTC.[Schema]
			AND TP.SourceTableName = DTC.TableName
			AND DTC.RowID = 1
		OUTER APPLY
		(
		SELECT 
			STRING_AGG('[' + DTCC.ColumnName + ']', ',') AS [ConstraintColumnList]
			,STRING_AGG(DTCC.ColumnName, ',') AS [KeyColumnList]
		FROM 
			SRC.DatabaseTableConstraint DTCC
		WHERE	
			DTCC.ConnectionID = @ConnectionID
			AND DTC.[Schema] = DTCC.[Schema]
			AND DTC.TableName = DTCC.TableName
			AND DTC.ConstraintName = DTCC.ConstraintName
		) TCCL
		OUTER APPLY
		(
		SELECT
			', [ETL_Operation] VARCHAR(50) NOT NULL , [ADS_DateCreated] DATETIMEOFFSET NOT NULL , [ADS_TaskInstanceID] INT NOT NULL ' AS HistoryTableColumns
		) HT
		OUTER APPLY
		(
		SELECT
			'[__$start_lsn] BINARY(10) NULL , [__$seqval] BINARY (10) NULL , [__$operation] INT NULL, [__$update_mask] VARBINARY(128) NULL, [__$lsn_timestamp] DATETIMEOFFSET(7) NULL, [__$updated_columns] NVARCHAR(MAX) NULL, ' AS CDCHistoryTableColumns
		) CDC_HT
		OUTER APPLY 
		(
		SELECT 
			CASE 
				--For SQL DW
				WHEN TT.TaskTypeName LIKE '%to Synapse'
				THEN 
					CASE			
						WHEN DTCC.ConstraintType = 'P' 
						THEN 'ALTER TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '_history] ADD CONSTRAINT PK_' + @TargetSchema + '_' + TP.TargetTableName + '_history PRIMARY KEY NONCLUSTERED([ADS_DateCreated], [ADS_TaskInstanceID], ' + TCCL.ConstraintColumnList + ') NOT ENFORCED;'
						ELSE 'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + '_history ON [' + @TargetSchema + '].[' + TP.TargetTableName + '_history]( [ADS_DateCreated], [ADS_TaskInstanceID], ' + TCCL.ConstraintColumnList + ') NOT ENFORCED;'
					END
				WHEN TT.TaskTypeName LIKE '%to SQL' --For SQL DB
				THEN
					CASE
						WHEN TaskProp.ClusteredColumnstoreIndex = 'Y'
						THEN 'CREATE UNIQUE NONCLUSTERED INDEX IX_' + TP.TargetTableName + '_history ON [' + @TargetSchema + '].[' + TP.TargetTableName + '_history]( [ADS_DateCreated], [ADS_TaskInstanceID], ' + TCCL.ConstraintColumnList + ');'
						ELSE
							CASE			
								WHEN DTCC.ConstraintType = 'P' 
								THEN 'ALTER TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '_history] ADD CONSTRAINT PK_' + @TargetSchema + '_' + TP.TargetTableName + '_history PRIMARY KEY CLUSTERED( [ADS_DateCreated], [ADS_TaskInstanceID], ' + TCCL.ConstraintColumnList + ');'
								ELSE 'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + '_history ON [' + @TargetSchema + '].[' + TP.TargetTableName + '_history]( [ADS_DateCreated], [ADS_TaskInstanceID], ' + TCCL.ConstraintColumnList + ');'
							END 
					END
			END AS HistoryTableConstraint 
		FROM 
			SRC.DatabaseTableConstraint DTCC
		WHERE	
			DTCC.ConnectionID = @ConnectionID
			AND DTC.[Schema] = DTCC.[Schema]
			AND DTC.TableName = DTCC.TableName
			AND DTC.ConstraintName = DTCC.ConstraintName
			AND DTC.RowID = 1
		) HTConstraint
		OUTER APPLY 
		(
		SELECT 
			CASE 
				--For SQL DW
				WHEN TT.TaskTypeName LIKE '%to Synapse'
				THEN 
					 'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + '_history ON [' + @TargetSchema + '].[' + TP.TargetTableName + '_history]( [__$start_lsn], [__$seqval], [ADS_DateCreated], [ADS_TaskInstanceID], ' + TCCL.ConstraintColumnList + ') NOT ENFORCED;'
				WHEN TT.TaskTypeName LIKE '%to SQL' --For SQL DB
				THEN
					CASE
						WHEN TaskProp.ClusteredColumnstoreIndex = 'Y'
						THEN 'CREATE UNIQUE NONCLUSTERED INDEX IX_' + TP.TargetTableName + '_history ON [' + @TargetSchema + '].[' + TP.TargetTableName + '_history]( [__$start_lsn], [__$seqval], [ADS_DateCreated], [ADS_TaskInstanceID], ' + TCCL.ConstraintColumnList + ');'
						ELSE
							'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + '_history ON [' + @TargetSchema + '].[' + TP.TargetTableName + '_history]( [__$start_lsn], [__$seqval], [ADS_DateCreated], [ADS_TaskInstanceID], ' + TCCL.ConstraintColumnList + ');'
					END
			END AS CDCHistoryTableConstraint 
		FROM 
			SRC.DatabaseTableConstraint DTCC
		WHERE	
			DTCC.ConnectionID = @ConnectionID
			AND DTC.[Schema] = DTCC.[Schema]
			AND DTC.TableName = DTCC.TableName
			AND DTC.ConstraintName = DTCC.ConstraintName
			AND DTC.RowID = 1
		) CDC_HTConstraint
		OUTER APPLY
		(
		SELECT
			CASE
				WHEN TaskProp.KeyColumnList IS NOT NULL --For Schema Mapping loads
				THEN 'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + '_history ON [' + @TargetSchema + '].[' + TP.TargetTableName + '_history]([ADS_DateCreated], [ADS_TaskInstanceID], ' + TaskProp.KeyColumnList + ');'
			END AS [ConstraintScript] 
		) FileLoad_HT
		OUTER APPLY
		(
		SELECT
			CASE
				WHEN TaskProp.KeyColumnList IS NOT NULL --For Schema Mapping loads
				THEN 'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + ' ON [' + @TargetSchema + '].[' + TP.TargetTableName + '](' + TaskProp.KeyColumnList + ');'
			END AS [ConstraintScript] 
		) FileLoad
		--Synpase Constraint
		OUTER APPLY
		(
		SELECT
			CASE
				WHEN TaskProp.KeyColumnList IS NOT NULL --For Schema Mapping loads
				--THEN 'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + ' ON [' + @TargetSchema + '].[' + TP.TargetTableName + '](' + TaskProp.KeyColumnList + ');'
				THEN 'ALTER TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '] ADD CONSTRAINT IX_' + TP.TargetTableName + ' UNIQUE (' + TaskProp.KeyColumnList + ') NOT ENFORCED;'			
			END AS [ConstraintScript] 
		) SynapseLoad
		OUTER APPLY
		(
		SELECT DISTINCT
			CASE 
				--For SQL DW
				WHEN TT.TaskTypeName LIKE '%to Synapse'
				THEN 
					CASE			
						WHEN DTCC.ConstraintType = 'P' 
						THEN 'ALTER TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '] ADD CONSTRAINT PK_' + @TargetSchema + '_' + TP.TargetTableName + ' PRIMARY KEY NONCLUSTERED(' + TCCL.ConstraintColumnList + ') NOT ENFORCED;'
						ELSE 'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + ' ON [' + @TargetSchema + '].[' + TP.TargetTableName + '](' + TCCL.ConstraintColumnList + ') NOT ENFORCED;'
					END
				WHEN TT.TaskTypeName LIKE '%to SQL' --For SQL DB
				THEN
					CASE
						WHEN TaskProp.ClusteredColumnstoreIndex = 'Y'
						THEN 'CREATE UNIQUE NONCLUSTERED INDEX IX_' + TP.TargetTableName + ' ON [' + @TargetSchema + '].[' + TP.TargetTableName + '](' + TCCL.ConstraintColumnList + ');'
						ELSE
							CASE			
								WHEN DTCC.ConstraintType = 'P' 
								THEN 'ALTER TABLE [' + @TargetSchema + '].[' + TP.TargetTableName + '] ADD CONSTRAINT PK_' + @TargetSchema + '_' + TP.TargetTableName + ' PRIMARY KEY CLUSTERED(' + TCCL.ConstraintColumnList + ');'
								ELSE 'CREATE UNIQUE CLUSTERED INDEX IX_' + TP.TargetTableName + ' ON [' + @TargetSchema + '].[' + TP.TargetTableName + '](' + TCCL.ConstraintColumnList + ');'
							END 
					END
			END AS [ConstraintScript]
		FROM 
			SRC.DatabaseTableConstraint DTCC
		WHERE	
			DTCC.ConnectionID = @ConnectionID
			AND DTC.[Schema] = DTCC.[Schema]
			AND DTC.TableName = DTCC.TableName
			AND DTC.ConstraintName = DTCC.ConstraintName
			AND DTC.RowID = 1
		) TabConstaint
		OUTER APPLY
		(
		SELECT
			CASE
				WHEN TT.TaskTypeName NOT LIKE '%to Synapse' 
					AND TaskProp.ClusteredColumnstoreIndex = 'Y'
				THEN 'CREATE CLUSTERED COLUMNSTORE INDEX CCI_' + TP.TargetTableName + ' ON [' + @TargetSchema + '].[' + TP.TargetTableName + '];'
			END AS [ClusteredColumnstoreIndex]
		) CCI
		OUTER APPLY
		(
		SELECT
			CASE
				WHEN TT.TaskTypeName NOT LIKE '%to Synapse' 
					AND TaskProp.ClusteredColumnstoreIndex = 'Y'
				THEN 'CREATE CLUSTERED COLUMNSTORE INDEX CCI_' + TP.TargetTableName + '_history ON [' + @TargetSchema + '].[' + TP.TargetTableName + '_history];'
			END AS [ClusteredColumnstoreIndex]
		) HistoryTableCCI
		CROSS APPLY
		(
		-- Column Names here. Add CASE statement here for TaskTypeName == File Source, TaskTypeName == Not File Source.  
		SELECT 
			STRING_AGG('[' + 
			CASE
				WHEN DTCol.LoadType = 'File'
				THEN CAST(DTCol.TargetColumnName AS NVARCHAR(MAX))
				ELSE CAST(DTCol.ColumnName AS NVARCHAR(MAX))
			END  + '] ' + 
			CAST(Cols.DataType AS NVARCHAR(MAX)) + 
			CAST(
			CASE 
				WHEN [Nullable] = 'Y' OR ( @UseSQLCDC = 'True' AND ComputedIndicator = 'Y' )
				THEN ' NULL' 
				ELSE ' NOT NULL' 
			END AS NVARCHAR(MAX)), ',') AS ColumnList
			,'[' + STRING_AGG('{"OriginalColumnName":"' 
				+	CASE
						WHEN DTCol.LoadType = 'File'
						THEN CAST(DTCol.TargetColumnName AS NVARCHAR(MAX)) + '","TransformedColumnName":"' 
						ELSE CAST(DTCol.ColumnName AS NVARCHAR(MAX)) + '","TransformedColumnName":"' 
					END
				+   CASE
						WHEN DTCol.LoadType = 'File'
						THEN CAST(DI.udf_ReplaceParquetColumnChars(DTCol.TargetColumnName) AS NVARCHAR(MAX)) + '","ColumnOrdinal":"' 
						ELSE CAST(DI.udf_ReplaceParquetColumnChars(DTCol.ColumnName) AS NVARCHAR(MAX)) + '","ColumnOrdinal":"' 
					END
				+ CAST(DTCol.ColumnID AS NVARCHAR(MAX)) + '","SQLDataType":"'
				+ CAST(Cols.DataType AS NVARCHAR(MAX)) + '"}', ',')
			+ ']' AS SchemaJson
			,STRING_AGG('"' + CAST(CASE WHEN DTCol.DataType IN('geography', 'geometry') THEN DTCol.ColumnName + '".STAsText()' ELSE DTCol.ColumnName + '"' END AS NVARCHAR(MAX)) + ' AS "' + CAST(DI.udf_ReplaceParquetColumnChars(DTCol.ColumnName) AS NVARCHAR(MAX)) + '"', ',') AS SelectColumnList 
		FROM 
			TableColumn DTCol
			CROSS APPLY
			(
			SELECT
				-- Add new case for File to DB and File to DW 
				CASE
					WHEN TT.TaskTypeName = 'Oracle to SQL' 
					THEN
						CASE 
							WHEN DataType IN('clob', 'long', 'xmltype')
							THEN 'varchar(max)'
							WHEN DataType IN('long raw', 'blob')
							THEN 'varbinary(max)'
							WHEN DataType = 'nclob'
							THEN 'text'
							WHEN DataType = 'raw'
							THEN 'varbinary(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'varchar2'
							THEN 'varchar(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'nvarchar2'
							THEN 'nvarchar(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'nvarchar2'
							THEN 'nvarchar(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType IN('char', 'nchar')
							THEN DataType + '(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'date'
							THEN 'datetime'
							WHEN DataType = 'number' AND ([DataScale] IS NULL OR [DataScale] = 0) AND ([DataPrecision] IS NULL OR [DataPrecision] = 0)
							THEN 'float'
							WHEN DataType = 'number' AND [DataScale] = 4 AND [DataPrecision] = 19
							THEN 'money'
							WHEN DataType = 'number' AND [DataScale] = 4 AND [DataPrecision] = 10
							THEN 'smallmoney'
							WHEN DataType = 'number' AND ([DataScale] IS NULL OR [DataScale] = 0) AND [DataPrecision] IS NOT NULL
							THEN 'decimal(' + CAST([DataPrecision] AS VARCHAR(20)) + ')'
							WHEN DataType = 'number' AND [DataScale] IS NOT NULL AND [DataPrecision] IS NOT NULL
							THEN 'decimal(' + CAST([DataPrecision] AS VARCHAR(20)) + ',' + CAST([DataScale] AS VARCHAR(20)) + ')'
							WHEN DataType LIKE 'timestamp%' AND DataType NOT LIKE '%time zone%'
							THEN 'datetime'
							WHEN DataType LIKE 'timestamp%' AND DataType LIKE '%time zone%'
							THEN 'varchar(37)'
							WHEN DataType = 'rowid'
							THEN 'char(18)'
							WHEN DataType = 'float'
							THEN 'float'
							ELSE 'varchar(max)'
						END
					WHEN TT.TaskTypeName IN('On Prem SQL to SQL', 'Azure SQL to SQL')
					THEN 
						CASE 
							WHEN DTCol.[DataLength] = -1 AND DataType NOT IN('geography', 'geometry', 'xml')
							THEN DataType + '(max)'
							WHEN DataType LIKE '%char%'
							THEN DataType + '(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType like '%binary%'
							THEN DataType + '(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DTCol.DataPrecision IS NOT NULL AND DTCol.DataScale IS NOT NULL AND (DTCol.DataType = 'decimal' OR DTCol.DataType = 'numeric')
							THEN DataType + '(' + CAST([DataPrecision] AS VARCHAR(20)) + ',' + CAST([DataScale] AS VARCHAR(20)) + ')'
							ELSE DataType
						END
					--SQL DW 
					--WHEN TT.TaskTypeName LIKE '%Synapse'
					WHEN TT.TaskTypeName LIKE '%Synapse'
					THEN 
						CASE 
							WHEN DTCol.[DataLength] = -1 AND DataType NOT IN('geography', 'geometry', 'xml')
							THEN DataType + '(max)'
							WHEN DataType LIKE '%char%'
							THEN DataType + '(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DTCol.DataPrecision IS NOT NULL AND DTCol.DataScale IS NOT NULL AND (DTCol.DataType = 'decimal' OR DTCol.DataType = 'numeric')
							THEN DataType + '(' + CAST([DataPrecision] AS VARCHAR(20)) + ',' + CAST([DataScale] AS VARCHAR(20)) + ')'
							WHEN DataType IN('geography', 'geometry', 'image')
							THEN 'varbinary(8000)'
							WHEN DataType = 'hierarchyid'
							THEN 'varbinary(4000)'
							WHEN DataType in ('text','xml')
							THEN 'varchar(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'ntext'
							THEN 'nvarchar(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'timestamp'
							THEN 'varbinary(8000)'
							WHEN DataType = 'guid'
							THEN 'uniqueidentifier'
							WHEN DataType = 'Boolean'
							THEN 'bit'
							WHEN DataType IN('Decimal', 'Double', 'Single')
							THEN 'Decimal(36,12)'
							WHEN DataType IN('Int16', 'Int32')
							THEN 'int'
							WHEN DataType = 'Int64'
							THEN 'bigint'
							WHEN DataType = 'String'
							--THEN 'nvarchar(8000)'
							THEN 'varchar(' + ISNULL(CAST([ColMappingDataLength] AS VARCHAR(50)), 'max') + ')'
							WHEN DataType = 'Byte'
							THEN 'varbinary(' + ISNULL(CAST([ColMappingDataLength] AS VARCHAR(50)), '8000') + ')'
							WHEN DataType IN('Datetime', 'Datetimeoffset')
							THEN DataType
							ELSE 'varchar(max)'							
						END
					WHEN TT.TaskTypeName IN('Oracle to Synapse')
					THEN 
						CASE 
							WHEN DataType IN('clob', 'long', 'xmltype')
							THEN 'varchar(max)'
							WHEN DataType IN('long raw', 'blob')
							THEN 'varbinary(max)'
							WHEN DataType = 'nclob'
							THEN 'text'
							WHEN DataType = 'raw'
							THEN 'varbinary(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'varchar2'
							THEN 'varchar(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'nvarchar2'
							THEN 'nvarchar(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'nvarchar2'
							THEN 'nvarchar(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType IN('char', 'nchar')
							THEN DataType + '(' + CAST([DataLength] AS VARCHAR(20)) + ')'
							WHEN DataType = 'date'
							THEN 'datetime'
							WHEN DataType = 'number' AND ([DataScale] IS NULL OR [DataScale] = 0) AND ([DataPrecision] IS NULL OR [DataPrecision] = 0)
							THEN 'float'
							WHEN DataType = 'number' AND [DataScale] = 4 AND [DataPrecision] = 19
							THEN 'money'
							WHEN DataType = 'number' AND [DataScale] = 4 AND [DataPrecision] = 10
							THEN 'smallmoney'
							WHEN DataType = 'number' AND ([DataScale] IS NULL OR [DataScale] = 0) AND [DataPrecision] IS NOT NULL
							THEN 'decimal(' + CAST([DataPrecision] AS VARCHAR(20)) + ')'
							WHEN DataType = 'number' AND [DataScale] IS NOT NULL AND [DataPrecision] IS NOT NULL
							THEN 'decimal(' + CAST([DataPrecision] AS VARCHAR(20)) + ',' + CAST([DataScale] AS VARCHAR(20)) + ')'
							WHEN DataType LIKE 'timestamp%' AND DataType NOT LIKE '%time zone%'
							THEN 'datetime'
							WHEN DataType LIKE 'timestamp%' AND DataType LIKE '%time zone%'
							THEN 'varchar(37)'
							WHEN DataType = 'rowid'
							THEN 'char(18)'
							WHEN DataType = 'float'
							THEN 'float'	
							ELSE 'varchar(max)'			
						END
					WHEN TT.FileLoadIndicator = 1
					THEN
						CASE 
							WHEN DataType = 'Boolean'
							THEN 'bit'
							WHEN DataType IN('Decimal', 'Double', 'Single')
							THEN 'Decimal(' + ISNULL(CAST([ColMappingDataLength] AS VARCHAR(50)), '38,20') + ')' 
							WHEN DataType IN('Int16', 'Int32')
							THEN 'int'
							WHEN DataType = 'Int64'
							THEN 'bigint'
							WHEN DataType IN('Datetime', 'Datetimeoffset')
							THEN DataType
							WHEN DataType = 'Date'
							THEN DataType
							WHEN DataType = 'guid'
							THEN 'uniqueidentifier'
							WHEN DataType = 'String'
							THEN 'varchar(' + ISNULL(CAST([ColMappingDataLength] AS VARCHAR(50)), 'max') + ')'
							WHEN DataType = 'Unicode String'
							THEN 'nvarchar(' + ISNULL(CAST([ColMappingDataLength] AS VARCHAR(50)), 'max') + ')'
							WHEN DataType = 'Byte'
							THEN 'varbinary(' + ISNULL(CAST([ColMappingDataLength] AS VARCHAR(50)), 'max') + ')'
							--If the column is part of a unique index, set the length to 8000
							WHEN DTCol.KeyColumnIndicator = 'Y'
							THEN 'varchar(8000)'
							ELSE 'varchar(max)'
						END					
				END	AS DataType
			) Cols
		WHERE 
			CASE
				WHEN TT.RunType <> 'Database to DW Stage'
					AND NOT(TT.RunType LIKE 'Database to%' AND TT.FileLoadIndicator = 1 AND TaskProp.SQLSelectCommand = 'N')
				THEN TP.[SourceSchema]
				ELSE DTCol.[Schema]
			END = DTCol.[Schema]
			AND CASE
					WHEN TT.RunType LIKE 'Database to%' 
						AND TT.RunType <> 'Database to DW Stage'
						AND NOT(TT.RunType LIKE 'Database to%' AND TT.FileLoadIndicator = 1 AND TaskProp.SQLSelectCommand = 'N')
					THEN TP.SourceTableName
					ELSE TP.TargetTableName
				END = DTCol.TableName
		) TabCols
	WHERE
		T.TaskID = @TaskID

	--Raise an error if the history table is enabled and there is no unique constraint

	IF EXISTS(SELECT * FROM #Result R WHERE R.UniqueConstraintIndicator = 'N' AND R.HistoryTableIndicator = 'Y')

	BEGIN

		;
		THROW 51000, 'Please note that you cannot enable history if there is no unique constraint for the object', 1 

	END

	--Only return the required columns

	IF @SchemaOnly = 1

	BEGIN

		SELECT 
			SchemaJson
		FROM 
			#Result

	END

	ELSE

	BEGIN

		SELECT 
			SchemaCreateScript
		   ,TableCreateScript
		   ,HistoryTableCreateScript
		   ,SchemaJson
		   ,ISNULL(SelectColumnList, '*') AS SelectColumnList
		   ,UniqueConstraintIndicator
		   ,ISNULL(REPLACE(REPLACE([UniqueConstraintColumns], '[', ''), ']', ''), '') AS [UniqueConstraintColumns]
		FROM 
			#Result

	END

END TRY

BEGIN CATCH

	SET @Error = ERROR_MESSAGE();
	THROW 51000, @Error, 1 
END CATCH
