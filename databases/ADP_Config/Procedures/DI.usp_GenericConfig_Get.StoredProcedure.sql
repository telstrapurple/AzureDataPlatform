/****** Object:  StoredProcedure [DI].[usp_GenericConfig_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_GenericConfig_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_GenericConfig_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE    PROCEDURE [DI].[usp_GenericConfig_Get]

AS

BEGIN TRY

	SELECT
		MAX(CASE WHEN GC.GenericConfigName = 'Logic App Send Email URL' THEN GC.GenericConfigValue END) AS [LogicAppSendEmailURL]
		,MAX(CASE WHEN GC.GenericConfigName = 'Logic App Scale Azure VM URL' THEN GC.GenericConfigValue END) AS [LogicAppScaleAzureVMURL]
		,MAX(CASE WHEN GC.GenericConfigName = 'Logic App Scale Azure SQL URL' THEN GC.GenericConfigValue END) AS [LogicAppScaleAzureSQLURL]
		,MAX(CASE WHEN GC.GenericConfigName = 'Notification Email Address' THEN GC.GenericConfigValue END) AS [NotificationEmailAddress]
		,MAX(CASE WHEN GC.GenericConfigName = 'KeyVault Name' THEN GC.GenericConfigValue END) AS [KeyVaultName]
	FROM
		DI.GenericConfig GC

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
