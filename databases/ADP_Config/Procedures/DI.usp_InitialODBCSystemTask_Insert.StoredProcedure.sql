/****** Object:  StoredProcedure [DI].[usp_InitialODBCSystemTask_Insert]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_InitialODBCSystemTask_Insert]
GO
/****** Object:  StoredProcedure [DI].[usp_InitialODBCSystemTask_Insert]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_InitialODBCSystemTask_Insert]

	@ScheduleName VARCHAR(50) = 'Once a day'

AS

SET NOCOUNT ON

-- This SP will create tasks and systems based on the initial config received from the client

BEGIN TRY

	-- Insert the system data

	DROP TABLE IF EXISTS #System

	CREATE TABLE #System
	(
		SystemID INT
		,SystemCode VARCHAR(50)
	)

	INSERT INTO DI.[System]
	(
		SystemCode
		,SystemName
		,SystemDescription
	)

	OUTPUT
		[INSERTED].SystemID
		,[INSERTED].SystemCode
	INTO
		#System

	SELECT DISTINCT
		REPLACE(REPLACE(REPLACE(DT.SourceSystem, ' ', ''), '-', ''), '_', '') AS SystemCode
		,DT.SourceSystem
		,DT.SourceSystem
	FROM
		[SRC].[ODBCTable] DT
		LEFT OUTER JOIN DI.[System] S ON DT.SourceSystem = S.SystemName
	WHERE
		S.SystemName IS NULL

	-- Insert the system properties--

	INSERT INTO DI.SystemProperty
	(
		SystemPropertyTypeID
		,SystemID
		,SystemPropertyValue
	)
	SELECT
		(SELECT SPT.SystemPropertyTypeID FROM DI.SystemPropertyType SPT WHERE SPT.SystemPropertyTypeName = 'Allow Schema Drift')
		,S.SystemID
		,'Y'
	FROM
		#System S
	UNION ALL
	SELECT
		(SELECT SPT.SystemPropertyTypeID FROM DI.SystemPropertyType SPT WHERE SPT.SystemPropertyTypeName = 'Target Schema')
		,S.SystemID
		,S.SystemCode
	FROM
		#System S
	
	-- Insert the tasks

	DROP TABLE IF EXISTS #Task

	CREATE TABLE #Task
	(
		TaskID INT
		,SystemID INT
		,TaskName VARCHAR(100)
	)

	INSERT INTO DI.Task
	(
		TaskName
	   ,TaskDescription
	   ,SystemID
	   ,ScheduleID
	   ,TaskTypeID
	   ,SourceConnectionID
	   ,ETLConnectionID
	   ,StageConnectionID
	   ,TargetConnectionID
	)
	OUTPUT
		[INSERTED].TaskID
		,[INSERTED].SystemID
		,[INSERTED].TaskName
	INTO
		#Task
	
	SELECT
		'Import ' + DT.[Schema] + '.' + DT.TableName + ' to stage'
		,'Import ' + DT.[Schema] + '.' + DT.TableName + ' to stage'
		,S.SystemID
		,(SELECT Sch.ScheduleID FROM DI.Schedule Sch WHERE Sch.ScheduleName = @ScheduleName)
		,TT.TaskTypeID
		,SourceC.ConnectionID
		,(SELECT C.ConnectionID FROM DI.[Connection] C WHERE C.ConnectionName = 'Databricks ETL Cluster')
		,(SELECT C.ConnectionID FROM DI.[Connection] C WHERE C.ConnectionName = 'ADS Data Lake')
		,(SELECT C.ConnectionID FROM DI.[Connection] C WHERE C.ConnectionName = 'ADS Staging')
	FROM
		[SRC].[ODBCTable] DT
		INNER JOIN DI.[System] S ON DT.SourceSystem = S.SystemName
		LEFT OUTER JOIN DI.Task T ON T.SystemID = S.SystemID
			AND T.TaskName = 'Import ' + DT.[Schema] + '.' + DT.TableName + ' to stage'
		INNER JOIN DI.TaskType TT ON TT.TaskTypeName = 'ODBC to SQL'
		INNER JOIN DI.[Connection] SourceC ON DT.SourceSystem = SourceC.ConnectionName
	WHERE
		T.TaskName IS NULL

	-- Insert the task properties

	INSERT INTO DI.TaskProperty
	(
		TaskPropertyTypeID
		,TaskID
		,TaskPropertyValue
	)

	-- Source SQL

	SELECT
		(SELECT TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'SQL Command')
		,T.TaskID
		,'SELECT * FROM ' + REPLACE(REPLACE(REPLACE(T.TaskName, 'Import ', '"'), '.', '"."'), ' to stage', '') + '"'
	FROM
		#Task T

	UNION ALL

	-- Target database

	SELECT
		(SELECT TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Target Database')
		,T.TaskID
		,'ADS_Stage'
	FROM
		#Task T
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID

	UNION ALL

	-- Target table

	SELECT
		(SELECT TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Target Table')
		,T.TaskID
		,'[' + REPLACE(REPLACE(REPLACE(T.TaskName, 'Import ', ''), '.', '_'), ' to stage', '') + ']'
	FROM
		#Task T
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID

	UNION ALL
	
	-- File Path in lake

	SELECT
		(SELECT TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Target File Path')
		,T.TaskID
		,'datalakestore/Raw/' + S.SystemCode + '/' + LEFT(Tabs.TableName, CHARINDEX('.', Tabs.TableName) - 1) + '/' + RIGHT(Tabs.TableName, LEN(Tabs.TableName) - CHARINDEX('.', Tabs.TableName)) + '/'
	FROM
		#Task T
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
		CROSS APPLY
		(
		SELECT
			REPLACE(REPLACE(T.TaskName, 'Import ', ''), ' to stage', '') AS TableName
		) Tabs

	UNION ALL

	-- File Name in lake

	SELECT
		(SELECT TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Target File Name')
		,T.TaskID
		,RIGHT(Tabs.TableName, LEN(Tabs.TableName) - CHARINDEX('.', Tabs.TableName)) + '.parquet'
	FROM
		#Task T
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
		CROSS APPLY
		(
		SELECT
			REPLACE(REPLACE(T.TaskName, 'Import ', ''), ' to stage', '') AS TableName
		) Tabs

	UNION ALL

	-- Load Type

	SELECT
		(SELECT TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Task Load Type')
		,T.TaskID
		,'Full'
	FROM
		#Task T
		INNER JOIN DI.[System] S ON T.SystemID = S.SystemID


	-- Insert File Coloum Mapping for ODBC Task
	INSERT INTO [DI].[FileColumnMapping]
    (
		[TaskID]
		,[SourceColumnName]
		,[TargetColumnName]
		,[FileInterimDataTypeID]
		,[DataLength]
		,[EnabledIndicator]
		,[DeletedIndicator]
		,[DateCreated]
		,[CreatedBy]
    )
	SELECT
		Tp.TaskID as TaskId,
		TC.[ColumnName] as SourceColumnName,
		TRIM(REPLACE(TC.[ColumnName],' ','')) as TargetColumnName,	
		FDT.FileInterimDataTypeID as [FileInterimDataTypeID], 
		CASE
			WHEN TC.DataPrecision > 36 AND TC.DataScale > 0
			THEN '36' + ',' + CAST(TC.DataScale AS VARCHAR(50))
			WHEN TC.DataPrecision < 36 AND TC.DataScale > 0
			THEN CAST(TC.DataPrecision AS VARCHAR(50)) + ',' + CAST(TC.DataScale AS VARCHAR(50))
			WHEN (TRIM(TC.[DataType]) LIKE '%char%' OR TRIM(TC.[DataType]) = 'string' OR TRIM(TC.[DataType]) = 'uniqueidentifier' OR TRIM(TC.[DataType]) = 'guid') AND TC.[DataLength] <> -1
			THEN CAST(TC.[DataLength] AS NVARCHAR(50))
		END AS [DataLength],
		1 as [EnabledIndicator],
		0 as [DeletedIndicator],
		GETDATE() as [DateCreated],
		'Initial System Generated' as [CreatedBy]	   
	FROM 
		[SRC].[ODBCTableColumn] TC 
		INNER JOIN [SRC].[ODBCTable] DT ON TC.[Schema] = DT.[Schema]
			AND TC.TableName = DT.TableName
		INNER JOIN [DI].[FileInterimDataType] FDT ON
		CASE 
			WHEN TRIM(TC.[DataType]) = 'bit'
			THEN 'Boolean'
			WHEN TRIM(TC.[DataType]) = 'bigint'
			THEN 'Int64'		
			WHEN TRIM(TC.[DataType]) = 'int'
			THEN 'Int32'
			WHEN TRIM(TC.[DataType]) = 'smallint'
			THEN 'Int16'
			WHEN TRIM(TC.[DataType]) = 'tinyint'
			THEN 'Int16'
			WHEN TRIM(TC.[DataType]) IN('float', 'money')
			THEN 'Double'
			WHEN TRIM(TC.[DataType]) LIKE 'n%char%'
			THEN 'Unicode String'
			WHEN TRIM(TC.[DataType]) LIKE '%char%' OR TRIM(TC.[DataType]) = 'uniqueidentifier'
			THEN 'String'
			WHEN TRIM(TC.[DataType]) LIKE '%binary%' OR TRIM(TC.[DataType]) IN('geography', 'geometry', 'image', 'timestamp',' hierarchyid')
			THEN 'Byte'
			WHEN TRIM(TC.[DataType]) IN('numeric', 'decimal')
			THEN 'Decimal'
			ELSE TRIM(TC.[DataType])
		END = TRIM(FDT.FileInterimDataTypeName)
		INNER JOIN DI.TaskProperty TP on TP.TaskPropertyValue = 'SELECT * FROM "' + TC.[Schema] + '"."' + TC.[TableName] + '"'	

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
