/****** Object:  StoredProcedure [DI].[usp_SchemaMapping_Get_Old]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_SchemaMapping_Get_Old]
GO
/****** Object:  StoredProcedure [DI].[usp_SchemaMapping_Get_Old]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [DI].[usp_SchemaMapping_Get_Old] (@TaskID INT)

AS

	SET NOCOUNT ON

	BEGIN TRY
		-- Declare variables 
		DECLARE 
			@HierarchicalSource INT -- 1 = True, 0 = False
			,@cols AS NVARCHAR(MAX)
			,@query AS NVARCHAR(MAX) -- Used when HierarchialSource = 1 
			,@interim NVARCHAR(MAX) -- Used to hold the interim result
			,@CollectionReference VARCHAR(MAX)

		-- Set @HierarchicalSource to 1 or 0 
		-- If it is a JSON file load 
		IF EXISTS 
			( 
				SELECT *
				FROM 
					DI.TaskProperty AS TP
				WHERE 
					TaskID = @TaskID
					AND TP.TaskPropertyValue = 'Json'
			)
		BEGIN 
			SET @HierarchicalSource = 1
		END 

		-- If it is a REST load (or add more connection types here) 
		ELSE IF EXISTS 
			(
				SELECT *
				FROM DI.Task T
					INNER JOIN DI.Connection C ON T.SourceConnectionID = C.ConnectionID
					INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
				WHERE 
					ConnectionTypeName IN ('REST API') -- add more connection types here 
					AND TaskID = @TaskID
			)
		BEGIN 
			SET @HierarchicalSource = 1
		END
		ELSE
		BEGIN
			SET @HierarchicalSource = 0
		END

		SELECT
			@CollectionReference = TP.TaskPropertyValue
		FROM
			DI.TaskProperty TP
			INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
		WHERE
			TP.TaskID = @TaskID
			AND TPT.TaskPropertyTypeName = 'Collection Reference'

		print @CollectionReference;
		-- Set dynamic columns. Used by HierarchialSource only. 
		SELECT
			@cols = STRING_AGG('"' + SourceColumnName + '"', ',')
		FROM 
			[DI].[FileColumnMapping]
		WHERE 
			TaskID = @TaskID

		-- If @HierarchicalSource  = 1 THEN output the @interim json result for hierarchial source
		IF @HierarchicalSource = 1
		BEGIN

			-- Add in the collection reference if there is one

			IF @CollectionReference IS NOT NULL

			BEGIN
				SET @interim = (SELECT 
									'TabularTranslator' AS [type]
									,Results.ColList AS [mappings]
									,@CollectionReference AS [collectionReference]
								FROM 
									(	
									SELECT 
										SourceColumnName AS [source.path]
										,[DI].[udf_ReplaceParquetColumnChars](TargetColumnName) AS [sink.name]
										,CASE 
											WHEN 
												FIDT.FileInterimDataTypeName = 'Date'
											THEN 
												'Datetime'
											WHEN 
												FIDT.FileInterimDataTypeName = 'Unicode String'
											THEN 
												'String'
											ELSE 
												FIDT.FileInterimDataTypeName
										END AS [sink.type]
									FROM 
										[DI].[FileColumnMapping] FCM
										INNER JOIN DI.FileInterimDataType AS FIDT ON FCM.FileInterimDataTypeID = FIDT.FileInterimDataTypeID
									WHERE 
										FCM.TaskID = @TaskID
										AND FCM.DeletedIndicator = 0
									FOR JSON PATH
									) Results (ColList)
								FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			END

			ELSE

			BEGIN

				SET @interim = (SELECT 
						'TabularTranslator' AS [type]
						,Results.ColList AS [mappings]
					FROM 
						(	
						SELECT 
							SourceColumnName AS [source.path]
							,[DI].[udf_ReplaceParquetColumnChars](TargetColumnName) AS [sink.name]
							,CASE 
								WHEN 
									FIDT.FileInterimDataTypeName = 'Date'
								THEN 
									'Datetime'
								WHEN 
									FIDT.FileInterimDataTypeName = 'Unicode String'
								THEN 
									'String'
								ELSE 
									FIDT.FileInterimDataTypeName
							END AS [sink.type]
						FROM 
							[DI].[FileColumnMapping] FCM
							INNER JOIN DI.FileInterimDataType AS FIDT ON FCM.FileInterimDataTypeID = FIDT.FileInterimDataTypeID
						WHERE 
							FCM.TaskID = @TaskID
							AND FCM.DeletedIndicator = 0
						FOR JSON PATH
						) Results (ColList)
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)

			END

			SELECT
				@interim AS [output]

		END
		-- ELSE IF @HierarchicalSource != 1 THEN output the @interim json result for tabular source
		ELSE
		BEGIN
			SET @interim = (SELECT
								'TabularTranslator' AS [type]
								,Results.ColList AS [mappings]
							FROM
								(
								SELECT
									FCM.SourceColumnName AS [source.name]
								   ,CASE 
										WHEN 
											FIDT.FileInterimDataTypeName = 'Date'
										THEN 
											'Datetime'
										WHEN 
											FIDT.FileInterimDataTypeName = 'Unicode String'
										THEN 
											'String'
										ELSE 
											FIDT.FileInterimDataTypeName
									END AS [source.type]
								   ,[DI].[udf_ReplaceParquetColumnChars](FCM.TargetColumnName) AS [sink.name]
								FROM 
									DI.FileColumnMapping AS FCM
									INNER JOIN DI.FileInterimDataType AS FIDT ON FCM.FileInterimDataTypeID = FIDT.FileInterimDataTypeID
								WHERE 
									FCM.TaskID = @TaskID
									AND FCM.DeletedIndicator = 0
								FOR	JSON PATH
								) Results (ColList)
							FOR	JSON PATH, WITHOUT_ARRAY_WRAPPER)

			-- Display @interim as 'output'
			SELECT
				@interim AS [output]

		END


	END TRY

	BEGIN CATCH

		DECLARE @Error VARCHAR(MAX)
		SET @Error = ERROR_MESSAGE()
		;
		THROW 51000, @Error, 1
	END CATCH
GO
