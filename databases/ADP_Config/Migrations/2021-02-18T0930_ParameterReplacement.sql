DECLARE
	@TaskPropertyTypeID INT

-- Add a new Method Parameters task property type--

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Method Parameters') 
BEGIN

	INSERT INTO DI.TaskPropertyType
	(
		TaskPropertyTypeName
		,TaskPropertyTypeDescription
		,TaskPropertyTypeValidationID
	)
	SELECT
		'Method Parameters'
		,'This is the list of parameters which need to be replaced in the body. The format should be: @Parameter=<value>, separated by a semi-colon (;), where value is a valid T-SQL statement, or [LatestValue] for incremental loads'
		,(SELECT TPTV.TaskPropertyTypeValidationID FROM DI.TaskPropertyTypeValidation TPTV WHERE TPTV.TaskPropertyTypeValidationName = 'TextBox')

END

-- Add a new SQL Parameters task property type--

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'SQL Parameters') 
BEGIN

	INSERT INTO DI.TaskPropertyType
	(
		TaskPropertyTypeName
		,TaskPropertyTypeDescription
		,TaskPropertyTypeValidationID
	)
	SELECT
		'SQL Parameters'
		,'This is the list of parameters which need to be replaced in the source SQL statement. The format should be: @Parameter=<value>, separated by a semi-colon (;), where value is a valid T-SQL statement, or [LatestValue] for incremental loads'
		,(SELECT TPTV.TaskPropertyTypeValidationID FROM DI.TaskPropertyTypeValidation TPTV WHERE TPTV.TaskPropertyTypeValidationName = 'TextBox')

END

-- Add the task type mappings for Method Parameters for REST tasks

SELECT @TaskPropertyTypeID = TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Method Parameters'

IF NOT EXISTS (SELECT 1 FROM DI.TaskTypeTaskPropertyTypeMapping TTTPTM WHERE TTTPTM.TaskPropertyTypeID = @TaskPropertyTypeID) 
BEGIN

	INSERT INTO DI.TaskTypeTaskPropertyTypeMapping
	(
		TaskTypeID
		,TaskPropertyTypeID
	)
	SELECT
		TT.TaskTypeID
		,@TaskPropertyTypeID
	FROM
		DI.TaskType TT
	WHERE
		TT.TaskTypeName LIKE 'REST API%'

END

-- Add the task type mappings for SQL Parameters for database tasks

SELECT @TaskPropertyTypeID = TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'SQL Parameters'

IF NOT EXISTS (SELECT 1 FROM DI.TaskTypeTaskPropertyTypeMapping TTTPTM WHERE TTTPTM.TaskPropertyTypeID = @TaskPropertyTypeID) 
BEGIN

	INSERT INTO DI.TaskTypeTaskPropertyTypeMapping
	(
		TaskTypeID
		,TaskPropertyTypeID
	)
	SELECT
		TT.TaskTypeID
		,@TaskPropertyTypeID
	FROM
		DI.TaskType TT
	WHERE
		TaskTypeName LIKE 'Azure SQL%'
		OR TaskTypeName LIKE 'Oracle%'
		OR TaskTypeName LIKE 'On Prem%'

END

-- Add an incremental column format to support time

SELECT @TaskPropertyTypeID = TPT.TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Incremental Column Format'

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyTypeOption TPTO WHERE TPTO.TaskPropertyTypeID = @TaskPropertyTypeID AND TPTO.TaskPropertyTypeOptionName = 'yyyy-MM-dd HH:mm:ss') 

BEGIN

	INSERT INTO DI.TaskPropertyTypeOption
	(
		TaskPropertyTypeID
		,TaskPropertyTypeOptionName
	)
	VALUES
	(
		@TaskPropertyTypeID
		,'yyyy-MM-dd HH:mm:ss'
	)

END

-- Add the ability to specify a customer schema for database loads if the source query can't derive the schema

UPDATE 
	DI.TaskType
SET 
	FileLoadIndicator = 1
	,DateModified = SYSUTCDATETIME()
WHERE 
	(TaskTypeName LIKE 'Azure SQL%'
	OR TaskTypeName LIKE 'Oracle%'
	OR TaskTypeName LIKE 'On Prem%')
	AND FileLoadIndicator = 0

-- Update the descriptions in the web UI

UPDATE 
	DI.TaskPropertyType
SET
	TaskPropertyTypeDescription = 'This is the body of the request if the method selected is POST. Use @<Parameter name> logic for parameters and specify the values for the parameters in the Body Parameters property'
WHERE
	TaskPropertyTypeName = 'Body'

UPDATE 
	DI.TaskPropertyType
SET
	TaskPropertyTypeDescription = 'This is the property type for a SQL select statement. Please note that CDC enabled sources do not support custom SQL command. Use @<Parameter name> logic for parameters and specify the values for the parameters in the SQL Parameters property'
WHERE
	TaskPropertyTypeName = 'SQL Command'