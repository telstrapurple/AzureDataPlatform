IF NOT EXISTS (SELECT 1 FROM sys.schemas S WHERE S.[name] = 'tempstage') 
BEGIN

	EXEC('CREATE SCHEMA tempstage')

END
IF NOT EXISTS (SELECT 1 FROM sys.schemas S WHERE S.[name] = 'ETL') 
BEGIN

	EXEC('CREATE SCHEMA ETL')

END