-- Add new task types for Azure File Share connection 
INSERT INTO DI.TaskType (
    TaskTypeName, 
    TaskTypeDescription,
    EnabledIndicator, 
    DeletedIndicator,
    ScriptIndicator,
    FileLoadIndicator,
    DatabaseLoadIndicator,
    RunType
) VALUES
(
    'Azure File Share to Lake',
    'This is the task type for any file stored in Azure File Share which needs to be moved to the Data Lake', 
    1,
    0,
    0,
    1,
    0,
    'File to Lake'
),
(
    'Azure File Share to SQL',
    'This is the task type for any file stored in Azure File Share which needs to be moved to target SQL', 
    1,
    0,
    0,
    1,
    0,
    'File to Stage'
)

-- Add new task type to task property type mapping for 'Azure File Share to Lake'
INSERT INTO DI.TaskTypeTaskPropertyTypeMapping ( 
    TaskTypeID, 
    TaskPropertyTypeID,
    DeletedIndicator
) 
SELECT (SELECT TaskTypeID FROM DI.TaskType WHERE TaskTypeName = 'Azure File Share to Lake'), 
	TTTPTM.TaskPropertyTypeID, 
	0 
FROM 
	DI.TaskTypeTaskPropertyTypeMapping TTTPTM
WHERE 
	TTTPTM.TaskTypeID = (SELECT TaskTypeID FROM DI.TaskType WHERE TaskTypeName = 'Azure Blob File to Lake'); 

-- Add new task type to task property type mapping for 'Azure File Share to SQL'
INSERT INTO DI.TaskTypeTaskPropertyTypeMapping ( 
    TaskTypeID, 
    TaskPropertyTypeID,
    DeletedIndicator
) 
SELECT (SELECT TaskTypeID FROM DI.TaskType WHERE TaskTypeName = 'Azure File Share to SQL'), 
	TTTPTM.TaskPropertyTypeID, 
	0 
FROM 
	DI.TaskTypeTaskPropertyTypeMapping TTTPTM
WHERE 
	TTTPTM.TaskTypeID = (SELECT TaskTypeID FROM DI.TaskType WHERE TaskTypeName = 'Azure Blob File to SQL') 

