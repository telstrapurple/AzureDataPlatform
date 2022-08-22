--------------------------------------------
-- Add Script Config parameter for notebooks 
--------------------------------------------
INSERT INTO DI.TaskPropertyType (
	TaskPropertyTypeName, 
	TaskPropertyTypeDescription,
	TaskPropertyTypeValidationID
)
VALUES (
	'Script Config', 
	'Configuration input for the script to receive and use.',
	(SELECT TaskPropertyTypeValidationID FROM DI.TaskPropertyTypeValidation WHERE TaskPropertyTypeValidationName = 'MultiLineTextBox')
)

SELECT * FROM DI.TaskTypeTaskPropertyTypeMapping
INSERT INTO DI.TaskTypeTaskPropertyTypeMapping ( 
	TaskTypeID,
	TaskPropertyTypeID
)
VALUES( 
	(SELECT TaskTypeID FROM DI.TaskType WHERE TaskTypeName = 'Databricks notebook'),
	(SELECT TaskPropertyTypeID FROM DI.TaskPropertyType WHERE TaskPropertyTypeName = 'Script Config')
)