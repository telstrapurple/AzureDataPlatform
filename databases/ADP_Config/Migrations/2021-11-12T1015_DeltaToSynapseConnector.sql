DECLARE @TaskTypeID INT ;
DECLARE @MaxTaskTypeID INT ;

IF EXISTS (
    SELECT 1 
    FROM DI.TaskType
    WHERE TaskTypeName = N'Delta to Synapse'
)
BEGIN
    SELECT @TaskTypeID = TaskTypeID
    FROM DI.TaskType
    WHERE TaskTypeName = N'Delta to Synapse'
END
ELSE
BEGIN
    SELECT @MaxTaskTypeID = MAX(TaskTypeID) + 1
    FROM DI.TaskType ;

    SET IDENTITY_INSERT [DI].[TaskType] ON
    INSERT [DI].[TaskType] (
        [TaskTypeID], 
        [TaskTypeName], 
        [TaskTypeDescription], 
        [EnabledIndicator], 
        [DeletedIndicator], 
        [DateCreated], 
        [CreatedBy], 
        [ScriptIndicator], 
        [FileLoadIndicator], 
        [DatabaseLoadIndicator], 
        [RunType]
    ) 
VALUES (
        @MaxTaskTypeID, 
        N'Delta to Synapse', 
        N'This is the task type for any Delta data source to Azure Synapse target', 
        1, 
        0, 
        SYSDATETIMEOFFSET(), 
        NULL, 
        0, 
        1, 
        0, 
        N'Delta to Stage'
    )
SET IDENTITY_INSERT [DI].[TaskType] OFF

SELECT @TaskTypeID = @MaxTaskTypeID
END

DECLARE @MergeTable TABLE (
    TaskTypeID INT,
    TaskPropertyTypeID INT,
    DeletedIndicator BIT,
    DateCreated DATETIMEOFFSET
)
INSERT @MergeTable (TaskTypeID, TaskPropertyTypeID, DeletedIndicator, DateCreated)
SELECT @TaskTypeID, 1, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 2, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 3, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 4, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 7, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 8, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 9, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 10, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 12, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 29, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 32, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 43, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 44, 0, SYSDATETIMEOFFSET()
UNION ALL SELECT @TaskTypeID, 49, 0, SYSDATETIMEOFFSET()

MERGE DI.TaskTypeTaskPropertyTypeMapping TGT
USING @MergeTable as SRC
    ON SRC.TaskTypeID = TGT.TaskTypeID 
       AND SRC.TaskPropertyTypeID = TGT.TaskPropertyTypeID
WHEN MATCHED AND TGT.DeletedIndicator <> SRC.DeletedIndicator
THEN UPDATE SET DeletedIndicator = SRC.DeletedIndicator,
                DateModified = SYSDATETIMEOFFSET(),
                ModifiedBy = N'Migration Script'
WHEN NOT MATCHED
THEN INSERT (TaskTypeID, TaskPropertyTypeID, DeletedIndicator, DateCreated)
    VALUES (SRC.TaskTypeID, SRC.TaskPropertyTypeID, SRC.DeletedIndicator, SRC.DateCreated) ;
GO
