/****** Object:  StoredProcedure [ETL].[usp_Database_Clean]    Script Date: 1/12/2020 11:55:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ETL].[usp_Database_Clean]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [ETL].[usp_Database_Clean] AS' 
END
GO
ALTER   PROCEDURE [ETL].[usp_Database_Clean]

AS

DECLARE
	@DropSQL NVARCHAR(MAX) = ''

SET NOCOUNT ON

BEGIN TRY

	--Drop the tables

	SELECT
		@DropSQL = STRING_AGG('DROP TABLE [' + CAST(T.TABLE_SCHEMA AS VARCHAR(MAX)) + '].[' + CAST(T.TABLE_NAME AS VARCHAR(MAX)) + ']', ';')
	FROM
		INFORMATION_SCHEMA.TABLES T
		INNER JOIN sys.schemas S ON T.TABLE_SCHEMA = S.[name]
	WHERE
		S.principal_id = 1
		AND T.TABLE_SCHEMA NOT IN('ETL', 'dbo')

	EXEC sys.sp_executesql @DropSQL

	--Drop the schemas

	SELECT
		@DropSQL = STRING_AGG('DROP SCHEMA [' + CAST(S.[name] AS VARCHAR(MAX)) + ']', ';')
	FROM
		sys.schemas S
	WHERE
		S.principal_id = 1
		AND S.[name] NOT IN('ETL', 'tempstage', 'dbo')

	EXEC sys.sp_executesql @DropSQL

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
