/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_FileLoadLog_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [DI].[usp_FileLoadLog_Get]
(
	@TaskInstanceID INT,
	@FileLoadOrderBy NVARCHAR(255),
	@ForceFileReload NVARCHAR(100)
)

AS

SET NOCOUNT ON

BEGIN TRY
		-- Get TaskID
		DECLARE @TaskID INT; 
		SET @TaskID = 
		(
			SELECT 
				MAX(TI.TaskID)
			FROM 
				DI.TaskInstance TI
			WHERE 
				TI.TaskInstanceID = @TaskInstanceID
		)


		-- if force file reload is true, then set success indicator to 0 for all files related to the task
		IF @ForceFileReload = 'true'
		BEGIN
			UPDATE DI.FileLoadLog
			SET SuccessIndicator = 0
			FROM
				DI.FileLoadLog FLL INNER JOIN DI.TaskInstance TI
				ON FLL.TaskInstanceID = TI.TaskInstanceID
			WHERE 
				TI.TaskID = @TaskID
		END
		
		IF @FileLoadOrderBy = 'LastModifiedDate'
		BEGIN 
			
			-- Get Last Successful Modified Date 
			DECLARE @LastSuccessfulModifiedDate datetimeoffset(7);
			SET @LastSuccessfulModifiedDate = 
			(
				SELECT MAX(FLL.FileLastModifiedDate)
				FROM
					DI.FileLoadLog FLL
					INNER JOIN
					DI.TaskInstance TI
						ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE
					TI.TaskID = @TaskID
					AND 
					FLL.SuccessIndicator = 1
					AND DeletedIndicator = 0
			)

			-- Return results where greater than Last Successful Modified Date 
			IF @LastSuccessfulModifiedDate != null
			BEGIN 
				SELECT 
					FLL.FileLoadLogID,
					FLL.TaskInstanceID, 
					FLL.FilePath, 
					FLL.[FileName],
					FLL.FileLastModifiedDate,
					CONCAT(FLL.FilePath, FLL.[FileName]) AS FilePathName,
					FLL.TargetFileName,
					FLL.TargetFilePath,
					CONCAT(FLL.TargetFilePath,TargetFileName) AS TargetFilePathName, 
					FLL.SuccessIndicator
				FROM 
					DI.FileLoadLog FLL
					INNER JOIN 
					DI.TaskInstance TI
					ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE 
					TI.TaskID = @TaskID
					AND FLL.SuccessIndicator = 0
					AND FLL.FileLastModifiedDate > @LastSuccessfulModifiedDate
					AND DeletedIndicator = 0
				ORDER BY 
					FLL.FileLastModifiedDate ASC 
			END 
			ELSE
			-- Return all results for matching TaskID
			BEGIN
				SELECT 
					FLL.FileLoadLogID,
					FLL.TaskInstanceID, 
					FLL.FilePath, 
					FLL.[FileName],
					FLL.FileLastModifiedDate,
					CONCAT(FLL.FilePath, FLL.[FileName]) AS FilePathName,
					FLL.TargetFileName,
					FLL.TargetFilePath,
					CONCAT(FLL.TargetFilePath,TargetFileName) AS TargetFilePathName, 
					FLL.SuccessIndicator
				FROM 
					DI.FileLoadLog FLL
					INNER JOIN 
					DI.TaskInstance TI
					ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE 
					TI.TaskID = @TaskID
					AND FLL.SuccessIndicator = 0
					AND DeletedIndicator = 0
				ORDER BY 
					FLL.FileLastModifiedDate ASC 
			END

		END 

		IF @FileLoadOrderBy = 'FilePathName'
		BEGIN

			-- Get Last Successful FilePathName
			DECLARE @LastSuccessfulFilePathName nvarchar(max);
			SET @LastSuccessfulFilePathName = 
			(
				SELECT MAX(CONCAT(FLL.FilePath, FLL.[FileName]))
				FROM
					DI.FileLoadLog FLL
					INNER JOIN
					DI.TaskInstance TI
						ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE
					TI.TaskID = @TaskID
					AND 
					FLL.SuccessIndicator = 1
					AND DeletedIndicator = 0
			)

			-- Return results where greater than Last Successful FilePathName
			IF @LastSuccessfulFilePathName != null
			BEGIN 
				SELECT 
					FLL.FileLoadLogID,
					FLL.TaskInstanceID, 
					FLL.FilePath, 
					FLL.[FileName],
					FLL.FileLastModifiedDate,
					CONCAT(FLL.FilePath, FLL.[FileName]) AS FilePathName,
					FLL.TargetFileName,
					FLL.TargetFilePath,
					CONCAT(FLL.TargetFilePath,TargetFileName) AS TargetFilePathName, 
					FLL.SuccessIndicator
				FROM 
					DI.FileLoadLog FLL
					INNER JOIN 
					DI.TaskInstance TI
					ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE 
					TI.TaskID = @TaskID
					AND FLL.SuccessIndicator = 0
					AND CONCAT(FLL.FilePath, FLL.[FileName]) > @LastSuccessfulFilePathName
					AND DeletedIndicator = 0
				ORDER BY 
					FilePathName ASC 
			END 
			ELSE
			-- Return all results for matching TaskID
			BEGIN
				SELECT 
					FLL.FileLoadLogID,
					FLL.TaskInstanceID, 
					FLL.FilePath, 
					FLL.[FileName],
					FLL.FileLastModifiedDate,
					CONCAT(FLL.FilePath, FLL.[FileName]) AS FilePathName,
					FLL.TargetFileName,
					FLL.TargetFilePath,
					CONCAT(FLL.TargetFilePath,TargetFileName) AS TargetFilePathName, 
					FLL.SuccessIndicator
				FROM 
					DI.FileLoadLog FLL
					INNER JOIN 
					DI.TaskInstance TI
					ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE 
					TI.TaskID = @TaskID
					AND FLL.SuccessIndicator = 0
					AND DeletedIndicator = 0
				ORDER BY 
					FilePathName ASC 
			END
		END
		
END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
