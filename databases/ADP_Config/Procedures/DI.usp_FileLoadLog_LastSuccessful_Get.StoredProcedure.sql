/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_LastSuccessful_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_FileLoadLog_LastSuccessful_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_LastSuccessful_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [DI].[usp_FileLoadLog_LastSuccessful_Get]
(
	@TaskInstanceID INT,
	@FileLoadOrderBy NVARCHAR(255),
	@FileLoadLogID INT
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
		
		IF @FileLoadOrderBy = 'LastModifiedDate'
		BEGIN 
			DECLARE @LastSuccessfulModifiedDate datetimeoffset(7);
			SET @LastSuccessfulModifiedDate = 
			(
				SELECT 
					MAX(FLL.FileLastModifiedDate)
				FROM
					DI.FileLoadLog FLL INNER JOIN DI.TaskInstance TI
						ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE
					TI.TaskID = @TaskID
					AND FLL.SuccessIndicator = 1
					AND FLL.FileLoadLogID <> @FileLoadLogID
			)
			-- Return previous target successful file path name
			IF @LastSuccessfulModifiedDate IS NOT NULL
			BEGIN
				SELECT TOP 1
					FLL.FileLastModifiedDate LastSuccessfulRun,
					CONCAT(FLL.TargetFilePath, FLL.[TargetFileName]) AS TargetFilePathName,
					FLL.FileLoadLogID
				FROM
					DI.FileLoadLog FLL INNER JOIN DI.TaskInstance TI
						ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE
					TI.TaskID = @TaskID
					AND FLL.SuccessIndicator = 1
					AND FLL.FileLoadLogID <> @FileLoadLogID
				ORDER BY 
					FLL.FileLastModifiedDate DESC
			END
			ELSE 
			BEGIN
				-- Return empty string 
				SELECT '' AS TargetFilePathName
			END
		END 


		IF @FileLoadOrderBy = 'FilePathName'
		BEGIN

			DECLARE @LastSuccessfulFilePathName nvarchar(max);
			SET @LastSuccessfulFilePathName = 
			(
				SELECT MAX(CONCAT(FLL.FilePath, FLL.[FileName]))
				FROM
					DI.FileLoadLog FLL INNER JOIN DI.TaskInstance TI
						ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE
					TI.TaskID = @TaskID 
					AND FLL.SuccessIndicator = 1
					AND FLL.FileLoadLogID <> @FileLoadLogID
			)

			-- Return previous successful target file path name
			IF @LastSuccessfulFilePathName IS NOT NULL
			BEGIN 
				SELECT TOP 1
					CONCAT(FLL.FilePath, FLL.[FileName]) LastSuccessfulFilePathName,
					CONCAT(FLL.TargetFilePath, FLL.[TargetFileName]) AS TargetFilePathName,
					FLL.FileLoadLogID
				FROM 
					DI.FileLoadLog FLL INNER JOIN DI.TaskInstance TI
						ON FLL.TaskInstanceID = TI.TaskInstanceID
				WHERE 
					TI.TaskID = @TaskID
					AND FLL.SuccessIndicator = 1
					AND FLL.FileLoadLogID <> @FileLoadLogID
				ORDER BY 
					CONCAT(FLL.TargetFilePath, FLL.[TargetFileName]) DESC
			END 
			ELSE
			BEGIN
				-- Return an empty string 
				SELECT 
					'' AS FilePathName,
					'' AS TargetFilePathName,
					'' AS FileLoadLogID
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
