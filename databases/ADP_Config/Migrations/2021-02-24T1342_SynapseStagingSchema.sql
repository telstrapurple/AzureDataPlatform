INSERT INTO DI.TaskType (
	TaskTypeName,
	TaskTypeDescription,
	ScriptIndicator,
	FileLoadIndicator,
	DatabaseLoadIndicator,
	RunType
) VALUES 
(
	'Schema Create to Synapse',
	'Schema Create statements on Synapse.', 
	1,
	0,
	0,
	'Script'
); 

INSERT INTO DI.TaskTypeTaskPropertyTypeMapping (
	TaskTypeID, 
	TaskPropertyTypeID
)
SELECT TaskTypeID, TPT.TaskPropertyTypeID FROM DI.TaskType TT CROSS JOIN 
(
SELECT TaskPropertyTypeID, TaskPropertyTypeName FROM DI.TaskPropertyType 	
) TPT
WHERE TT.TaskTypeName = 'Schema Create to Synapse'
AND TPT.TaskPropertyTypeName IN ('Source Table', 'Target Table', 'Target Schema Overwrite'); 