/****** Object:  StoredProcedure [ETL].[usp_InvalidSourceDateColumns_Get]    Script Date: 1/12/2020 11:55:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ETL].[usp_InvalidSourceDateColumns_Get]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [ETL].[usp_InvalidSourceDateColumns_Get] AS' 
END
GO
ALTER   PROCEDURE [ETL].[usp_InvalidSourceDateColumns_Get]

AS

SET NOCOUNT ON


BEGIN TRY

	DECLARE
		@ExecString NVARCHAR(MAX) = ''

	SELECT @ExecString +=
		'SELECT ''' + C.TABLE_SCHEMA + '_' + C.TABLE_NAME + ''' AS [Temp Object Name], ''' + C.TABLE_SCHEMA + '.' + C.TABLE_NAME + ''' AS [Landing Object Name], ''' + C.COLUMN_NAME + ''' AS [Column Name], COUNT(*) AS [No of Rows] FROM tempstage.[' + C.TABLE_SCHEMA + '_' + C.TABLE_NAME + '] WHERE TRY_CAST([' + C.COLUMN_NAME + '] AS ' + C.DATA_TYPE + ') IS NULL AND [' + C.COLUMN_NAME + '] IS NOT NULL HAVING COUNT(*) > 0 UNION ALL ' 
	FROM
		INFORMATION_SCHEMA.[columns] C	
		INNER JOIN 
		(
		SELECT 
			CT.TABLE_NAME 
			,CT.COLUMN_NAME
		FROM 
			INFORMATION_SCHEMA.[COLUMNS] CT
		WHERE
			CT.TABLE_SCHEMA = 'tempstage'
		) Temp ON C.TABLE_SCHEMA + '_' + C.TABLE_NAME = Temp.TABLE_NAME
			AND C.COLUMN_NAME = Temp.COLUMN_NAME
		INNER JOIN 
		(
		SELECT 
			Phy.TableName 
		FROM 	
			(
			SELECT
				T.[name] AS TableName
				,P.[rows] AS NoOfRows
			FROM
				sys.tables T
				INNER JOIN sys.[partitions] P ON T.[object_id] = P.[object_id]
			WHERE
				SCHEMA_NAME(T.[schema_id]) = 'tempstage'
				AND P.index_id < 2
			) TS
			INNER JOIN 
			(
			SELECT
				SCHEMA_NAME(T.[schema_id]) + '_' + T.[name] AS TableName
				,P.[rows] AS NoOfRows
			FROM
				sys.tables T
				INNER JOIN sys.[partitions] P ON T.[object_id] = P.[object_id]
			WHERE
				SCHEMA_NAME(T.[schema_id]) <> 'tempstage'
				AND P.index_id < 2
			) Phy ON TS.TableName = Phy.TableName
				AND TS.NoOfRows > Phy.NoOfRows
		) TabDif ON Temp.TABLE_NAME = TabDif.TableName
	WHERE
		C.TABLE_SCHEMA <> 'tempstage'
		AND C.DATA_TYPE LIKE '%date%'

	SET @ExecString = LEFT(@ExecString, LEN(@ExecString) - 9)

	EXEC(@ExecString)

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
