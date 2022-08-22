/****** Object:  StoredProcedure [DI].[usp_SystemsToRun_Get]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_SystemsToRun_Get]
GO
/*

This procedure returns all the systems which need to be run for a given schedule

Changes
--------------------
20200219	David Schneeberger		Modified the logic for the sequetial loads to use a set based approach
20200323	Sarath Mohan			Modified for CRM loads
20200518	Jon Neo					Added logic for system priority
20210816	David Schneeberger		Added support for system level ACL's
20210823	Jonathan Neo		 	Modified support for system level ACL's

*/
CREATE PROCEDURE [DI].[usp_SystemsToRun_Get]
(
	@Schedule VARCHAR(50) = 'Once a day',
	@Sequential BIT = 0
)

AS

SET NOCOUNT ON

BEGIN TRY

	-- If sequential = 0 then return parallel results 
    IF @Sequential = 0 
    BEGIN
        SELECT
            Systems.[System]
           ,Systems.TaskType
           ,Systems.RunType
           ,Systems.SystemPriority
           ,Systems.[ACL] AS [ACLPermissions]
        FROM 
            (
            SELECT DISTINCT
                    S.SystemName AS [System]
                    ,TT.TaskTypeName AS [TaskType]
                    ,COALESCE(TT.RunType, '') AS [RunType]
                    ,COUNT(*) OVER(PARTITION BY S.SystemID) AS [No of Tasks]
                    ,SP.SystemPriority
                    ,ACLPerm.[ACL]
                FROM
                    DI.Task T
                    INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
                    INNER JOIN DI.[System] S ON T.SystemID = S.SystemID
                    LEFT OUTER JOIN 
                    (
                    SELECT 
                        SP.SystemID
                        ,MAX(CAST(SP.SystemPropertyValue AS INT) ) AS SystemPriority
                    FROM 
                        DI.SystemProperty SP
                        INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
                    WHERE
                        SPT.SystemPropertyTypeName = 'System Priority'
                        AND SP.DeletedIndicator = 0
                    GROUP BY 
                        SP.SystemID
                    ) SP ON S.SystemID = SP.SystemID
                    INNER JOIN DI.Schedule S1 ON T.ScheduleID = S1.ScheduleID
                    INNER JOIN DI.[Connection] CSource ON T.SourceConnectionID = CSource.ConnectionID
                    LEFT OUTER JOIN DI.[Connection] CTarget ON T.TargetConnectionID = CTarget.ConnectionID  -- INNER JOIN
                    INNER JOIN DI.ConnectionType CTSource ON CSource.ConnectionTypeID = CTSource.ConnectionTypeID
                    LEFT OUTER JOIN DI.ConnectionType CTTarget ON CTarget.ConnectionTypeID = CTTarget.ConnectionTypeID -- INNER JOIN
                    LEFT OUTER JOIN DI.SystemDependency SD ON SD.SystemID = S.SystemID
                        AND SD.EnabledIndicator = 1
                        AND SD.DeletedIndicator = 0
                    OUTER APPLY
                    (
                    SELECT DISTINCT
                        SP.SystemPropertyValue AS [ACL]
                    FROM
                        DI.[System] Syst
                        INNER JOIN DI.SystemProperty SP ON Syst.SystemID = SP.SystemID
                        INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
                    WHERE
                        SPT.SystemPropertyTypeName = 'ACL Permissions'
                        AND ISNULL(SP.SystemPropertyValue, '') <> ''
                        AND SP.DeletedIndicator = 0
                        AND S.SystemID = Syst.SystemID
                    ) ACLPerm
                WHERE
                    S1.ScheduleName = @Schedule
                    AND S.EnabledIndicator = 1
                    AND S.DeletedIndicator = 0
                    AND T.EnabledIndicator = 1
                    AND T.DeletedIndicator = 0
                    AND SD.SystemID IS NULL
                ) Systems
        GROUP BY
            Systems.[System]
           ,Systems.TaskType
           ,Systems.RunType
           ,Systems.SystemPriority
           ,Systems.ACL
        ORDER BY 
            -Systems.SystemPriority DESC -- sorts by +col asc, implies nulls last
            ,Systems.[System] -- then sorts by system name alphabetically 
    END


	--If sequential = 1 then return sequential results
	IF @Sequential = 1
    BEGIN
        
        CREATE TABLE #List
        (
            OrderID int, 
            SystemID int
        );
        WITH SystemDependency AS
        (
        SELECT 
            S.SystemID
            ,0 AS DependencyID
            ,0 AS DependentSystemID
            ,1 AS DependencyLevel
            ,CAST('' AS VARCHAR(100)) AS DependencyPath
        FROM 
            DI.[System] S
        WHERE    
            S.EnabledIndicator = 1
            AND S.DeletedIndicator = 0
        EXCEPT
        SELECT 
            SD.SystemID
            ,0 AS DependencyID
            ,0 AS DependentSystemID
            ,1
            ,CAST('' AS VARCHAR(100))
        FROM 
            DI.SystemDependency SD
            INNER JOIN DI.[System] S ON SD.SystemID = S.SystemID
        WHERE
            SD.EnabledIndicator = 1
            AND SD.DeletedIndicator = 0
            AND S.EnabledIndicator = 1
            AND S.DeletedIndicator = 0
        UNION ALL
        SELECT 
            SD.SystemID
            ,SD.DependencyID
            ,SystemDependency.DependencyID
            ,DependencyLevel + 1
            ,CAST(DependencyPath + CAST(SystemDependency.DependencyID AS VARCHAR(50)) + '/' AS VARCHAR(100))
        FROM 
            SystemDependency
            INNER JOIN DI.SystemDependency SD ON SystemDependency.SystemID = SD.DependencyID
            INNER JOIN DI.[System] S ON SD.SystemID = S.SystemID
        WHERE
            SD.EnabledIndicator = 1
            AND SD.DeletedIndicator = 0
            AND S.EnabledIndicator = 1
            AND S.DeletedIndicator = 0
        )
        INSERT INTO #List
        (
            OrderID
            ,SystemID
        )
        SELECT 
            ROW_NUMBER() OVER(ORDER BY MAX(Depends.RowID)) AS OrderID
            ,Depends.SystemID
        FROM 
            (
            SELECT 
                SystemID
               ,ROW_NUMBER() OVER(PARTITION BY SystemID, DependencyLevel ORDER BY (SELECT NULL)) AS RowID
            FROM 
                SystemDependency
                CROSS APPLY
                (
                SELECT
                    DependencyPath + CAST(DependencyID AS VARCHAR(50)) AS DependencyPath
                ) Depend
                CROSS APPLY STRING_SPLIT(Depend.DependencyPath, '/') PathDepend
            WHERE
                DependencyID <> 0
            ) Depends
        GROUP BY 
            Depends.SystemID
        -- Select statement 
        SELECT 
            Systems.OrderID,
            Systems.[System],
            Systems.TaskType,
            Systems.RunType,
            Systems.SystemPriority
            ,Systems.[ACL] AS [ACLPermissions]
		FROM 
            (
            SELECT 
                L.OrderID AS [OrderID],
                S.SystemName AS [System],
                TT.TaskTypeName AS [TaskType]
                ,COALESCE(TT.RunType, '') AS [RunType]
                ,COUNT(*) OVER(PARTITION BY S.SystemID) AS [No of Tasks]
                ,SP.SystemPriority
                ,ACLPerm.[ACL]
            FROM
                #List L
                INNER JOIN DI.[System] S ON S.SystemID = L.SystemID
                INNER JOIN DI.Task T ON T.SystemID = S.SystemID
                LEFT OUTER JOIN 
                (
                SELECT 
                    SP.SystemID
                    ,MAX(CAST(SP.SystemPropertyValue AS INT) ) AS SystemPriority
                FROM 
                    DI.SystemProperty SP
                    INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
                WHERE
                    SPT.SystemPropertyTypeName = 'System Priority'
                    AND SP.DeletedIndicator = 0
                GROUP BY 
                    SP.SystemID
                ) SP ON S.SystemID = SP.SystemID
                INNER JOIN DI.TaskType TT ON T.TaskTypeID = TT.TaskTypeID
                INNER JOIN DI.Schedule S1 ON T.ScheduleID = S1.ScheduleID
                INNER JOIN DI.[Connection] CSource ON T.SourceConnectionID = CSource.ConnectionID
                LEFT OUTER JOIN DI.[Connection] CTarget ON T.TargetConnectionID = CTarget.ConnectionID 
                INNER JOIN DI.ConnectionType CTSource ON CSource.ConnectionTypeID = CTSource.ConnectionTypeID
                LEFT OUTER JOIN DI.ConnectionType CTTarget ON CTarget.ConnectionTypeID = CTTarget.ConnectionTypeID 
                OUTER APPLY
                (
                SELECT 
                    SP.SystemPropertyValue AS [ACL]
                FROM
                    DI.[System] Syst
                    INNER JOIN DI.SystemProperty SP ON Syst.SystemID = SP.SystemID
                    INNER JOIN DI.SystemPropertyType SPT ON SP.SystemPropertyTypeID = SPT.SystemPropertyTypeID
                WHERE
                    SPT.SystemPropertyTypeName = 'ACL Permissions'
                    AND ISNULL(SP.SystemPropertyValue, '') <> ''
                    AND SP.DeletedIndicator = 0
                    AND S.SystemID = Syst.SystemID
                ) ACLPerm
            WHERE
                S1.ScheduleName = @Schedule
                AND S.EnabledIndicator = 1
                AND S.DeletedIndicator = 0
                AND T.EnabledIndicator = 1
                AND T.DeletedIndicator = 0
            GROUP BY
                L.OrderID
                ,S.SystemID
                ,S.SystemName
                ,TT.TaskTypeName
                ,COALESCE(TT.RunType, '')
                ,SP.SystemPriority
                ,ACLPerm.[ACL]
            ) Systems
        GROUP BY 
            Systems.OrderID,
            Systems.[System],
            Systems.TaskType,
            Systems.RunType,
            Systems.SystemPriority,
            Systems.ACL
        ORDER BY 
            Systems.OrderID ASC
            ,-Systems.SystemPriority DESC -- sorts by +col asc, implies nulls last
            ,Systems.[System] -- then sorts by system name alphabetically 
    END



	-- if sequential = 1 then return sequential results
	--IF @Sequential = 1
	--BEGIN
		
	--	CREATE TABLE #List
	--	(
	--		OrderID int, 
	--		SystemID int
	--	)

	--	DECLARE @SystemDependencyID INT
	--			,@SystemID INT
	--			,@DependencyID INT; 
		
	--	DECLARE SystemDependency_Cursor CURSOR FAST_FORWARD READ_ONLY FOR 
	--	SELECT
	--		SD.SystemDependencyID,
	--		SD.SystemID,
	--		SD.DependencyID
	--	FROM 
	--		DI.[SystemDependency] SD
	--	ORDER BY 
	--		SD.SystemDependencyID;

	--	OPEN SystemDependency_Cursor
	--	FETCH NEXT FROM SystemDependency_Cursor INTO @SystemDependencyID, @SystemID, @DependencyID -- Fetch the first row from SystemDependency_Cursor
	--	WHILE @@FETCH_STATUS = 0 -- While the cursor is not empty  
	--	BEGIN
	--		DECLARE @ListOrderID INT
	--				,@ListSystemID INT
	--				,@ListID INT = 0
	--				,@SystemFound BIT = 0;
				
	--		DECLARE List_Cursor CURSOR FAST_FORWARD READ_ONLY FOR 
	--		SELECT
	--			LI.OrderID,
	--			LI.SystemID
	--		FROM
	--			#List LI
	--		ORDER BY 
	--			LI.OrderID

	--		OPEN List_Cursor
	--		FETCH NEXT FROM List_Cursor INTO @ListOrderID, @ListSystemID -- Fetch the first row from List_Cursor
	--		WHILE @@FETCH_STATUS = 0 AND @SystemFound = 0 -- While the cursor is not empty and System has not matched
	--		BEGIN 
	--			SET @ListID = @ListID + 1; 
	--			IF @ListSystemID = @SystemID 
	--			BEGIN
	--				-- Set SystemFound to true and do nothing to insert system
	--				SET @SystemFound = 1;
	--				PRINT 'System match found for ' + CAST(@SystemID as varchar(255)) + ' at position ' + CAST(@ListID as varchar(255))
	--			END; 
	--			FETCH NEXT FROM List_Cursor INTO @ListOrderID, @ListSystemID -- Fetch the next row from List_Cursor
	--		END

	--		IF @SystemFound = 0 -- System does not exist
	--		BEGIN
	--			SET @ListID = (SELECT COUNT(*) FROM #List) + 1; -- Set ListID to last value on list 
	--			IF @ListID IS NULL BEGIN SET @ListID = 1 END; -- If listID does not exist, then add it to the front of the list
	--			PRINT 'System match not found. Inserting SystemID ' + CAST(@SystemID as varchar(255)) + ' into #List at position ' + CAST(@ListID as varchar(255))
	--			INSERT INTO #List
	--			VALUES
	--			(
	--				@ListID,
	--				@SystemID
	--			)
	--			-- Check if dependency exists	
	--			DECLARE 
	--				@InnerListOrderID INT
	--				,@InnerListSystemID INT
	--				,@DependencyFound BIT = 0;

	--			DECLARE Inner_List_Cursor CURSOR FAST_FORWARD READ_ONLY FOR 
	--			SELECT
	--				LI.OrderID,
	--				LI.SystemID
	--			FROM
	--				#List LI
	--			ORDER BY 
	--				LI.OrderID

	--			OPEN Inner_List_Cursor
	--			FETCH NEXT FROM Inner_List_Cursor INTO @InnerListOrderID, @InnerListSystemID -- Fetch the first row from Inner_List_Cursor
	--			WHILE @@FETCH_STATUS = 0 AND @DependencyFound = 0 -- While the cursor is not empty  and dependency has not matched
	--			BEGIN 
	--				-- If dependency exists, then do nothing
	--				IF @DependencyID = @InnerListSystemID
	--				BEGIN
	--					SET @DependencyFound = 1; 
	--					PRINT 'Dependency match found for ' + CAST(@DependencyID as varchar(255)) + ' at position ' + CAST(@InnerListOrderID as varchar(255))
	--				END
	--				FETCH NEXT FROM Inner_List_Cursor INTO @InnerListOrderID, @InnerListSystemID
	--			END

	--			CLOSE Inner_List_Cursor
	--			DEALLOCATE Inner_List_Cursor
				
	--			-- If dependency does not exist, then add dependency to list before the system
	--			IF @DependencyFound = 0
	--			BEGIN
	--				PRINT 'Dependency match not found. Inserting DependencyID ' + CAST(@DependencyID as varchar(255)) + ' into #List at position ' + CAST(@ListID as varchar(255))
	--				UPDATE 
	--					#List
	--				SET 
	--					OrderID += 1
	--				WHERE 
	--					OrderID >= @ListID;
	--				-- Insert into #List
	--				INSERT INTO #List
	--				VALUES
	--				(
	--					@ListID,
	--					@DependencyID
	--				);
	--			END

	--		END

	--		IF @SystemFound = 1
	--		BEGIN
			
	--			-- Check if dependency exists	
	--			DECLARE 
	--				@InnerListOrderID2 INT
	--				,@InnerListSystemID2 INT
	--				,@DependencyFound2 BIT = 0;

	--			DECLARE Inner_List_Cursor2 CURSOR FAST_FORWARD READ_ONLY FOR 
	--			SELECT
	--				LI.OrderID,
	--				LI.SystemID
	--			FROM
	--				#List LI
	--			ORDER BY 
	--				LI.OrderID

	--			OPEN Inner_List_Cursor2
	--			FETCH NEXT FROM Inner_List_Cursor2 INTO @InnerListOrderID2, @InnerListSystemID2 -- Fetch the first row from Inner_List_Cursor
	--			WHILE @@FETCH_STATUS = 0 AND  @DependencyFound2 = 0 -- While the cursor is not empty  
	--			BEGIN 
	--				-- If dependency exists, then do nothing
	--				IF @DependencyID = @InnerListSystemID2
	--				BEGIN
	--					SET @DependencyFound2 = 1; 
	--					PRINT 'Dependency match found for ' + CAST(@DependencyID as varchar(255)) + ' at position ' + CAST(@InnerListOrderID as varchar(255))
	--				END
	--				FETCH NEXT FROM Inner_List_Cursor2 INTO @InnerListOrderID2, @InnerListSystemID2
	--			END

	--			CLOSE Inner_List_Cursor2
	--			DEALLOCATE Inner_List_Cursor2
				
	--			-- If no dependency exists, then add dependency to list before the system
	--			IF @DependencyFound2 = 0
	--			BEGIN
	--				PRINT 'Dependency match not found. Inserting DependencyID ' + CAST(@DependencyID as varchar(255)) + ' into #List at position ' + CAST(@ListID as varchar(255))
	--				UPDATE 
	--					#List
	--				SET 
	--					OrderID += 1
	--				WHERE 
	--					OrderID >= @ListID;
	--				-- Insert into #List
	--				INSERT INTO #List
	--				VALUES
	--				(
	--					@ListID,
	--					@DependencyID
	--				);
	--			END

	--		END

	--		CLOSE List_Cursor
	--		DEALLOCATE List_Cursor

	--		FETCH NEXT FROM SystemDependency_Cursor INTO @SystemDependencyID, @SystemID, @DependencyID -- Fetch the next row from SystemDependency_Cursor
	--	END
	--	CLOSE SystemDependency_Cursor
	--	DEALLOCATE SystemDependency_Cursor

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
