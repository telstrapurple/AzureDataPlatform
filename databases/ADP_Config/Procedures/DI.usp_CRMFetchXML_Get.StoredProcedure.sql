/****** Object:  StoredProcedure [DI].[usp_CRMFetchXML_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_CRMFetchXML_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_CRMFetchXML_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [DI].[usp_CRMFetchXML_Get] (@TaskInstanceID INT)

AS

SET NOCOUNT ON

BEGIN TRY

	DECLARE @TaskID INT

	SELECT 
		@TaskID = TaskID 
	FROM
		DI.TaskInstance TI
	WHERE
		TI.TaskInstanceID = @TaskInstanceID

	IF EXISTS (
					SELECT 
						TP.TaskPropertyValue AS Result				
					FROM 
						[DI].[TaskProperty] TP INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID					
					WHERE
						TP.TaskID =  @TaskID
						and TPT.TaskPropertyTypeName = 'Fetch XML' and TP.DeletedIndicator = 0
				)
		BEGIN
					SELECT 
						TP.TaskPropertyValue AS Result				
					FROM 
						[DI].[TaskProperty] TP INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID					
					WHERE
						TP.TaskID =  @TaskID
						and TPT.TaskPropertyTypeName = 'Fetch XML'and TP.DeletedIndicator = 0
		END

	ELSE 
		BEGIN

			SELECT
				MAX(
					'<fetch><entity name="' + Props.EntityName + '">'
				) +
				STRING_AGG('<attribute name="' + SourceColumnName + '" />', '') +
				MAX(
				CASE
					WHEN Props.[TaskLoadType] = 'FULL' -- Filter condition based on the load type
					THEN ''
					ELSE '<filter type="and"><condition attribute="' + Props.[Incremental Column] + '" operator="on-or-after" value="' + CAST(Props.IncrementalValue AS VARCHAR(50)) + '" /> </filter>'
				END
				+ '		</entity></fetch>'
				) AS Result
			FROM
				[DI].[FileColumnMapping] FCM
				CROSS APPLY
				--Gets the Properties for the task Instance 
					(
					SELECT 
						MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Entity Name' THEN TP.TaskPropertyValue END) AS [EntityName]
						,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Incremental Column' THEN TP.TaskPropertyValue END) AS [Incremental Column]
						,MAX(CASE WHEN TPT.TaskPropertyTypeName = 'Task Load Type' THEN TP.TaskPropertyValue END) AS [TaskLoadType]
						,MAX(IV.IncrementalValue) as [IncrementalValue]
					FROM 
						[DI].[TaskProperty] TP
						INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID
						CROSS APPLY 
						(
						SELECT 
							[DI].[udf_GetIncrementalLoadValue] (@TaskInstanceID, 'CRM') AS IncrementalValue							
						)  IV 
					WHERE
						--FCM.TaskID = @TaskID AND
						TP.TaskID =  @TaskID
					) Props
					WHERE
						FCM.TaskID = @TaskID


		END

	END TRY

	BEGIN CATCH

		DECLARE @Error VARCHAR(MAX)
		SET @Error = ERROR_MESSAGE()
		;
		THROW 51000, @Error, 1
	END CATCH
GO
