/****** Object:  StoredProcedure [DI].[usp_TargetIncrementalColumnMapping_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_TargetIncrementalColumnMapping_Get]
GO
CREATE  PROCEDURE [DI].[usp_TargetIncrementalColumnMapping_Get] (@TaskID INT,@SourceType NVARCHAR (500))

AS

DECLARE @TargetColumnName  NVARCHAR (500)

	SET NOCOUNT ON

	BEGIN TRY

	If @SourceType = 'SQL'

	BEGIN
			
		SELECT @TargetColumnName = TaskPropertyValue					
			FROM 
				[DI].[TaskProperty] TP
				INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID 
				where 
					TaskID = @TaskID   and 
					TaskPropertyTypeName = 'Incremental Column'

	END

	ELSE

	BEGIN
		SELECT @TargetColumnName = [TargetColumnName]
				FROM [DI].[FileColumnMapping]
					WHERE TaskID = @TaskID 
					and 
					[SourceColumnName] = 
					(
						SELECT TaskPropertyValue					
							FROM 
								[DI].[TaskProperty] TP
								INNER JOIN DI.TaskPropertyType TPT ON TP.TaskPropertyTypeID = TPT.TaskPropertyTypeID 
								where 
									TaskID = @TaskID  and 
									TaskPropertyTypeName = 'Incremental Column'
					)

	END

	SELECT @TargetColumnName as [TargetColumnName]

	END TRY

	BEGIN CATCH

		DECLARE @Error VARCHAR(MAX)
		SET @Error = ERROR_MESSAGE()
		;
		THROW 51000, @Error, 1
	END CATCH
GO