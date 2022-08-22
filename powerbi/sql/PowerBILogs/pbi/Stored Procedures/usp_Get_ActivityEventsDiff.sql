CREATE PROCEDURE [pbi].[usp_Get_ActivityEventsDiff]
	@SourceSchema sysname,
	 @SourceTable sysname,
	 @TargetCompareSchema sysname,
	 @TargetCompareTable sysname,
	 @TargetSchema sysname,
	 @TargetTable sysname,
	 @Debug BIT = 0
AS
	
BEGIN TRY
	--The variable to hold the dynamic sql is split as the endresult exceeds an nvarchar(max)
	 DECLARE       @MergeSQL NVARCHAR(MAX)
	 DECLARE       @UpdateSQL NVARCHAR(MAX) = ''
	 DECLARE       @UpdateSQLColumns NVARCHAR(MAX)
	 DECLARE       @InsertSQL NVARCHAR(MAX) = ''
	 DECLARE       @DeleteSQL NVARCHAR(MAX) = ''

	--Create Carriage return variable to help format the resulting query
	 DECLARE @crlf char(2)
	 SET @crlf = CHAR(13)
	 DECLARE @Field varchar(255)

	--Cursor for primarykey columns
	 DECLARE myCurPK Cursor FOR
	 SELECT c.name
	 FROM sys.columns c
	 INNER JOIN sys.indexes i 
	  ON c.object_id = i.object_id
	 INNER JOIN sys.index_columns IC 
	  ON IC.column_id = c.column_id
	  AND IC.object_id = c.object_id
	  AND i.index_id = IC.index_id
	 WHERE OBJECT_NAME(c.object_id) = @TargetTable AND OBJECT_SCHEMA_NAME(c.object_id) = @TargetSchema
	  --AND i.is_primary_key = 1 

	--Cursor for columns to be updated (all columns except the primary key columns)
	 DECLARE myCurUpdate CURSOR FOR
	 SELECT c.name
	 FROM sys.columns c
	 left JOIN sys.index_columns IC 
	  ON IC.column_id = c.column_id
	  AND IC.object_id = c.object_id
	  AND IC.column_id = c.column_id
	 left JOIN sys.indexes i ON i.object_id = ic.object_id
	  AND i.index_id = IC.index_id
	 WHERE OBJECT_NAME(c.object_id) = @TargetTable AND OBJECT_SCHEMA_NAME(c.object_id) = @TargetSchema
	  AND ISNULL(i.is_primary_key,0) = 0 

	--Cursor for all columns, used for insert
	 DECLARE myCurALL CURSOR FOR
	 SELECT c.name
	 FROM sys.columns c
	 WHERE OBJECT_NAME(c.object_id) = @TargetTable AND OBJECT_SCHEMA_NAME(c.object_id) = @TargetSchema

	 SET @InsertSQL =  @crlf +
		' INSERT [' + @TargetSchema + '].[' + @TargetTable + '] ('
		OPEN myCurALL
		FETCH NEXT FROM myCurALL INTO @Field
		IF (@@FETCH_STATUS>=0) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		BEGIN
		SET @InsertSQL = @InsertSQL + @crlf + '           ' + '[' + @Field + ']'
		FETCH NEXT FROM myCurALL INTO @Field
		END
		WHILE (@@FETCH_STATUS<>-1)
		BEGIN
		IF (@@FETCH_STATUS<>-2) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		SET @InsertSQL = @InsertSQL + @crlf + '           ,' + '[' + @Field + ']'
		FETCH NEXT FROM myCurALL INTO @Field
		END
		CLOSE myCurALL

	SET @InsertSQL =  @InsertSQL + @crlf + '
		)'

	SET @InsertSQL =  @InsertSQL + @crlf +
		'SELECT '
		OPEN myCurALL
		FETCH NEXT FROM myCurALL INTO @Field
		IF (@@FETCH_STATUS>=0) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		BEGIN
		SET @InsertSQL = @InsertSQL + @crlf + '           SOURCE.[' + @Field  + ']'
		FETCH NEXT FROM myCurALL INTO @Field
		END
		WHILE (@@FETCH_STATUS<>-1)
		BEGIN
		IF (@@FETCH_STATUS<>-2) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		SET @InsertSQL = @InsertSQL + @crlf + '           , SOURCE.[' + @Field  + ']'
		FETCH NEXT FROM myCurALL INTO @Field
		END
		CLOSE myCurALL
		SET @InsertSQL =  @InsertSQL + @crlf +
		'       FROM '
		SET @InsertSQL =  @InsertSQL + @crlf + '[' + @SourceSchema + '].[' + @SourceTable + '] SOURCE'

	SET @InsertSQL = @InsertSQL  + @crlf + 
	' WHERE NOT EXISTS ( SELECT '
		OPEN myCurPK
		FETCH NEXT FROM myCurPK INTO @Field
		IF (@@FETCH_STATUS>=0) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		BEGIN
		SET @InsertSQL = @InsertSQL + @crlf + '           TGT.[' + @Field + ']'
		FETCH NEXT FROM myCurPK INTO @Field
		END
		WHILE (@@FETCH_STATUS<>-1)
		BEGIN
		IF (@@FETCH_STATUS<>-2) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		SET @InsertSQL = @InsertSQL + @crlf + '           AND TGT.[' + @Field + ']'
		FETCH NEXT FROM myCurPK INTO @Field
		END
		CLOSE myCurPK
	SET @InsertSQL = @InsertSQL  + @crlf + 
	' FROM [' + @TargetCompareSchema + '].[' + @TargetCompareTable + '] AS TGT'
	SET @InsertSQL = @InsertSQL  + @crlf + 
	' WHERE '
		OPEN myCurPK
		FETCH NEXT FROM myCurPK INTO @Field
		IF (@@FETCH_STATUS>=0) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		BEGIN
		SET @InsertSQL = @InsertSQL + @crlf + '           TGT.[' + @Field + '] = SOURCE.['  + @Field + ']'
		FETCH NEXT FROM myCurPK INTO @Field
		END
		WHILE (@@FETCH_STATUS<>-1)
		BEGIN
		IF (@@FETCH_STATUS<>-2) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		SET @InsertSQL = @InsertSQL + @crlf + '           AND TGT.[' + @Field + '] = SOURCE.['  + @Field + ']'
		FETCH NEXT FROM myCurPK INTO @Field
		END
		CLOSE myCurPK
	SET @InsertSQL = @InsertSQL + ')'


	--clean up
	DEALLOCATE myCurUpdate
	DEALLOCATE myCurAll
	DEALLOCATE myCurPK
	-- Execute
	IF @Debug = 0
	BEGIN
	EXEC( @InsertSQL + ';')
	END
	ELSE
	BEGIN
	PRINT @InsertSQL + ';'
	END

END TRY
BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH