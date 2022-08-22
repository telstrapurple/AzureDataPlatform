-- Make sure all the rows are available for the script.
EXEC sp_set_session_context @key = N'IsGlobalAdmin', @value = 1
GO

ALTER TABLE DI.Connection
ADD Generic BIT NOT NULL DEFAULT 'TRUE',
	SystemCode NVARCHAR(100) NULL ;
GO

CREATE OR ALTER TRIGGER DI.CheckValidSystemConnection ON DI.Connection
AFTER INSERT, UPDATE
AS
IF (ROWCOUNT_BIG() = 0)
	RETURN;
IF EXISTS (
	SELECT 1 
	FROM inserted i
	WHERE i.Generic = 1 AND i.SystemCode IS NOT NULL
)
BEGIN
	RAISERROR ('Your are specifying both a SystemCode and a Generic connection - a Connection cannot allow both.', 16, 1) ;
	ROLLBACK TRANSACTION ;
	RETURN ;
END
IF EXISTS (
	SELECT 1 
	FROM inserted i
	LEFT JOIN DI.System s ON s.SystemCode = i.SystemCode
	WHERE i.Generic = 0 AND s.SystemCode IS NULL
)
BEGIN
	RAISERROR ('A specified SystemCode does not exist.', 16, 1) ;
	ROLLBACK TRANSACTION ;
	RETURN ;
END
GO


UPDATE DI.Connection
SET Generic = 1
WHERE ConnectionName IN (N'ADS Config', N'ADS Data Lake', N'ADS ETL Cluster', N'ADS Staging', N'ADS Synapse', N'Assurance - G360_Test_DW', N'Global_AM_KFM', N'Platform - AdventureWorks Sample', N'SAP_storage_account') ;
GO

;WITH mb
AS (
		SELECT DISTINCT ConnectionName, SystemCode 
		FROM (
		SELECT c.ConnectionName,
			   ETL.SystemCode
		FROM DI.Connection c
		JOIN (SELECT t.TaskName, s.SystemCode, t.ETLConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) ETL ON ETL.ConnectionID = c.ConnectionID
		WHERE c.ConnectionID IN (
			SELECT ConnectionID 
			FROM (
				SELECT ConnectionID, ConnectionName, COUNT(DISTINCT SystemCode) as DistinctSystems
				FROM (
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   ETL.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.ETLConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) ETL ON ETL.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   SRC.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.SourceConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) SRC ON SRC.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   TGT.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.TargetConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) TGT ON TGT.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   STG.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.StageConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) STG ON STG.ConnectionID = c.ConnectionID
				) a
				GROUP BY ConnectionID, ConnectionName 
				HAVING COUNT(DISTINCT SystemCode) = 1
			) x
		)
		UNION ALL 
		SELECT c.ConnectionName,
			   SRC.SystemCode
		FROM DI.Connection c
		JOIN (SELECT t.TaskName, s.SystemCode, t.SourceConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) SRC ON SRC.ConnectionID = c.ConnectionID
		WHERE c.ConnectionID IN (
			SELECT ConnectionID 
			FROM (
				SELECT ConnectionID, ConnectionName, COUNT(DISTINCT SystemCode) as DistinctSystems
				FROM (
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   ETL.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.ETLConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) ETL ON ETL.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   SRC.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.SourceConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) SRC ON SRC.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   TGT.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.TargetConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) TGT ON TGT.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   STG.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.StageConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) STG ON STG.ConnectionID = c.ConnectionID
				) a
				GROUP BY ConnectionID, ConnectionName
				HAVING COUNT(DISTINCT SystemCode) = 1
			) x
		)
		UNION ALL 
		SELECT c.ConnectionName,
			   TGT.SystemCode
		FROM DI.Connection c
		JOIN (SELECT t.TaskName, s.SystemCode, t.TargetConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) TGT ON TGT.ConnectionID = c.ConnectionID
		WHERE c.ConnectionID IN (
			SELECT ConnectionID 
			FROM (
				SELECT ConnectionID, ConnectionName, COUNT(DISTINCT SystemCode) as DistinctSystems
				FROM (
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   ETL.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.ETLConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) ETL ON ETL.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   SRC.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.SourceConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) SRC ON SRC.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   TGT.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.TargetConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) TGT ON TGT.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   STG.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.StageConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) STG ON STG.ConnectionID = c.ConnectionID
				) a
				GROUP BY ConnectionID, ConnectionName 
				HAVING COUNT(DISTINCT SystemCode) = 1
			) x
		)
		UNION ALL 
		SELECT c.ConnectionName,
			   STG.SystemCode
		FROM DI.Connection c
		JOIN (SELECT t.TaskName, s.SystemCode, t.StageConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) STG ON STG.ConnectionID = c.ConnectionID
		WHERE c.ConnectionID IN (
			SELECT ConnectionID 
			FROM (
				SELECT ConnectionID, ConnectionName, COUNT(DISTINCT SystemCode) as DistinctSystems
				FROM (
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   ETL.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.ETLConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) ETL ON ETL.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   SRC.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.SourceConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) SRC ON SRC.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   TGT.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.TargetConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) TGT ON TGT.ConnectionID = c.ConnectionID
				UNION ALL 
				SELECT c.ConnectionID, 
					   c.ConnectionName,
					   STG.SystemCode
				FROM DI.Connection c
				JOIN (SELECT t.TaskName, s.SystemCode, t.StageConnectionID as ConnectionID FROM DI.Task t JOIN DI.System s ON t.SystemID = s.SystemID) STG ON STG.ConnectionID = c.ConnectionID
				) a
				GROUP BY ConnectionID, ConnectionName 
				HAVING COUNT(DISTINCT SystemCode) = 1
			) x
		)
	) a
)
UPDATE mc
SET Generic = 0,
    SystemCode = mb.SystemCode
FROM DI.Connection mc
JOIN mb ON mb.ConnectionName = mc.ConnectionName ;
GO


-- Create a predicate function for Row Level Security based on SystemCode and Generic Indicator
-- The function is applied to the column value parameter to identify the  rows
-- that should be returned based on the Groups that the user has set  in the 
-- SESSION_CONTEXT and the relationship of Systems to Tasks to identify the valid
-- TaskID values
CREATE FUNCTION [Security].systemCodeGenericPredicate(@SystemCode NVARCHAR(100), @Generic BIT)
    RETURNS TABLE
    WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS isAccessible
    FROM DI.System s 
    WHERE 
    (
        -- Use the UserGroups from the Session Context to get the matching System IDs that the 
        -- user can access OR the IsGlobalAdmin value is TRUE in which case they see ALL 
        -- System IDs
        s.SystemCode = @SystemCode
        AND 
        (
            (
                s.LocalAdminGroup IN (
                    SELECT CAST(value as uniqueidentifier) as GroupGUID
                    FROM OPENJSON( CAST(SESSION_CONTEXT(N'UserGroups') as NVARCHAR(MAX)))
                )
                OR 
                s.MemberGroup IN (
                    SELECT CAST(value as uniqueidentifier) as GroupGUID
                    FROM OPENJSON( CAST(SESSION_CONTEXT(N'UserGroups') as NVARCHAR(MAX)))
                )
            )
            OR 
            (
                CAST(SESSION_CONTEXT(N'IsGlobalAdmin') as BIT) = 1
            )
			OR
			(
				IS_ROLEMEMBER ('BypassRLS') = 1 
			)
        )
    )
    OR @Generic = 1 ;
GO

-- Create the Security Policies. This is the high-level object and the implementations of
-- it are then added afterwards on a case by case basis.
-- Create it as OFF initially until we apply the rules

-- Filter by SystemCode and Generic BIT setting
CREATE SECURITY POLICY [Security].systemCodeGenericSecurityPolicy
WITH (STATE = OFF, SCHEMABINDING = ON);
GO


-- Next we apply the Security Policy to the Connection table that needs it.
ALTER SECURITY POLICY [Security].systemCodeGenericSecurityPolicy 
ADD BLOCK PREDICATE [Security].systemCodeGenericPredicate(SystemCode, Generic) ON DI.Connection AFTER UPDATE,
ADD BLOCK PREDICATE [Security].systemCodeGenericPredicate(SystemCode, Generic) ON DI.Connection AFTER INSERT,
ADD FILTER PREDICATE [Security].systemCodeGenericPredicate(SystemCode, Generic) ON DI.Connection ;
GO

-- Finally we want to switch the policies on
ALTER SECURITY POLICY [Security].systemCodeGenericSecurityPolicy
WITH (STATE = ON);
GO