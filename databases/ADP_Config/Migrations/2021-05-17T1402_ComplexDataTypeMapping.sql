DECLARE
	@TaskPropertyTypeID INT

--Add a new Method task property type--

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'Map Complex Values to String') 
BEGIN

	INSERT INTO DI.TaskPropertyType
	(
		TaskPropertyTypeName
		,TaskPropertyTypeDescription
		,TaskPropertyTypeValidationID
	)
	SELECT
		'Map Complex Values to String'
		,'Specifies whether to map complex (array and object) values to simple strings in json format.'
		,(SELECT TPTV.TaskPropertyTypeValidationID FROM DI.TaskPropertyTypeValidation TPTV WHERE TPTV.TaskPropertyTypeValidationName = 'DropDownList')

END

SELECT @TaskPropertyTypeID = TaskPropertyTypeID FROM DI.TaskPropertyType WHERE TaskPropertyTypeName = 'Map Complex Values to String'

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyTypeOption WHERE TaskPropertyTypeID = @TaskPropertyTypeID) 
BEGIN
    
	INSERT INTO DI.TaskPropertyTypeOption
	(
		TaskPropertyTypeID
		,TaskPropertyTypeOptionName
	)
	SELECT
		@TaskPropertyTypeID
		,''
	UNION ALL
	SELECT
		@TaskPropertyTypeID
		,'true'
	UNION ALL
	SELECT
		@TaskPropertyTypeID
		,'false'

END	

IF NOT EXISTS (SELECT 1 FROM DI.TaskTypeTaskPropertyTypeMapping TTTPTM INNER JOIN DI.TaskPropertyType TPT ON TTTPTM.TaskPropertyTypeID = TPT.TaskPropertyTypeID WHERE TPT.TaskPropertyTypeName = 'Map Complex Values to String') 
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
		(TT.TaskTypeName LIKE 'REST API%'
		OR TT.TaskTypeName LIKE '%File%')
		AND TPT.TaskPropertyTypeName = 'Map Complex Values to String'

END