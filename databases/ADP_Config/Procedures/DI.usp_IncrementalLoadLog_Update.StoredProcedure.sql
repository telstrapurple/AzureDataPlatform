/****** Object:  StoredProcedure [DI].[usp_IncrementalLoadLog_Update]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_IncrementalLoadLog_Update]
GO
CREATE PROCEDURE [DI].[usp_IncrementalLoadLog_Update] 
(
	@TaskID INT
	,@TaskInstanceID INT
	,@IncrementalColumn NVARCHAR(100)
	,@Latestvalue NVARCHAR(100)
	,@SuccessIndicator BIT
	,@SourceType NVARCHAR(100)
)

AS

SET NOCOUNT ON

DECLARE @TableName NVARCHAR(500)

BEGIN TRY

IF(@SourceType in ('ODBC','SQL', 'REST'))

	BEGIN

		SELECT
			@TableName = 
			(
			SELECT 
				MAX(
				CASE
					WHEN ([TPTarget].[SQLCommand] IS NOT NULL
						AND [TPTarget].[SQLCommand] NOT LIKE '%FROM%')
						OR TPTarget.TaskType LIKE 'REST%'
					THEN COALESCE([TPTarget].[TargetSchemaOverwrite], [TPTarget].[TargetSchema]) + '.' + [TPTarget].[TargetTable]
					WHEN [TPTarget].[SQLCommand] IS NOT NULL
					THEN REPLACE(REPLACE(REPLACE(RIGHT([TPTarget].[SQLCommand], LEN([TPTarget].[SQLCommand]) - CHARINDEX('FROM ', [TPTarget].[SQLCommand]) - 4), '"', ''), '[', ''), ']', '')
					ELSE TRIM(REPLACE(REPLACE(REPLACE(TPTarget.SourceTable, '"', ''), '[', ''), ']', ''))
				END)
			FROM 
				(
				SELECT 
					TP.TaskID
					,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'SQL Command' THEN TP.TaskPropertyValue END) AS [SQLCommand]
					,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Source Table' THEN TP.TaskPropertyValue END) AS [SourceTable]
					,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Target Schema Overwrite' THEN TP.TaskPropertyValue END) AS [TargetSchemaOverwrite]
					,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Target Table' THEN TP.TaskPropertyValue END) AS [TargetTable]
					,MAX(TT.TaskTypeName) AS [TaskType]
					,MAX(SP.SystemPropertyValue) AS [TargetSchema]
				FROM 
					DI.Task T
					INNER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
					INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
					INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
					INNER JOIN DI.SystemProperty SP ON S.SystemID = SP.SystemID
					INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
					AND SPT.SystemPropertyTypeName = 'Target Schema'
					INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
				WHERE
					TPT.TaskPropertyTypeName IN('SQL Command', 'Source Table', 'Target Schema Overwrite', 'Target Table') 
					AND TP.TaskID = @TaskID
				GROUP BY 
					TP.TaskID
				) TPTarget
			)
	END

	IF @SourceType = 'CRM'

	BEGIN

		SELECT @TableName = (
							SELECT 
								TP.TaskPropertyValue AS [EntityName]
							FROM 
								[DI].[TaskProperty] TP				
								INNER JOIN DI.TaskPropertyType TPT 
									ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID 
									AND TPT.TaskPropertyTypeName = 'Entity Name'
									AND TP.TaskID = @TaskID 
							)

	END 

	IF @SourceType = 'File'

	BEGIN

		SELECT @TableName = (
							SELECT 
								TP.TaskPropertyValue AS [EntityName]
							FROM 
								[DI].[TaskProperty] TP				
								INNER JOIN DI.TaskPropertyType TPT 
									ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID 
									AND TPT.TaskPropertyTypeName = 'Target Table'
									AND TP.TaskID = @TaskID 
							)

	END 

	UPDATE 
		[DI].[IncrementalLoadLog]
	SET 
		[EntityName] = @TableName
		,[IncrementalColumn] = @IncrementalColumn
		,[LatestValue] = @Latestvalue
		,[SuccessIndicator] = @SuccessIndicator
		,[DateModified] = GETDATE()
	WHERE 
		[TaskInstanceID] = @TaskInstanceID

	-- Insert the row if the UPDATE statement failed.  
	IF (@@rowcount = 0)

	BEGIN
		INSERT INTO [DI].[IncrementalLoadLog]
		(
			[TaskInstanceID]
			,[EntityName]
			,[IncrementalColumn]
			,[LatestValue]
			,[SuccessIndicator]
			,[DateCreated]
		)
		VALUES
		(
			@TaskInstanceID
			,@TableName
			,@IncrementalColumn
			,@Latestvalue
			,@SuccessIndicator
			,GETDATE()
		)
	END

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1
END CATCH
GO