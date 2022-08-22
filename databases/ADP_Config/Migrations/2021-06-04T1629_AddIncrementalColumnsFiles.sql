-- Add new task type to task property type mapping for File Types
INSERT INTO DI.TaskTypeTaskPropertyTypeMapping ( 
    TaskTypeID, 
    TaskPropertyTypeID,
    DeletedIndicator
) 
SELECT 
	TaskTypeID, 
	(SELECT TaskPropertyTypeID FROM DI.TaskPropertyType WHERE TaskPropertyTypeName = 'Incremental Column'),
	0
FROM DI.TaskType WHERE TaskTypeName LIKE '%File%'

-- Add new task type to task property type mapping for File Types
INSERT INTO DI.TaskTypeTaskPropertyTypeMapping ( 
    TaskTypeID, 
    TaskPropertyTypeID,
    DeletedIndicator
) 
SELECT 
	TaskTypeID, 
	(SELECT TaskPropertyTypeID FROM DI.TaskPropertyType WHERE TaskPropertyTypeName = 'Incremental Column Format'),
	0
FROM DI.TaskType WHERE TaskTypeName LIKE '%File%'

-- Add new task type to task property type mapping for File Types
INSERT INTO DI.TaskTypeTaskPropertyTypeMapping ( 
    TaskTypeID, 
    TaskPropertyTypeID,
    DeletedIndicator
) 
SELECT 
	TaskTypeID, 
	(SELECT TaskPropertyTypeID FROM DI.TaskPropertyType WHERE TaskPropertyTypeName = 'Incremental Value'),
	0
FROM DI.TaskType WHERE TaskTypeName LIKE '%File%'
