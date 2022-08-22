/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Update]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_FileLoadLog_Update]
GO
/****** Object:  StoredProcedure [DI].[usp_FileLoadLog_Update]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [DI].[usp_FileLoadLog_Update]
(
	@FileLoadLogID INT,
	@TargetFilePath NVARCHAR(MAX),
	@TargetFileName NVARCHAR(MAX),
	@SuccessIndicator BIT
)

AS

SET NOCOUNT ON

BEGIN TRY
		
		-- Update FileLoadLog
		UPDATE DI.FileLoadLog 
		SET SuccessIndicator = @SuccessIndicator, TargetFilePath = @TargetFilePath, TargetFileName = @TargetFileName
		WHERE FileLoadLogID = @FileLoadLogID
		
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
