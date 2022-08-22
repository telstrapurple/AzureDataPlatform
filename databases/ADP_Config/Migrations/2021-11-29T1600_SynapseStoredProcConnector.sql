DECLARE @TaskTypeID INT ;
DECLARE @MaxTaskTypeID INT ;

IF EXISTS (
    SELECT 1 
    FROM DI.TaskType
    WHERE TaskTypeName = N'Synapse Stored Procedure'
)
BEGIN
    SELECT @TaskTypeID = TaskTypeID
    FROM DI.TaskType
    WHERE TaskTypeName = N'Synapse Stored Procedure'
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
        N'Synapse Stored Procedure', 
        N'This is the task type for any Azure Synapse stored procedure run', 
        1, 
        0, 
        SYSDATETIMEOFFSET(), 
        NULL, 
        0, 
        0, 
        0, 
        N'Script'
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
SELECT @TaskTypeID, 25, 0, SYSDATETIMEOFFSET()

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
