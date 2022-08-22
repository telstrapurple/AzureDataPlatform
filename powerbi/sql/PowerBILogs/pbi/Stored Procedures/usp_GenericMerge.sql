/*
 usp_GenericMerge @SourceSchema = 'etl', @SourceTable='Customers', @TargetSchema='Dim', @TargetTable='Customers'

 @Operation paramter usage: 
 Specify: IUD, IU-, I--, -U-, -UD, --D, I-D
 I: Insert
 U: Update
 D: Delete
 */
 CREATE PROCEDURE [pbi].[usp_GenericMerge] (
	 @SourceSchema sysname,
	 @SourceTable sysname,
	 @TargetSchema sysname,
	 @TargetTable sysname,
	 @Operation VARCHAR(50) = 'IUD', 
	 @Debug bit = 0
 )
 AS
/*
 SYNPOSIS: 
 Merges two table based on the primary key of the Target table 
 
 AUTHOR:
 Original author: Rasmus Reinholdt
 Modified by: Jonathan Neo

 MODIFICATIONS: 
	- 04/08/2020 [JN] - Support same table name in different schema
	- 04/08/2020 [JN] - Support indexes
	- 05/08/2020 [JN] - Support for column names that clash with SQL Sever Reserved Names
	- 05/08/2020 [JN] - Added support for SystemVersioned tables 
	- 05/08/2020 [JN] - Added support for only updating if changes are detected
	- 05/08/2020 [JN] - Included PK columns in the Update statemnet
	- 07/08/2020 [JN] - Added support for merge operation
 */
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

	--Building the DynamicSQL
	 SET @MergeSQL = '
	 MERGE [' + @TargetSchema + '].[' + @TargetTable + '] AS TARGET
	 USING [' + @SourceSchema +'].['+ @SourceTable + '] AS SOURCE
	 ON '
	 OPEN myCurPK
	 FETCH NEXT FROM myCurPK INTO @Field
	 IF (@@FETCH_STATUS>=0) AND @Field NOT IN ('ValidFrom', 'ValidTo')
	 BEGIN
	 SET @MergeSQL = @MergeSQL + @crlf + '           SOURCE.[' + @Field + '] = TARGET.['  + @Field + ']'
	 FETCH NEXT FROM myCurPK INTO @Field
	 END
	 WHILE (@@FETCH_STATUS<>-1)
	 BEGIN
	 IF (@@FETCH_STATUS<>-2) AND @Field NOT IN ('ValidFrom', 'ValidTo')
	 SET @MergeSQL = @MergeSQL + @crlf + '           AND SOURCE.[' + @Field + '] = TARGET.['  + @Field + ']'
	 FETCH NEXT FROM myCurPK INTO @Field
	 END
	 CLOSE myCurPK

	 -- UPDATE
	 IF @Operation IN ('IUD', 'IU-', '-U-', '-UD') 
	 BEGIN
		SET @UpdateSQLColumns =  ' WHEN MATCHED ' 
		OPEN myCurALL
		 FETCH NEXT FROM myCurALL INTO @Field
		 IF (@@FETCH_STATUS>=0) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		 BEGIN
		 SET @UpdateSQLColumns = @UpdateSQLColumns + @crlf + '           AND ' + 'TARGET.[' + @Field + '] <> SOURCE.['  + @Field + ']'
		 FETCH NEXT FROM myCurALL INTO @Field
		 END
		 WHILE (@@FETCH_STATUS<>-1)
		 BEGIN
		 IF (@@FETCH_STATUS<>-2) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		 SET @UpdateSQLColumns = @UpdateSQLColumns + @crlf + '           OR ' + 'TARGET.[' + @Field + '] <> SOURCE.['  + @Field + ']'
		 FETCH NEXT FROM myCurALL INTO @Field
		 END
		 CLOSE myCurALL

		SET @UpdateSQL =  ' THEN UPDATE SET '
		 OPEN myCurALL
		 FETCH NEXT FROM myCurALL INTO @Field
		 IF (@@FETCH_STATUS>=0) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		 BEGIN
		 SET @UpdateSQL = @UpdateSQL + @crlf + '           ' + 'TARGET.[' + @Field + '] = SOURCE.['  + @Field + ']'
		 FETCH NEXT FROM myCurALL INTO @Field
		 END
		 WHILE (@@FETCH_STATUS<>-1)
		 BEGIN
		 IF (@@FETCH_STATUS<>-2) AND @Field NOT IN ('ValidFrom', 'ValidTo')
		 SET @UpdateSQL = @UpdateSQL + @crlf + '           ,' + 'TARGET.[' + @Field + '] = SOURCE.['  + @Field + ']'
		 FETCH NEXT FROM myCurALL INTO @Field
		 END
		 CLOSE myCurALL
	END

	-- INSERT
	IF @Operation IN ('IUD', 'I--', 'IU-', 'I-D')
	BEGIN
		SET @InsertSQL =  @crlf +
		 ' WHEN NOT MATCHED BY TARGET THEN
		 INSERT (
		 '
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
		 'VALUES ('
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
		 '      )'
	END

	IF @Operation IN ('IUD', 'I-D', '-UD', '--D')
	BEGIN 
		SET @DeleteSQL = 
		'
		 WHEN NOT MATCHED BY SOURCE 
		 THEN DELETE'
	END

	--clean up
	 DEALLOCATE myCurUpdate
	 DEALLOCATE myCurAll
	 DEALLOCATE myCurPK

	IF @Debug = 0
	 BEGIN
	 EXEC(@MergeSQL + @UpdateSQLColumns + @UpdateSQL + @InsertSQL + @DeleteSQL + ';')
	 END
	 ELSE
	 BEGIN
	 PRINT @MergeSQL
	 PRINT @UpdateSQLColumns
	 PRINT @UpdateSQL
	 PRINT @InsertSQL
	 PRINT @DeleteSQL
	 PRINT ';'
	 END

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH