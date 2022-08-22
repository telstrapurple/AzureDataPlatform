/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Insert]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_FileLoadLog_Insert]
GO
/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Insert]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [DI].[usp_FileLoadLog_Insert]
(
	@TaskInstanceID INT
	,@FilePath NVARCHAR(max)
	,@FileName NVARCHAR(max)
	,@LastModified datetimeoffset(7)
)

AS

SET NOCOUNT ON

BEGIN TRY
		-- Get TaskID
		DECLARE @TaskID INT;
		SET @TaskID = 
		(
			SELECT 
				MAX(TaskID)
			FROM 
				DI.TaskInstance
			WHERE 
				TaskInstanceID = @TaskInstanceID 
		)

		-- Check if exist 
		IF NOT EXISTS (SELECT 1 FROM DI.FileLoadLog FLL INNER JOIN DI.TaskInstance TI ON FLL.TaskInstanceID = TI.TaskInstanceID WHERE TI.TaskID = @TaskID AND FLL.FilePath = @FilePath AND FLL.[FileName] = @FileName)	
		BEGIN 
			INSERT INTO 
				DI.FileLoadLog
			(
				[TaskInstanceID],
				[FilePath],
				[FileName],
				[FileLastModifiedDate]
			)
			VALUES
			(
				@TaskInstanceID,
				@FilePath,
				@FileName,
				@LastModified
			)
		END
		-- it exists 
		ELSE 
		BEGIN
			-- Update deleted indicator to 0
			UPDATE DI.FileLoadLog
			SET DeletedIndicator = 0
			FROM 
				DI.FileLoadLog FLL INNER JOIN DI.TaskInstance TI 
				ON FLL.TaskInstanceID = TI.TaskInstanceID 
			WHERE 
				TI.TaskID = @TaskID 
				AND FLL.FilePath = @FilePath 
				AND FLL.[FileName] = @FileName
		END
		
		-- Return 1 
		SELECT 'Success'

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
