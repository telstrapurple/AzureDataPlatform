/****** Object:  UserDefinedFunction [DI].[udf_ReplaceParquetColumnChars]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP FUNCTION IF EXISTS [DI].[udf_ReplaceParquetColumnChars]
GO
/****** Object:  UserDefinedFunction [DI].[udf_ReplaceParquetColumnChars]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [DI].[udf_ReplaceParquetColumnChars]
(
	@String NVARCHAR(MAX)
)

RETURNS NVARCHAR(MAX)

AS

BEGIN

	RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@String, ' ', ''), '.', ''), ',', ''), ';', ''), '{', ''), '}', ''), '=', ''), '(', ''), ')', ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')

END
GO
