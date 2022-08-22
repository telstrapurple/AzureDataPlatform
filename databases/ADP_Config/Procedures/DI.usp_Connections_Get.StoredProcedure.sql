/****** Object:  StoredProcedure [DI].[usp_Connections_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_Connections_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_Connections_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [DI].[usp_Connections_Get]
(
	@ConnectionType VARCHAR(50)
)

AS

BEGIN TRY

	SELECT
		C.ConnectionID
		,CP.ConnectionPropertyValue AS [secretName]
	FROM
		DI.[Connection] C
		INNER JOIN DI.ConnectionType CT ON C.ConnectionTypeID = CT.ConnectionTypeID
		INNER JOIN DI.[ConnectionProperty] CP ON C.ConnectionID = CP.ConnectionID
		INNER JOIN DI.ConnectionPropertyType CPT ON CP.ConnectionPropertyTypeID = CPT.ConnectionPropertyTypeID
	WHERE
		CPT.ConnectionPropertyTypeName = 'KeyVault Secret Name'
		AND CT.ConnectionTypeName = @ConnectionType
		AND C.ConnectionName NOT IN('ADS Config', 'ADS Staging')
		AND C.EnabledIndicator = 1
		AND C.DeletedIndicator = 0

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
