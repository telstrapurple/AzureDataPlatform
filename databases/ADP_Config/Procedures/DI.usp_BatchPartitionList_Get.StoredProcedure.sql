/****** Object:  StoredProcedure [DI].[usp_BatchPartitionList_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_BatchPartitionList_Get]
GO
/****** Object:  StoredProcedure [DI].[usp_BatchPartitionList_Get]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [DI].[usp_BatchPartitionList_Get]
(
	@MinValue VARCHAR(50)
	,@MaxValue VARCHAR(50)
	,@PartitionCount INT
)

AS

SET NOCOUNT ON	

BEGIN TRY

	--If the value is a date, partition by batches of days

	IF ISDATE(@MinValue) = 1

	BEGIN

		SELECT
			'''' + FORMAT(Vals.StartValue, 'yyyyMMdd') + '''' AS StartValue
			,'''' + FORMAT(ISNULL(LEAD(Vals.StartValue, 1) OVER(ORDER BY IDs.ID), DATEADD(DAY, 1, @MaxValue)), 'yyyyMMdd') + '''' AS EndValue
			,ROW_NUMBER() OVER(ORDER BY Vals.StartValue) AS PartitionNo
		FROM
			(SELECT
				ROW_NUMBER() OVER (ORDER BY (SELECT	NULL)) AS ID
			FROM 
				sys.all_columns AC
			) IDs
			CROSS APPLY
			(
			SELECT
				CASE
					WHEN IDs.ID = 1
					THEN CAST(@MinValue AS DATE)
					ELSE DATEADD(DAY, (DATEDIFF(DAY, @MinValue, @MaxValue) / CEILING(CAST(@PartitionCount AS DECIMAL(10,2)))) * (IDs.ID - 1), @MinValue)
				END AS StartValue
			) Vals
		WHERE
			IDs.id <= @PartitionCount

	END

	ELSE

	-- Otherwise, create partitions of equal size

	BEGIN

		SELECT
			Vals.StartValue
			,ISNULL(LEAD(Vals.StartValue, 1) OVER(ORDER BY IDs.id), @MaxValue + 1) AS EndValue
			,ROW_NUMBER() OVER(ORDER BY Vals.StartValue) AS PartitionNo
		FROM
			(SELECT
				ROW_NUMBER() OVER (ORDER BY (SELECT	NULL)) AS ID
			FROM 
				sys.all_columns AC
			) IDs
			CROSS APPLY
			(
			SELECT
				CASE
					WHEN IDs.id = 1
					THEN @MinValue
					ELSE @MinValue + ((CAST(@MaxValue AS BIGINT) - CAST(@MinValue AS BIGINT)) / @PartitionCount) * (IDs.id - 1)
				END AS StartValue
			) Vals
		WHERE
			((@MinValue + (CAST(@MaxValue AS BIGINT) - CAST(@MinValue AS BIGINT))) / @PartitionCount) * IDs.ID <= CAST(@MaxValue AS BIGINT)

	END

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
