DECLARE
	@TaskPropertyTypeID INT

--Add a new Method task property type--

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Method') 
BEGIN

	INSERT INTO DI.TaskPropertyType
	(
		TaskPropertyTypeName
		,TaskPropertyTypeDescription
		,TaskPropertyTypeValidationID
	)
	SELECT
		'Method'
		,'This is the type of rest method to use. Options are GET and POST. If POST, please supply a body'
		,(SELECT TPTV.TaskPropertyTypeValidationID FROM DI.TaskPropertyTypeValidation TPTV WHERE TPTV.TaskPropertyTypeValidationName = 'DropDownList')

END

SELECT @TaskPropertyTypeID = TaskPropertyTypeID FROM DI.TaskPropertyType WHERE TaskPropertyTypeName = 'Method'

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyTypeOption WHERE TaskPropertyTypeID = @TaskPropertyTypeID) 
BEGIN
    
	INSERT INTO DI.TaskPropertyTypeOption
	(
		TaskPropertyTypeID
		,TaskPropertyTypeOptionName
	)
	SELECT
		@TaskPropertyTypeID
		,'GET'
	UNION ALL
	SELECT
		@TaskPropertyTypeID
		,'POST'

END

--Add a new Body task property type--

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Body') 
BEGIN

	INSERT INTO DI.TaskPropertyType
	(
		TaskPropertyTypeName
		,TaskPropertyTypeDescription
		,TaskPropertyTypeValidationID
	)
	SELECT
		'Body'
		,'This is the body of the request if the method selected is POST'
		,(SELECT TPTV.TaskPropertyTypeValidationID FROM DI.TaskPropertyTypeValidation TPTV WHERE TPTV.TaskPropertyTypeValidationName = 'MultiLineTextBox')

END

IF NOT EXISTS (SELECT 1 FROM DI.TaskTypeTaskPropertyTypeMapping TTTPTM INNER JOIN DI.TaskPropertyType TPT ON TTTPTM.TaskPropertyTypeID = TPT.TaskPropertyTypeID WHERE TPT.TaskPropertyTypeName IN('Method', 'Body')) 
BEGIN

	INSERT INTO DI.TaskTypeTaskPropertyTypeMapping
	(
		TaskTypeID
		,TaskPropertyTypeID
	)
	SELECT
		TT.TaskTypeID
		,TPT.TaskPropertyTypeID
	FROM
		DI.TaskType TT
		,DI.TaskPropertyType TPT
	WHERE
		TT.TaskTypeName LIKE 'REST API%'
		AND TPT.TaskPropertyTypeName IN('Method', 'Body')

END

--Insert the missing properties for all REST tasks--

INSERT INTO DI.TaskProperty
(
	TaskPropertyTypeID
	,TaskID
	,TaskPropertyValue
)

SELECT
	TPNew.TaskPropertyTypeID
	,T.TaskID
	,'GET'
FROM
	DI.Task T
	INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
	CROSS JOIN 
	(
	SELECT 
		TPT.TaskPropertyTypeID	
	FROM 
		DI.TaskPropertyType TPT
	WHERE
		TPT.TaskPropertyTypeName = 'Method'
	) TPNew
	LEFT OUTER JOIN DI.TaskProperty TP ON T.TaskID = TP.TaskID
		AND TP.TaskPropertyTypeID = TPNew.TaskPropertyTypeID
WHERE
	TT.TaskTypeName LIKE 'REST API%'
	AND TPNew.TaskPropertyTypeID IS NULL

--Incremental loads for REST API's

IF NOT EXISTS (SELECT 1 FROM DI.TaskTypeTaskPropertyTypeMapping TTTPTM INNER JOIN DI.TaskPropertyType TPT ON TTTPTM.TaskPropertyTypeID = TPT.TaskPropertyTypeID INNER JOIN DI.TaskType TT ON TTTPTM.TaskTypeID = TT.TaskTypeID WHERE TPT.TaskPropertyTypeName IN('Incremental Column', 'Incremental Value', 'Incremental Column Format') AND TT.TaskTypeName LIKE 'REST API%') 
BEGIN

	INSERT INTO DI.TaskTypeTaskPropertyTypeMapping
	(
		TaskTypeID
		,TaskPropertyTypeID
	)
	SELECT
		TT.TaskTypeID
		,TPT.TaskPropertyTypeID
	FROM
		DI.TaskType TT
		,DI.TaskPropertyType TPT
	WHERE
		TT.TaskTypeName LIKE 'REST API%'
		AND TPT.TaskPropertyTypeName IN('Incremental Column', 'Incremental Value', 'Incremental Column Format')

END