/*
#### ADS GO FAST ###

Description
--------------------

This stored procedure is used to generate the Task Instance Config. This is the parameters that gest passed into the Datafactory for a Task

Input
--------------------

@TaskInstanceID:		TaskInstance ID for the task

*/


CREATE OR ALTER PROCEDURE [DI].[usp_TaskInstanceConfig_Get]
(
	@TaskInstanceID INT
)

AS

DECLARE
	@OutputMessage NVARCHAR(MAX)
	,@PreviousTargetFilePath VARCHAR(500)
	,@TaskType NVARCHAR(MAX)
	,@RunType NVARCHAR(MAX)
	,@TargetSchema VARCHAR(50)
	,@Error VARCHAR(MAX)
	,@TaskLoadType NVARCHAR(MAX)
	,@HistoryTable NVARCHAR(MAX)
	,@BatchColumn NVARCHAR(MAX)
	,@UseSQLCDC NVARCHAR(MAX)
	,@UseDeltaLake NVARCHAR(MAX)
	,@IncrementalValue NVARCHAR(MAX)
	,@IncrementalColumn NVARCHAR(MAX)
	,@IgnoreSourceKey NVARCHAR(MAX)
	,@DataLakeStagingCreate NVARCHAR(MAX)
	,@SourceQuery NVARCHAR(MAX)
	,@SourceParameterList NVARCHAR(MAX)
	,@ParameterName NVARCHAR(MAX)
	,@ParameterValue NVARCHAR(MAX)
	,@IsolationLevel NVARCHAR(MAX)

SET NOCOUNT ON

BEGIN TRY

	-- Get the Task Type
	SELECT 
		@TaskType = TaskType
	FROM
		DI.vw_TaskInstanceConfig
	WHERE
		TaskInstanceID = @TaskInstanceID
		AND ConnectionStage = 'Source'

	--Raise an error if there is no task type
	IF @TaskType IS NULL
	BEGIN
		SET @Error = 'Could not find Task Type for TaskInstance ID ' + CAST( @TaskInstanceID as VARCHAR(255) );
		THROW 51000, @Error, 1 
	END

	-- Get the Run Type
	SELECT 
		@RunType = TT.RunType
	FROM 
		DI.TaskType TT 
		INNER JOIN DI.Task T ON TT.TaskTypeID = T.TaskTypeID
		INNER JOIN DI.TaskInstance TI ON T.TaskID = TI.TaskID
	WHERE 
		TaskInstanceID = @TaskInstanceID

	--Raise an error if there is no run type
	IF @RunType IS NULL
	BEGIN
		SET @Error = 'Could not find Run Type for TaskInstance ID ' + CAST( @TaskInstanceID as VARCHAR(255) );
		THROW 51000, @Error, 1 
	END

	--Check if the target schema has been set on the task level
	SELECT 
		@TargetSchema = TaskPropertyValue
	FROM
		DI.vw_TaskInstanceConfig
	WHERE
		TaskInstanceID = @TaskInstanceID
		AND ConnectionStage = 'Target'
		AND TaskPropertyType = 'Target Schema Overwrite'

	IF TRIM(ISNULL(@TargetSchema, '')) = ''

	BEGIN

		--Set the target schema from the system properties
		SELECT 
			@TargetSchema = SystemPropertyValue
		FROM
			DI.vw_TaskInstanceConfig
		WHERE
			TaskInstanceID = @TaskInstanceID
			AND ConnectionStage = 'Target'
			AND SystemPropertyType = 'Target Schema'

	END

	--Raise an error if there is no target schema
	IF TRIM(ISNULL(@TargetSchema, '')) = '' AND @RunType != 'Script'
	BEGIN
		SET @Error = 'Make sure to capture a Target Schema in the task or system properties';
		THROW 51000, @Error, 1 
	END

	-- Get parameters for validation 
	SELECT 
		@UseSQLCDC = MAX( CASE WHEN VTIC.TaskPropertyType = 'Use SQL CDC' THEN VTIC.TaskPropertyValue END ) 
		,@TaskLoadType  = MAX( CASE WHEN VTIC.TaskPropertyType = 'Task Load Type' THEN VTIC.TaskPropertyValue END ) 
		,@HistoryTable  = MAX( CASE WHEN VTIC.TaskPropertyType = 'History Table' THEN VTIC.TaskPropertyValue END ) 
		,@BatchColumn   = MAX( CASE WHEN VTIC.TaskPropertyType = 'Batch Column' THEN VTIC.TaskPropertyValue END ) 
		,@UseDeltaLake   = MAX( CASE WHEN VTIC.TaskPropertyType = 'Use Delta Lake' THEN VTIC.TaskPropertyValue END ) 
		,@IncrementalValue   = MAX( CASE WHEN VTIC.TaskPropertyType = 'Incremental Value' THEN VTIC.TaskPropertyValue END ) 
		,@IncrementalColumn   = MAX( CASE WHEN VTIC.TaskPropertyType = 'Incremental Column' THEN VTIC.TaskPropertyValue END ) 
		,@IgnoreSourceKey   = MAX( CASE WHEN VTIC.TaskPropertyType = 'Ignore Source Key' THEN VTIC.TaskPropertyValue END ) 
		,@DataLakeStagingCreate = MAX( CASE WHEN VTIC.TaskPropertyType = 'Data Lake Staging Create' THEN VTIC.TaskPropertyValue END ) 
		,@IsolationLevel = ISNULL(MAX( CASE WHEN VTIC.ConnectionPropertyType = 'Isolation Level' THEN VTIC.ConnectionPropertyValue END ), '') 
	FROM 
		DI.vw_TaskInstanceConfig VTIC 
	WHERE 
		VTIC.TaskInstanceID = @TaskInstanceID

	/**
	* --------------------------
	* PERFORM VALIDATION - START
	* --------------------------
	*/
	-- DATABASE, ODBC, CRM, FILE, AND REST API RUN TYPE VALIDATION
	IF @RunType LIKE 'Database to%' OR @RunType LIKE 'ODBC to%' OR @RunType LIKE 'CRM to%' OR @RunType LIKE 'File to%' OR @RunType LIKE 'REST to%'
	BEGIN 
		IF @DataLakeStagingCreate = 'True'
		BEGIN
			IF @UseDeltaLake != 'Y'
			BEGIN
				SET @Error = '"Use Delta Lake" must be set to "Y" when Data Lake Staging Create is "True".';
				THROW 51000, @Error, 1 
			END
		END
	END

	-- DATABASE, ODBC and CRM RUN TYPE VALIDATION
	IF @RunType LIKE 'Database to%' OR @RunType LIKE 'ODBC to%' OR @RunType LIKE 'CRM to%' 
	BEGIN 
		-- Incremental Load Validation
		IF @TaskLoadType = 'Incremental'
		BEGIN 
			IF @IncrementalValue IS NULL
			BEGIN
				SET @Error = 'Incremental value cannot be NULL when Task Load Type is "Incremental".';
				THROW 51000, @Error, 1 
			END 

			IF @IncrementalColumn IS NULL
			BEGIN
				SET @Error = 'Incremental column cannot be NULL when Task Load Type is "Incremental".';
				THROW 51000, @Error, 1 
			END 

			IF @UseDeltaLake != 'Y'
			BEGIN 
				SET @Error = '"Use Delta Lake" must be set to "Y" when Task Load Type is "Incremental".';
				THROW 51000, @Error, 1
			END
		END

		IF @HistoryTable = 'True'
		BEGIN
			IF @IgnoreSourceKey = 'Y'
			BEGIN 
				SET @Error = '"Ignore Source Key" must be set to "N" when History Table is "True".';
				THROW 51000, @Error, 1
			END 
		END

		IF @UseSQLCDC = 'True'
		BEGIN
			IF @IgnoreSourceKey = 'Y'
			BEGIN 
				SET @Error = '"Ignore Source Key" must be set to "N" when Use SQL CDC is "True".';
				THROW 51000, @Error, 1
			END 

			IF @BatchColumn IS NOT NULL OR @BatchColumn != ''
			BEGIN 
				SET @Error = '"Batch Column" must be blank when Use SQL CDC is "True".';
				THROW 51000, @Error, 1
			END 

			IF @TaskLoadType = 'Incremental'
			BEGIN 
				SET @Error = '"Task Load Type" cannot be "Incremental" when Use SQL CDC is "True".';
				THROW 51000, @Error, 1
			END
		END

		IF (@BatchColumn IS NOT NULL OR @BatchColumn != '') AND @TaskLoadType = 'Incremental'
		BEGIN
			SET @Error = 'You cannot enable both Incremental and Batch Loads. Please either leave "Batch Column" as blank, or change "Task Load Type" to "Full".';
			THROW 51000, @Error, 1
		END
	END
	
	/**
	* --------------------------
	* PERFORM VALIDATION - END
	* --------------------------
	*/

	-- Get the file path for the previous successful task execution
	SELECT
		@OutputMessage = DFL.OutputMessage
	FROM 
		DI.DataFactoryLog DFL
		INNER JOIN 
		(
		SELECT
			MAX(TIPrevious.TaskInstanceID) AS LatestTaskInstanceID
		FROM
			DI.TaskInstance TI
			INNER JOIN DI.Task T ON TI.TaskID = T.TaskID
			INNER JOIN DI.TaskInstance TIPrevious ON T.TaskID = TIPrevious.TaskID
			INNER JOIN DI.TaskResult TR ON TIPrevious.TaskResultID = TR.TaskResultID
		WHERE
			TI.TaskInstanceID = @TaskInstanceID
			AND TIPrevious.TaskInstanceID <> @TaskInstanceID
			AND TR.TaskResultName = 'Success'
		) LatestTI ON DFL.TaskInstanceID = LatestTI.LatestTaskInstanceID
	WHERE
		DFL.LogType = 'End'
		AND ISJSON(DFL.OutputMessage) = 1


	IF LEN(@OutputMessage) > 0

	BEGIN
		IF @TaskType LIKE '%to SQL'
		BEGIN 
			SELECT 
				@PreviousTargetFilePath = JSON_VALUE(LogOutput.[value], '$.TargetFilePath')
			FROM
				OPENJSON(@OutputMessage) LogOutput
			WHERE
				JSON_VALUE(LogOutput.[value], '$.ConnectionStage') = 'Staging'
		END
		IF @TaskType LIKE '%to Lake'
		BEGIN
			SELECT 
				@PreviousTargetFilePath = JSON_VALUE(LogOutput.[value], '$.TargetFilePath')
			FROM
				OPENJSON(@OutputMessage) LogOutput
			WHERE
				JSON_VALUE(LogOutput.[value], '$.ConnectionStage') = 'Target'
		END
		IF @TaskType LIKE '%to Synapse'
		BEGIN 
			SELECT 
				@PreviousTargetFilePath = JSON_VALUE(LogOutput.[value], '$.TargetFilePath')
			FROM
				OPENJSON(@OutputMessage) LogOutput
			WHERE
				JSON_VALUE(LogOutput.[value], '$.ConnectionStage') = 'Staging'
		END
	END
	ELSE
	BEGIN
		SELECT @PreviousTargetFilePath = ''
	END

	/*

	This section is used to do parameter substitution in the source SQL query or API Body if it exists

	*/

	SELECT
		@SourceQuery = MAX(CASE 
								WHEN VTIC.TaskPropertyType = 'SQL Command' OR VTIC.TaskPropertyType = 'Body'
								THEN VTIC.TaskPropertyValue 
								WHEN VTIC.TaskPropertyType = 'Source Table'
								THEN 'SELECT * FROM "' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '"."') + '"'
						   END)
		,@SourceParameterList = MAX(CASE WHEN VTIC.TaskPropertyType IN('Method Parameters', 'SQL Parameters') THEN VTIC.TaskPropertyValue END)
	FROM
		DI.vw_TaskInstanceConfig VTIC
	WHERE
		VTIC.TaskInstanceID = @TaskInstanceID
		AND VTIC.ConnectionStage = 'Source' 
		AND VTIC.TaskPropertyType IN('Source Table', 'SQL Command', 'Body', 'Method Parameters', 'SQL Parameters')
		AND VTIC.TaskPropertyValue IS NOT NULL 

	IF @SourceParameterList IS NOT NULL AND @SourceQuery NOT LIKE '%@%'

	BEGIN 

		SET @Error = 'Parameter definitions defined but no parameters found in your source query';
		THROW 51000, @Error, 1

	END 

	IF @SourceQuery LIKE '%@%'

	BEGIN

		--Get the parameter names and values into a temp table

		DROP TABLE IF EXISTS #Params

		SELECT
			MAX(CASE WHEN Params.RowID = 1 THEN Params.ParameterValue END) AS [ParameterName]
			,MAX(CASE WHEN Params.RowID = 2 THEN Params.ParameterValue END) AS [ParameterValue]
		INTO
			#Params
		FROM
			(
			SELECT
				ROW_NUMBER() OVER(PARTITION BY Params.[value] ORDER BY Params.[value]) AS RowID
				,Params.[value] AS [Parameter]
				,ParamVals.[value] AS [ParameterValue]
			FROM
				STRING_SPLIT(@SourceParameterList, ';') Params
				CROSS APPLY STRING_SPLIT(Params.[value], '=') ParamVals
			) Params
		GROUP BY 
			[Parameter]

		-- Loop through all parameters

		DECLARE Param_Cursor CURSOR FAST_FORWARD READ_ONLY FOR 
		SELECT
			ParameterName
			,ParameterValue
		FROM 
			#Params

		OPEN Param_Cursor

		FETCH NEXT FROM Param_Cursor INTO @ParameterName, @ParameterValue

		WHILE @@fetch_status = 0

		BEGIN

			DECLARE @ParamValue TABLE(ParameterValue VARCHAR(MAX))

			DELETE FROM @ParamValue

			-- Check if the value uses the [LatestValue] placeholder

			IF @ParameterValue LIKE '%[LatestValue]%'

			BEGIN

				--Get the latest incremental value

				IF @RunType LIKE 'Database to%'

				BEGIN
	
					SELECT @IncrementalValue = [DI].[udf_GetIncrementalLoadValue](@TaskInstanceID,'SQL')

				END

				ELSE

				BEGIN
	
					 SELECT @IncrementalValue = [DI].[udf_GetIncrementalLoadValue](@TaskInstanceID,'') 

				END

				SELECT @IncrementalValue = CASE WHEN @IncrementalValue = '''1900-01-01''' THEN 'NULL' ELSE ISNULL(@IncrementalValue, 'NULL') END

				SELECT @ParameterValue = REPLACE(@ParameterValue, '[LatestValue]', @IncrementalValue)

			END

			-- Try and execute the query. If it fails, use a string literal

			BEGIN

				BEGIN TRY

					INSERT INTO @ParamValue
					EXEC('SELECT ' + @ParameterValue)

				END TRY

				BEGIN CATCH

					INSERT INTO @ParamValue
					SELECT @ParameterValue

				END CATCH

			END

			SET @SourceQuery = REPLACE(@SourceQuery, @ParameterName, (SELECT ParameterValue FROM @ParamValue))
		
			FETCH NEXT FROM Param_Cursor INTO @ParameterName, @ParameterValue

		END

		CLOSE Param_Cursor
		DEALLOCATE Param_Cursor

	END

	/*
		Description:
		Check the run type to determine the required output. Please add new RunTypes below. 
		
		Input:
		@RunType

		Output:
		Resultset for taskinstanceId's run type
	*/

	-- Database Run Types
	IF @RunType LIKE 'Database to%'

	BEGIN
		
		-- Get cdc all and net query 
		DECLARE @CDCQueryAll AS NVARCHAR(MAX) = ''
				,@CDCQueryNet AS NVARCHAR(MAX) = ''
				,@Latest_LSN AS VARCHAR(MAX) = NULL
				,@Schema_Name AS NVARCHAR(MAX) = ''
				,@Table_Name AS NVARCHAR(MAX) = ''
				,@Source_Table_Full_Name AS NVARCHAR(MAX) = ''
				,@ColumnList AS NVARCHAR(MAX)
				,@ConnectionID AS INT

		-- Set the transaction isolation level if there is one

		IF LEN(@IsolationLevel) > 0
		BEGIN

			SET @SourceQuery = 'SET TRANSACTION ISOLATION LEVEL ' + @IsolationLevel + ';' + @SourceQuery

		END
		
		-- If True, then get CDC statements
		IF @UseSQLCDC = 'True'
		BEGIN
			
			-- Get Latest LSN value
			DROP TABLE IF EXISTS #tempTable
			CREATE TABLE #tempTable (LatestLSNValue VARCHAR(MAX) NULL)
			INSERT INTO #tempTable (LatestLSNValue)
			EXEC [DI].[usp_CDC_LSN_Get] @TaskInstanceID

			SET @Latest_LSN = (SELECT LatestLSNValue FROM #tempTable)
			
			SET @Source_Table_Full_Name = (SELECT MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table' THEN VTIC.TaskPropertyValue END ) FROM DI.vw_TaskInstanceConfig VTIC WHERE VTIC.TaskInstanceID = @TaskInstanceID)
			IF @Source_Table_Full_Name IS NULL 
			BEGIN
				SET @Error = 'Source Table name needs to be populated if ''Use SQL CDC is True''.';
				THROW 51000, @Error, 1 
			END

			-- Remove any square brackets
			SET @Source_Table_Full_Name = REPLACE(REPLACE(@Source_Table_Full_Name, '[', ''), ']', '')

			-- If source table full name does not have schema name, then use dbo.
			IF CHARINDEX('.', @Source_Table_Full_Name) = 0 -- not found
			BEGIN
				SET @Source_Table_Full_Name = 'dbo.' + @Source_Table_Full_Name 
			END

			-- Get schema name
			SET @Schema_Name = SUBSTRING(@Source_Table_Full_Name, 1, CHARINDEX('.', @Source_Table_Full_Name)-1);

			-- Get table name
			SET @Table_Name = SUBSTRING(@Source_Table_Full_Name, CHARINDEX('.', @Source_Table_Full_Name) + 1 , LEN(@Source_Table_Full_Name) - CHARINDEX('.', @Source_Table_Full_Name));
			
			-- Get connection ID
			SET @ConnectionID = (SELECT MAX(T.SourceConnectionID) FROM DI.Task T INNER JOIN DI.TaskInstance TI ON T.TaskID = TI.TaskID WHERE TI.TaskInstanceID = @TaskInstanceID)
	 
			-- Get column list 
			SET @ColumnList = (SELECT STRING_AGG(ColumnName, ',') AS ColumnString FROM [SRC].[DatabaseTableColumn] WHERE [Schema] = @Schema_Name AND [TableName] = @Table_Name AND [ConnectionID] = @ConnectionID)
			
			
			-- Get CDC Query (All) for History Table
			SET @CDCQueryAll = 'DECLARE 
									@MAX_LSN AS BINARY(10)
									,@PREVIOUS_LSN AS BINARY(10)
								SET 
									@MAX_LSN = (SELECT sys.fn_cdc_get_max_lsn());' + 
								CASE 
									WHEN @Latest_LSN IS NULL THEN 
								'SET @PREVIOUS_LSN = (SELECT sys.fn_cdc_get_min_lsn(''' + @Schema_Name + '_' + @Table_Name + '''));'
									ELSE 
								'
								IF(' + @Latest_LSN + ' < sys.fn_cdc_get_min_lsn(''' + @Schema_Name + '_' + @Table_Name + '''))
								BEGIN
									SET @PREVIOUS_LSN = (SELECT sys.fn_cdc_get_min_lsn(''' + @Schema_Name + '_' + @Table_Name + '''));
								END

								ELSE

								BEGIN
									SET @PREVIOUS_LSN = (SELECT sys.fn_cdc_increment_lsn(' + CONVERT(VARCHAR(MAX), @Latest_LSN, 1) + '));
								END
								'
								END 
								+ 
								
								'
								SELECT 
									AllChanges.__$start_lsn,
									AllChanges.__$seqval,
									AllChanges.__$operation,
									AllChanges.__$update_mask,
									sys.fn_cdc_map_lsn_to_time ( AllChanges.__$start_lsn ) as __$lsn_timestamp,
									query.__$updated_columns,
									' + @ColumnList + '
								FROM 
									[cdc].[fn_cdc_get_all_changes_' + @Schema_Name + '_' + @Table_Name + '](@PREVIOUS_LSN, @MAX_LSN, ''all'') AllChanges
									OUTER APPLY
									(
									SELECT
										STRING_AGG(subquery.__$updated_columns, '','') AS __$updated_columns
									FROM
										(
										SELECT
											CASE
												WHEN sys.fn_cdc_has_column_changed(''' + @Schema_Name + '_' + @Table_Name + ''', COLUMN_NAME, AllChanges.__$update_mask) = 1 THEN COLUMN_NAME
											END AS __$updated_columns
										FROM 
											INFORMATION_SCHEMA.COLUMNS
										WHERE 
											TABLE_SCHEMA = N'''+ @Schema_Name + '''
											AND TABLE_NAME = N''' + @Table_Name + ''') subquery
									) query';
		
		SET @CDCQueryNet = 
		CASE 
			WHEN @Latest_LSN IS NULL THEN 
				'SELECT ' + @ColumnList + ' FROM ' + @Schema_Name + '.' + @Table_Name
			ELSE
				'DECLARE 
					@MAX_LSN AS BINARY(10)
					,@PREVIOUS_LSN AS BINARY(10);
				SET 
					@MAX_LSN = (SELECT sys.fn_cdc_get_max_lsn());
				IF(' + @Latest_LSN + ' < sys.fn_cdc_get_min_lsn(''' + @Schema_Name + '_' + @Table_Name + '''))
				BEGIN
					SET @PREVIOUS_LSN = (SELECT sys.fn_cdc_get_min_lsn(''' + @Schema_Name + '_' + @Table_Name + '''));
				END

				ELSE

				BEGIN
					SET @PREVIOUS_LSN = (SELECT sys.fn_cdc_increment_lsn(' + CONVERT(VARCHAR(MAX), @Latest_LSN, 1) + '));
				END
				
				SELECT 
					__$start_lsn,
					__$operation,
					__$update_mask,
					sys.fn_cdc_map_lsn_to_time ( __$start_lsn ) as __$lsn_timestamp,
					' + @ColumnList + ' 
				FROM 
					[cdc].[fn_cdc_get_net_changes_' + @Schema_Name + '_' + @Table_Name + '](@PREVIOUS_LSN, @MAX_LSN ,''all with mask'')'
			END
		END
		 

		-- Get the final result set
		SELECT
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
			,'Y' AS [AutoSchemaDetection]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Target Schema' THEN VTIC.SystemPropertyValue END), '') AS [TargetSchema]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Allow Schema Drift' THEN VTIC.SystemPropertyValue END), 'N') AS [AllowSchemaDrift]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Include SQL Data Lineage' THEN VTIC.SystemPropertyValue END), 'N') AS [IncludeSQLDataLineage]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Delta Lake Retention Days' THEN VTIC.SystemPropertyValue END), '7') AS [DeltaLakeRetentionDays]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Partition Count' THEN VTIC.SystemPropertyValue END), '10') AS [PartitionCount]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name' THEN VTIC.ConnectionPropertyValue END), '') AS [SecretName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Service Endpoint' THEN VTIC.ConnectionPropertyValue END), '') AS [ServiceEndpoint]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks URL' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksURL]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks Cluster ID' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksClusterID]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' THEN @SourceQuery END), '') AS [SQLCommand]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table' THEN VTIC.TaskPropertyValue WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'SQL Command' THEN SUBSTRING(VTIC.TaskPropertyValue, CHARINDEX('FROM ', VTIC.TaskPropertyValue) + 5, LEN(VTIC.TaskPropertyValue)) END), '') AS [SourceTable]
			,ISNULL(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND MAX(FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END) <> @PreviousTargetFilePath THEN @PreviousTargetFilePath END, '') AS [PreviousTargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END END), '') AS [TargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN CASE WHEN RIGHT(FP.TargetFilePath,1) = '/' THEN SUBSTRING(FP.TargetFilePath,1,LEN(FP.TargetFilePath)-1) + '_cdc/' ELSE FP.TargetFilePath + '_cdc/' END + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END END), '') AS [TargetCDCFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Use Delta Lake' THEN VTIC.TaskPropertyValue ELSE '' END), 'N') AS [UseDeltaLakeIndicator]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Delta/') END), '') AS [TargetDeltaFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Staging/') END), '') AS [TargetStagingFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Name' THEN VTIC.TaskPropertyValue END), '') AS [TargetFileName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Database' THEN VTIC.TaskPropertyValue ELSE '' END), 'ADS_Stage') AS [TargetDatabase]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') THEN FP.[TargetTableName] END), '') AS [TargetTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Table' THEN '[tempstage].' + REPLACE(FP.[TargetTableName], '].[', '_') END), '') AS [TargetTempTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Task Load Type' THEN VTIC.TaskPropertyValue END), 'Full') AS [LoadType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Column' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Value' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalValue]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Batch Column' THEN VTIC.TaskPropertyValue END), '') AS [BatchColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Stored Procedure' THEN VTIC.TaskPropertyValue END), '') AS [StoredProcedureName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Databricks notebook' THEN VTIC.TaskPropertyValue END), '') AS [DatabricksNotebook]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Use SQL CDC' THEN VTIC.TaskPropertyValue END), '') AS [UseSQLCDC]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'History Table' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [HistoryTable]
			,ISNULL(CASE WHEN VTIC.ConnectionStage = 'Source' THEN @CDCQueryAll ELSE '' END,'') AS [CDCQueryAll]
			,ISNULL(CASE WHEN VTIC.ConnectionStage = 'Source' THEN @CDCQueryNet ELSE '' END,'') AS [CDCQueryNet]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Create' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [DataLakeStagingCreate]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Partitions' THEN VTIC.TaskPropertyValue ELSE '0' END), '0') AS [DataLakeStagingPartitions]
			,ISNULL(MIN(CASE WHEN VTIC.SystemPropertyType = 'ACL Permissions' AND ISNULL(VTIC.SystemPropertyValue, '') <> '' THEN '' WHEN VTIC.TaskPropertyType = 'ACL Permissions' AND VTIC.TaskPropertyValue IS NOT NULL THEN VTIC.TaskPropertyValue END), '') AS [ACLPermissions]
		FROM	
			DI.vw_TaskInstanceConfig VTIC
			OUTER APPLY
			(
			SELECT 
				MAX(CASE 
						WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Data Lake Date Mask Overwrite' 
						THEN VTIC.TaskPropertyValue 
					END) AS [DataLakeDateMaskOverwrite]
			FROM
				DI.vw_TaskInstanceConfig VTIC
			WHERE
				VTIC.TaskInstanceID = @TaskInstanceID
			) FPA 
			CROSS APPLY
			(
			SELECT
				CASE 
					WHEN VTIC.TaskPropertyType = 'Target File Path' 
					THEN 
					CASE
						WHEN RIGHT(VTIC.TaskPropertyValue, 1) <> '/'
						THEN VTIC.TaskPropertyValue + '/'
						ELSE VTIC.TaskPropertyValue
					END
				END AS [TargetFilePath]
				,CASE 
					WHEN FPA.DataLakeDateMaskOverwrite IS NOT NULL AND FPA.DataLakeDateMaskOverwrite <> ''
					THEN FPA.DataLakeDateMaskOverwrite
					WHEN VTIC.ConnectionPropertyType = 'Data Lake Date Mask' 
					THEN VTIC.ConnectionPropertyValue 
				END AS [DataLakeDateMask]
				,CASE
					WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Table'
					THEN '[' + @TargetSchema + '].[' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '_') + ']'
				END AS [TargetTableName]
				,CASE 
					WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'SQL Command' AND VTIC.TaskPropertyValue IS NOT NULL 
					THEN VTIC.TaskPropertyValue 
					WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table'
					THEN 'SELECT * FROM "' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '"."') + '"'
				END AS SQLCommand
			) FP
		WHERE
			VTIC.TaskInstanceID = @TaskInstanceID
		GROUP BY 
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
		ORDER BY 
			CASE
				WHEN VTIC.ConnectionStage = 'Source'
				THEN 1
				WHEN VTIC.ConnectionStage = 'ETL'
				THEN 2
				WHEN VTIC.ConnectionStage = 'Staging'
				THEN 3
				WHEN VTIC.ConnectionStage = 'Target'
				THEN 4
			END

	END

	-- File Run Types
	ELSE IF @RunType LIKE 'File to%'

	BEGIN

		-- Get the final result set

		SELECT
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
			,'N' AS [AutoSchemaDetection]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Target Schema' THEN VTIC.SystemPropertyValue END), '') AS [TargetSchema]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Allow Schema Drift' THEN VTIC.SystemPropertyValue END), 'N') AS [AllowSchemaDrift]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Include SQL Data Lineage' THEN VTIC.SystemPropertyValue END), 'N') AS [IncludeSQLDataLineage]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Delta Lake Retention Days' THEN VTIC.SystemPropertyValue END), '7') AS [DeltaLakeRetentionDays]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name' THEN VTIC.ConnectionPropertyValue END), '') AS [SecretName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'File System User Name' THEN VTIC.ConnectionPropertyValue END), '') AS [FileSystemUserName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Service Endpoint' THEN VTIC.ConnectionPropertyValue END), '') AS [ServiceEndpoint]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Account Key Secret Name' THEN VTIC.ConnectionPropertyValue END), '') AS [AccountKeySecretName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'File Share' THEN VTIC.ConnectionPropertyValue END), '') AS [FileShare]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Storage Account Name' THEN VTIC.ConnectionPropertyValue END), '') AS [StorageAccountName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks URL' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksURL]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks Cluster ID' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksClusterID]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental File Load Type' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalFileLoadType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Column' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Value' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalValue]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'File Load Order By' THEN VTIC.TaskPropertyValue END), '') AS [FileLoadOrderBy]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Force File Reload' THEN VTIC.TaskPropertyValue END), '') AS [ForceFileReload]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Host' THEN VTIC.TaskPropertyValue END), '') AS [Host]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Compression Type' THEN VTIC.TaskPropertyValue END), '') AS [CompressionType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Column Delimiter' THEN VTIC.TaskPropertyValue END), '') AS [ColumnDelimiter]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Row Delimiter' THEN VTIC.TaskPropertyValue END), '') AS [RowDelimiter]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Encoding' THEN VTIC.TaskPropertyValue END), 'UTF-8') AS [Encoding]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Escape Character' THEN VTIC.TaskPropertyValue END), '') AS [EscapeCharacter]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Quote Character' THEN VTIC.TaskPropertyValue END), '') AS [QuoteCharacter]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'First Row as Header' THEN VTIC.TaskPropertyValue ELSE '' END), 'true') AS [FirstRowAsHeader]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Null Value' THEN VTIC.TaskPropertyValue END), '') AS [NullValue]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Skip Line Count' THEN VTIC.TaskPropertyValue END), '') AS [SkipLineCount]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source File Path' THEN VTIC.TaskPropertyValue END), '') AS [SourceFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source File Name' THEN VTIC.TaskPropertyValue END), '') AS [SourceFileName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'File Format' THEN VTIC.TaskPropertyValue END), '') AS [SourceFileFormat]
			,ISNULL(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND MAX(FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END) <> @PreviousTargetFilePath THEN @PreviousTargetFilePath END, '') AS [PreviousTargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END END), '') AS [TargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Use Delta Lake' THEN VTIC.TaskPropertyValue ELSE '' END), 'N') AS [UseDeltaLakeIndicator]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Delta/') END), '') AS [TargetDeltaFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Staging/') END), '') AS [TargetStagingFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Name' THEN VTIC.TaskPropertyValue END), '') AS [TargetFileName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Database' THEN VTIC.TaskPropertyValue ELSE '' END), 'ADS_Stage') AS [TargetDatabase]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target Table' THEN FP.[TargetTableName] END), '') AS [TargetTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target Table' THEN '[tempstage].' + REPLACE(FP.[TargetTableName], '].[', '_') END), '') AS [TargetTempTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Task Load Type' THEN VTIC.TaskPropertyValue END), 'Full') AS [LoadType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Stored Procedure' THEN VTIC.TaskPropertyValue END), '') AS [StoredProcedureName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Databricks notebook' THEN VTIC.TaskPropertyValue END), '') AS [DatabricksNotebook]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'History Table' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [HistoryTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Use SQL CDC' THEN VTIC.TaskPropertyValue END), '') AS [UseSQLCDC]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Create' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [DataLakeStagingCreate]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Partitions' THEN VTIC.TaskPropertyValue ELSE '0' END), '0') AS [DataLakeStagingPartitions]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Remove Duplicates' THEN VTIC.TaskPropertyValue ELSE 'N' END), 'N') AS [RemoveDuplicates]
			,ISNULL(MIN(CASE WHEN VTIC.SystemPropertyType = 'ACL Permissions' AND ISNULL(VTIC.SystemPropertyValue, '') <> '' THEN '' WHEN VTIC.TaskPropertyType = 'ACL Permissions' AND VTIC.TaskPropertyValue IS NOT NULL THEN VTIC.TaskPropertyValue END), '') AS [ACLPermissions]
		FROM
			DI.vw_TaskInstanceConfig VTIC
			OUTER APPLY
			(
			SELECT 
				MAX(CASE 
						WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Data Lake Date Mask Overwrite' 
						THEN VTIC.TaskPropertyValue 
					END) AS [DataLakeDateMaskOverwrite]
			FROM
				DI.vw_TaskInstanceConfig VTIC
			WHERE
				VTIC.TaskInstanceID = @TaskInstanceID
			) FPA 
			CROSS APPLY
			(
			SELECT
				CASE 
					WHEN VTIC.TaskPropertyType = 'Target File Path' 
					THEN 
					CASE
						WHEN RIGHT(VTIC.TaskPropertyValue, 1) <> '/'
						THEN VTIC.TaskPropertyValue + '/'
						ELSE VTIC.TaskPropertyValue
					END
				END AS [TargetFilePath]
				,CASE 
					WHEN FPA.DataLakeDateMaskOverwrite IS NOT NULL AND FPA.DataLakeDateMaskOverwrite <> ''
					THEN FPA.DataLakeDateMaskOverwrite
					WHEN VTIC.ConnectionPropertyType = 'Data Lake Date Mask' 
					THEN VTIC.ConnectionPropertyValue 
				END AS [DataLakeDateMask]
				,CASE
					WHEN VTIC.TaskPropertyType = 'Target Table'
					THEN '[' + @TargetSchema + '].[' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '_') + ']'
				END AS [TargetTableName]
			) FP
		WHERE
			VTIC.TaskInstanceID = @TaskInstanceID
		GROUP BY 
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
		ORDER BY 
			CASE
				WHEN VTIC.ConnectionStage = 'Source'
				THEN 1
				WHEN VTIC.ConnectionStage = 'ETL'
				THEN 2
				WHEN VTIC.ConnectionStage = 'Staging'
				THEN 3
				WHEN VTIC.ConnectionStage = 'Target'
				THEN 4
			END

	END

	-- Script Run Type
	ELSE IF @RunType = 'Script'

	BEGIN

		-- Get the final result set

		SELECT
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Target Schema' THEN VTIC.SystemPropertyValue END), '') AS [TargetSchema]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Allow Schema Drift' THEN VTIC.SystemPropertyValue END), 'N') AS [AllowSchemaDrift]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Include SQL Data Lineage' THEN VTIC.SystemPropertyValue END), 'N') AS [IncludeSQLDataLineage]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Partition Count' THEN VTIC.SystemPropertyValue END), '10') AS [PartitionCount]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name' THEN VTIC.ConnectionPropertyValue END), '') AS [SecretName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Service Endpoint' THEN VTIC.ConnectionPropertyValue END), '') AS [ServiceEndpoint]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks URL' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksURL]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks Cluster ID' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksClusterID]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Stored Procedure' THEN VTIC.TaskPropertyValue END), '') AS [StoredProcedureName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Databricks notebook' THEN VTIC.TaskPropertyValue END), '') AS [DatabricksNotebook]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Script Config' THEN VTIC.TaskPropertyValue END), '') AS [ScriptConfig]
		FROM
			DI.vw_TaskInstanceConfig VTIC
		WHERE
			VTIC.TaskInstanceID = @TaskInstanceID
		GROUP BY 
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
		ORDER BY 
			CASE
				WHEN VTIC.ConnectionStage = 'Source'
				THEN 1
				WHEN VTIC.ConnectionStage = 'ETL'
				THEN 2
				WHEN VTIC.ConnectionStage = 'Staging'
				THEN 3
				WHEN VTIC.ConnectionStage = 'Target'
				THEN 4
			END

	END

	-- CRM Run Types
	ELSE IF @RunType LIKE 'CRM to%'

	BEGIN

		-- Get the final result set

		SELECT
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
			,'N' AS [AutoSchemaDetection]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Target Schema' THEN VTIC.SystemPropertyValue END), '') AS [TargetSchema]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Allow Schema Drift' THEN VTIC.SystemPropertyValue END), 'N') AS [AllowSchemaDrift]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Include SQL Data Lineage' THEN VTIC.SystemPropertyValue END), 'N') AS [IncludeSQLDataLineage]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Delta Lake Retention Days' THEN VTIC.SystemPropertyValue END), '7') AS [DeltaLakeRetentionDays]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Partition Count' THEN VTIC.SystemPropertyValue END), '10') AS [PartitionCount]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name' THEN VTIC.ConnectionPropertyValue END), '') AS [SecretName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Service Endpoint' THEN VTIC.ConnectionPropertyValue END), '') AS [ServiceEndpoint]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks URL' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksURL]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks Cluster ID' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksClusterID]
			,ISNULL(MAX(FP.SQLCommand), '') AS [SQLCommand]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table' THEN VTIC.TaskPropertyValue WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'SQL Command' THEN SUBSTRING(VTIC.TaskPropertyValue, CHARINDEX('FROM ', VTIC.TaskPropertyValue) + 5, LEN(VTIC.TaskPropertyValue)) END), '') AS [SourceTable]
			,ISNULL(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND MAX(FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END) <> @PreviousTargetFilePath THEN @PreviousTargetFilePath END, '') AS [PreviousTargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END END), '') AS [TargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Use Delta Lake' THEN VTIC.TaskPropertyValue ELSE '' END), 'N') AS [UseDeltaLakeIndicator]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Delta/') END), '') AS [TargetDeltaFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Staging/') END), '') AS [TargetStagingFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Name' THEN VTIC.TaskPropertyValue END), '') AS [TargetFileName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Database' THEN VTIC.TaskPropertyValue ELSE '' END), 'ADS_Stage') AS [TargetDatabase]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') THEN FP.[TargetTableName] END), '') AS [TargetTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Table' THEN '[tempstage].' + REPLACE(FP.[TargetTableName], '].[', '_') END), '') AS [TargetTempTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Task Load Type' THEN VTIC.TaskPropertyValue END), 'Full') AS [LoadType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Column' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Value' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalValue]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Batch Column' THEN VTIC.TaskPropertyValue END), '') AS [BatchColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Stored Procedure' THEN VTIC.TaskPropertyValue END), '') AS [StoredProcedureName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Databricks notebook' THEN VTIC.TaskPropertyValue END), '') AS [DatabricksNotebook]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' THEN'CRM'END),'') AS [SourceConnectionType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.ConnectionPropertyType = 'CRM User Name KeyVault Secret' THEN VTIC.ConnectionPropertyValue END), '') AS [CRMUserNameKeyVaultSecret]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.ConnectionPropertyType = 'CRM Password KeyVault Secret' THEN VTIC.ConnectionPropertyValue END), '') AS [CRMPasswordKeyVaultSecret]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'History Table' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [HistoryTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Use SQL CDC' THEN VTIC.TaskPropertyValue END), '') AS [UseSQLCDC]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Create' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [DataLakeStagingCreate]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Partitions' THEN VTIC.TaskPropertyValue ELSE '0' END), '0') AS [DataLakeStagingPartitions]
			,ISNULL(MIN(CASE WHEN VTIC.SystemPropertyType = 'ACL Permissions' AND ISNULL(VTIC.SystemPropertyValue, '') <> '' THEN '' WHEN VTIC.TaskPropertyType = 'ACL Permissions' AND VTIC.TaskPropertyValue IS NOT NULL THEN VTIC.TaskPropertyValue END), '') AS [ACLPermissions]
		FROM
			DI.vw_TaskInstanceConfig VTIC
			OUTER APPLY
			(
			SELECT 
				MAX(CASE 
						WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Data Lake Date Mask Overwrite' 
						THEN VTIC.TaskPropertyValue 
					END) AS [DataLakeDateMaskOverwrite]
			FROM
				DI.vw_TaskInstanceConfig VTIC
			WHERE
				VTIC.TaskInstanceID = @TaskInstanceID
			) FPA 
			CROSS APPLY
			(
			SELECT
				CASE 
					WHEN VTIC.TaskPropertyType = 'Target File Path' 
					THEN 
					CASE
						WHEN RIGHT(VTIC.TaskPropertyValue, 1) <> '/'
						THEN VTIC.TaskPropertyValue + '/'
						ELSE VTIC.TaskPropertyValue
					END
				END AS [TargetFilePath]
				,CASE 
					WHEN FPA.DataLakeDateMaskOverwrite IS NOT NULL AND FPA.DataLakeDateMaskOverwrite <> ''
					THEN FPA.DataLakeDateMaskOverwrite
					WHEN VTIC.ConnectionPropertyType = 'Data Lake Date Mask' 
					THEN VTIC.ConnectionPropertyValue 
				END AS [DataLakeDateMask]
				,CASE
					WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Table'
					THEN '[' + @TargetSchema + '].[' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '_') + ']'
				END AS [TargetTableName]
				,CASE 
					WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'SQL Command' AND VTIC.TaskPropertyValue IS NOT NULL 
					THEN VTIC.TaskPropertyValue 
					WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table'
					THEN 'SELECT * FROM "' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '"."') + '"'
				END AS SQLCommand
			) FP
		WHERE
			VTIC.TaskInstanceID = @TaskInstanceID
		GROUP BY 
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
		ORDER BY 
			CASE
				WHEN VTIC.ConnectionStage = 'Source'
				THEN 1
				WHEN VTIC.ConnectionStage = 'ETL'
				THEN 2
				WHEN VTIC.ConnectionStage = 'Staging'
				THEN 3
				WHEN VTIC.ConnectionStage = 'Target'
				THEN 4
			END

	END
		
	-- ODBC Run Types
	ELSE IF @RunType LIKE 'ODBC to%'
	
	BEGIN

		-- Get the final result set

		SELECT
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
			,'N' AS [AutoSchemaDetection]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Target Schema' THEN VTIC.SystemPropertyValue END), '') AS [TargetSchema]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Allow Schema Drift' THEN VTIC.SystemPropertyValue END), 'N') AS [AllowSchemaDrift]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Include SQL Data Lineage' THEN VTIC.SystemPropertyValue END), 'N') AS [IncludeSQLDataLineage]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Delta Lake Retention Days' THEN VTIC.SystemPropertyValue END), '7') AS [DeltaLakeRetentionDays]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Partition Count' THEN VTIC.SystemPropertyValue END), '10') AS [PartitionCount]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name' THEN VTIC.ConnectionPropertyValue END), '') AS [SecretName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Service Endpoint' THEN VTIC.ConnectionPropertyValue END), '') AS [ServiceEndpoint]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks URL' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksURL]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks Cluster ID' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksClusterID]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret - Connection String' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretConnectionString]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret - Password' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretPassword]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret - User Name' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretUserName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' THEN @SourceQuery END), '') AS [SQLCommand]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table' THEN VTIC.TaskPropertyValue WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'SQL Command' THEN SUBSTRING(VTIC.TaskPropertyValue, CHARINDEX('FROM ', VTIC.TaskPropertyValue) + 5, LEN(VTIC.TaskPropertyValue)) END), '') AS [SourceTable]
			,ISNULL(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND MAX(FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END) <> @PreviousTargetFilePath THEN @PreviousTargetFilePath END, '') AS [PreviousTargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END END), '') AS [TargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Use Delta Lake' THEN VTIC.TaskPropertyValue ELSE '' END), 'N') AS [UseDeltaLakeIndicator]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Delta/') END), '') AS [TargetDeltaFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Staging/') END), '') AS [TargetStagingFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Name' THEN VTIC.TaskPropertyValue END), '') AS [TargetFileName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Database' THEN VTIC.TaskPropertyValue ELSE '' END), 'ADS_Stage') AS [TargetDatabase]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') THEN FP.[TargetTableName] END), '') AS [TargetTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Table' THEN '[tempstage].' + REPLACE(FP.[TargetTableName], '].[', '_') END), '') AS [TargetTempTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Task Load Type' THEN VTIC.TaskPropertyValue END), 'Full') AS [LoadType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Column' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Value' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalValue]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Batch Column' THEN VTIC.TaskPropertyValue END), '') AS [BatchColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Stored Procedure' THEN VTIC.TaskPropertyValue END), '') AS [StoredProcedureName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Databricks notebook' THEN VTIC.TaskPropertyValue END), '') AS [DatabricksNotebook]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'History Table' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [HistoryTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Use SQL CDC' THEN VTIC.TaskPropertyValue END), '') AS [UseSQLCDC]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Create' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [DataLakeStagingCreate]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Partitions' THEN VTIC.TaskPropertyValue ELSE '0' END), '0') AS [DataLakeStagingPartitions]
			,ISNULL(MIN(CASE WHEN VTIC.SystemPropertyType = 'ACL Permissions' AND ISNULL(VTIC.SystemPropertyValue, '') <> '' THEN '' WHEN VTIC.TaskPropertyType = 'ACL Permissions' AND VTIC.TaskPropertyValue IS NOT NULL THEN VTIC.TaskPropertyValue END), '') AS [ACLPermissions]
		FROM
			DI.vw_TaskInstanceConfig VTIC
			OUTER APPLY
			(
			SELECT 
				MAX(CASE 
						WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Data Lake Date Mask Overwrite' 
						THEN VTIC.TaskPropertyValue 
					END) AS [DataLakeDateMaskOverwrite]
			FROM
				DI.vw_TaskInstanceConfig VTIC
			WHERE
				VTIC.TaskInstanceID = @TaskInstanceID
			) FPA 
			CROSS APPLY
			(
			SELECT
				CASE 
					WHEN VTIC.TaskPropertyType = 'Target File Path' 
					THEN 
					CASE
						WHEN RIGHT(VTIC.TaskPropertyValue, 1) <> '/'
						THEN VTIC.TaskPropertyValue + '/'
						ELSE VTIC.TaskPropertyValue
					END
				END AS [TargetFilePath]
				,CASE 
					WHEN FPA.DataLakeDateMaskOverwrite IS NOT NULL AND FPA.DataLakeDateMaskOverwrite <> ''
					THEN FPA.DataLakeDateMaskOverwrite
					WHEN VTIC.ConnectionPropertyType = 'Data Lake Date Mask' 
					THEN VTIC.ConnectionPropertyValue 
				END AS [DataLakeDateMask]
				,CASE
					WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Table'
					THEN '[' + @TargetSchema + '].[' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '_') + ']'
				END AS [TargetTableName]
				,CASE 
					WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'SQL Command' AND VTIC.TaskPropertyValue IS NOT NULL 
					THEN VTIC.TaskPropertyValue 
					WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table'
					THEN 'SELECT * FROM "' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '"."') + '"'
				END AS SQLCommand
			) FP
		WHERE
			VTIC.TaskInstanceID = @TaskInstanceID
		GROUP BY 
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
		ORDER BY 
			CASE
				WHEN VTIC.ConnectionStage = 'Source'
				THEN 1
				WHEN VTIC.ConnectionStage = 'ETL'
				THEN 2
				WHEN VTIC.ConnectionStage = 'Staging'
				THEN 3
				WHEN VTIC.ConnectionStage = 'Target'
				THEN 4
			END
	END



	-- REST Run Types
	ELSE IF @RunType LIKE 'REST to%'

	BEGIN
		-- Get the final result set

		SELECT
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
			,'N' AS [AutoSchemaDetection]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Target Schema' THEN VTIC.SystemPropertyValue END), '') AS [TargetSchema]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Allow Schema Drift' THEN VTIC.SystemPropertyValue END), 'N') AS [AllowSchemaDrift]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Include SQL Data Lineage' THEN VTIC.SystemPropertyValue END), 'N') AS [IncludeSQLDataLineage]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Delta Lake Retention Days' THEN VTIC.SystemPropertyValue END), '7') AS [DeltaLakeRetentionDays]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name' THEN VTIC.ConnectionPropertyValue END), '') AS [SecretName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret - Password' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretPassword]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret - User Name' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretUserName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Service Endpoint' THEN VTIC.ConnectionPropertyValue END), '') AS [ServiceEndpoint]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Authorization Endpoint' THEN VTIC.ConnectionPropertyValue END), '') AS [AuthorizationEndpoint]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name - Client ID' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretNameClientID]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name - Client Secret' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretNameClientSecret]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks URL' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksURL]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks Cluster ID' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksClusterID]
			,ISNULL(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND MAX(FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END) <> @PreviousTargetFilePath THEN @PreviousTargetFilePath END, '') AS [PreviousTargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END END), '') AS [TargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Use Delta Lake' THEN VTIC.TaskPropertyValue ELSE '' END), 'N') AS [UseDeltaLakeIndicator]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Delta/') END), '') AS [TargetDeltaFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Staging/') END), '') AS [TargetStagingFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Name' THEN VTIC.TaskPropertyValue END), '') AS [TargetFileName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Database' THEN VTIC.TaskPropertyValue ELSE '' END), 'ADS_Stage') AS [TargetDatabase]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target Table' THEN FP.[TargetTableName] END), '') AS [TargetTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target Table' THEN '[tempstage].' + REPLACE(FP.[TargetTableName], '].[', '_') END), '') AS [TargetTempTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Task Load Type' THEN VTIC.TaskPropertyValue END), 'Full') AS [LoadType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Column' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Value' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalValue]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Relative URL' THEN VTIC.TaskPropertyValue END), '') AS [RelativeURL]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Token Request Additional Body' THEN VTIC.TaskPropertyValue END), '') AS [TokenRequestAdditionalBody]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'History Table' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [HistoryTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Use SQL CDC' THEN VTIC.TaskPropertyValue END), '') AS [UseSQLCDC]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Create' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [DataLakeStagingCreate]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Partitions' THEN VTIC.TaskPropertyValue ELSE '0' END), '0') AS [DataLakeStagingPartitions]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Method' THEN VTIC.TaskPropertyValue END), '') AS [Method]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' THEN @SourceQuery END), '') AS [Body]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Remove Duplicates' THEN VTIC.TaskPropertyValue ELSE 'N' END), 'N') AS [RemoveDuplicates]
			,ISNULL(MIN(CASE WHEN VTIC.SystemPropertyType = 'ACL Permissions' AND ISNULL(VTIC.SystemPropertyValue, '') <> '' THEN '' WHEN VTIC.TaskPropertyType = 'ACL Permissions' AND VTIC.TaskPropertyValue IS NOT NULL THEN VTIC.TaskPropertyValue END), '') AS [ACLPermissions]
		FROM
			DI.vw_TaskInstanceConfig VTIC
			OUTER APPLY
			(
			SELECT 
				MAX(CASE 
						WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Data Lake Date Mask Overwrite' 
						THEN VTIC.TaskPropertyValue 
					END) AS [DataLakeDateMaskOverwrite]
			FROM
				DI.vw_TaskInstanceConfig VTIC
			WHERE
				VTIC.TaskInstanceID = @TaskInstanceID
			) FPA 
			CROSS APPLY
			(
			SELECT
				CASE 
					WHEN VTIC.TaskPropertyType = 'Target File Path' 
					THEN 
					CASE
						WHEN RIGHT(VTIC.TaskPropertyValue, 1) <> '/'
						THEN VTIC.TaskPropertyValue + '/'
						ELSE VTIC.TaskPropertyValue
					END
				END AS [TargetFilePath]
				,CASE 
					WHEN FPA.DataLakeDateMaskOverwrite IS NOT NULL AND FPA.DataLakeDateMaskOverwrite <> ''
					THEN FPA.DataLakeDateMaskOverwrite
					WHEN VTIC.ConnectionPropertyType = 'Data Lake Date Mask' 
					THEN VTIC.ConnectionPropertyValue 
				END AS [DataLakeDateMask]
				,CASE
					WHEN VTIC.TaskPropertyType = 'Target Table'
					THEN '[' + @TargetSchema + '].[' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '_') + ']'
				END AS [TargetTableName]
			) FP
		WHERE
			VTIC.TaskInstanceID = @TaskInstanceID
		GROUP BY 
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
		ORDER BY 
			CASE
				WHEN VTIC.ConnectionStage = 'Source'
				THEN 1
				WHEN VTIC.ConnectionStage = 'ETL'
				THEN 2
				WHEN VTIC.ConnectionStage = 'Staging'
				THEN 3
				WHEN VTIC.ConnectionStage = 'Target'
				THEN 4
			END
	END


		-- Delta Run Types
	ELSE IF @RunType LIKE 'Delta to%'
	
	BEGIN

		-- Get the final result set

		SELECT
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
			,'N' AS [AutoSchemaDetection]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Target Schema' THEN VTIC.SystemPropertyValue END), '') AS [TargetSchema]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Allow Schema Drift' THEN VTIC.SystemPropertyValue END), 'N') AS [AllowSchemaDrift]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Include SQL Data Lineage' THEN VTIC.SystemPropertyValue END), 'N') AS [IncludeSQLDataLineage]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Delta Lake Retention Days' THEN VTIC.SystemPropertyValue END), '7') AS [DeltaLakeRetentionDays]
			,ISNULL(MAX(CASE WHEN VTIC.SystemPropertyType = 'Partition Count' THEN VTIC.SystemPropertyValue END), '10') AS [PartitionCount]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret Name' THEN VTIC.ConnectionPropertyValue END), '') AS [SecretName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Service Endpoint' THEN VTIC.ConnectionPropertyValue END), '') AS [ServiceEndpoint]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks URL' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksURL]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'Databricks Cluster ID' THEN VTIC.ConnectionPropertyValue END), '') AS [DatabricksClusterID]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret - Connection String' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretConnectionString]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret - Password' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretPassword]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionPropertyType = 'KeyVault Secret - User Name' THEN VTIC.ConnectionPropertyValue END), '') AS [KeyVaultSecretUserName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' THEN @SourceQuery END), '') AS [SQLCommand]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table' THEN VTIC.TaskPropertyValue WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'SQL Command' THEN SUBSTRING(VTIC.TaskPropertyValue, CHARINDEX('FROM ', VTIC.TaskPropertyValue) + 5, LEN(VTIC.TaskPropertyValue)) END), '') AS [SourceTable]
			--,ISNULL(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND MAX(FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END) <> @PreviousTargetFilePath THEN @PreviousTargetFilePath END, '') AS [PreviousTargetFilePath]
			,ISNULL(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND MAX( CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END) <> @PreviousTargetFilePath THEN @PreviousTargetFilePath END, '') AS [PreviousTargetFilePath]
			
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN FP.TargetFilePath + CASE WHEN FP.DataLakeDateMask IS NOT NULL THEN FORMAT(SYSUTCDATETIME(), FP.DataLakeDateMask) + '/' END END), '') AS [TargetFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Use Delta Lake' THEN VTIC.TaskPropertyValue ELSE '' END), 'N') AS [UseDeltaLakeIndicator]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Delta/') END), '') AS [TargetDeltaFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Path' THEN REPLACE(FP.TargetFilePath, '/Raw/', '/Staging/') END), '') AS [TargetStagingFilePath]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Target File Name' THEN VTIC.TaskPropertyValue END), '') AS [TargetFileName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Database' THEN VTIC.TaskPropertyValue ELSE '' END), 'ADS_Stage') AS [TargetDatabase]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage IN('Staging', 'Target') THEN FP.[TargetTableName] END), '') AS [TargetTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Table' THEN '[tempstage].' + REPLACE(FP.[TargetTableName], '].[', '_') END), '') AS [TargetTempTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Task Load Type' THEN VTIC.TaskPropertyValue END), 'Full') AS [LoadType]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Column' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Incremental Value' THEN VTIC.TaskPropertyValue END), '') AS [IncrementalValue]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Batch Column' THEN VTIC.TaskPropertyValue END), '') AS [BatchColumn]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Stored Procedure' THEN VTIC.TaskPropertyValue END), '') AS [StoredProcedureName]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Databricks notebook' THEN VTIC.TaskPropertyValue END), '') AS [DatabricksNotebook]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'History Table' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [HistoryTable]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Use SQL CDC' THEN VTIC.TaskPropertyValue END), '') AS [UseSQLCDC]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Create' THEN VTIC.TaskPropertyValue ELSE '' END), 'False') AS [DataLakeStagingCreate]
			,ISNULL(MAX(CASE WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Data Lake Staging Partitions' THEN VTIC.TaskPropertyValue ELSE '0' END), '0') AS [DataLakeStagingPartitions]
		FROM
			DI.vw_TaskInstanceConfig VTIC
			OUTER APPLY
			(
			SELECT 
				MAX(CASE 
						WHEN VTIC.ConnectionStage IN('Staging', 'Target') AND VTIC.TaskPropertyType = 'Data Lake Date Mask Overwrite' 
						THEN VTIC.TaskPropertyValue 
					END) AS [DataLakeDateMaskOverwrite]
			FROM
				DI.vw_TaskInstanceConfig VTIC
			WHERE
				VTIC.TaskInstanceID = @TaskInstanceID
			) FPA 
			CROSS APPLY
			(
			SELECT
				CASE 
					WHEN VTIC.TaskPropertyType = 'Target File Path' 
					THEN 
					CASE
						WHEN RIGHT(VTIC.TaskPropertyValue, 1) <> '/'
						THEN VTIC.TaskPropertyValue + '/'
						ELSE VTIC.TaskPropertyValue
					END
				END AS [TargetFilePath]
				,CASE 
					WHEN FPA.DataLakeDateMaskOverwrite IS NOT NULL AND FPA.DataLakeDateMaskOverwrite <> ''
					THEN FPA.DataLakeDateMaskOverwrite
					WHEN VTIC.ConnectionPropertyType = 'Data Lake Date Mask' 
					THEN VTIC.ConnectionPropertyValue 
				END AS [DataLakeDateMask]
				,CASE
					WHEN VTIC.ConnectionStage = 'Target' AND VTIC.TaskPropertyType = 'Target Table'
					THEN '[' + @TargetSchema + '].[' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '_') + ']'
				END AS [TargetTableName]
				,CASE 
					WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'SQL Command' AND VTIC.TaskPropertyValue IS NOT NULL 
					THEN VTIC.TaskPropertyValue 
					WHEN VTIC.ConnectionStage = 'Source' AND VTIC.TaskPropertyType = 'Source Table'
					THEN 'SELECT * FROM "' + REPLACE(REPLACE(REPLACE(REPLACE(VTIC.TaskPropertyValue, '"', ''), '[', ''), ']', ''), '.', '"."') + '"'
				END AS SQLCommand
			) FP
		WHERE
			VTIC.TaskInstanceID = @TaskInstanceID
		GROUP BY 
			VTIC.TaskInstanceID
			,VTIC.ConnectionStage
			,VTIC.AuthenticationType
		ORDER BY 
			CASE
				WHEN VTIC.ConnectionStage = 'Source'
				THEN 1
				WHEN VTIC.ConnectionStage = 'ETL'
				THEN 2
				WHEN VTIC.ConnectionStage = 'Staging'
				THEN 3
				WHEN VTIC.ConnectionStage = 'Target'
				THEN 4
			END
	END

END TRY

BEGIN CATCH
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
