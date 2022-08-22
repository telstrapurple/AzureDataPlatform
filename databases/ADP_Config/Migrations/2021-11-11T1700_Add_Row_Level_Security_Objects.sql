-- Create a new schema to hold the RLS objects
CREATE SCHEMA [Security] AUTHORIZATION [DBO];
GO

-- Create a Role to be able to ByPass RLS for certain connections
CREATE ROLE BypassRLS AUTHORIZATION [dbo];
GO

-- Create a predicate function for Row Level Security based on SystemID
-- The function is applied to the column value parameter to identify the  rows
-- that should be returned based on the Groups that the user has set  in the 
-- SESSION_CONTEXT
CREATE FUNCTION Security.systemIDPredicate(@SystemID int)
    RETURNS TABLE
    WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS isAccessible
    FROM DI.System
    WHERE 
    (
        -- Use the UserGroups from the Session Context to get the matching System IDs that the 
        -- user can access OR the IsGlobalAdmin value is TRUE in which case they see ALL 
        -- System IDs
        SystemID = @SystemID
        AND 
        (
            (
                LocalAdminGroup IN (
                    SELECT CAST(value as uniqueidentifier) as GroupGUID
                    FROM OPENJSON( CAST(SESSION_CONTEXT(N'UserGroups') as NVARCHAR(MAX)))
                )
                OR 
                MemberGroup IN (
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
    ) ;
GO

-- Create a predicate function for Row Level Security based on TaskID
-- The function is applied to the column value parameter to identify the  rows
-- that should be returned based on the Groups that the user has set  in the 
-- SESSION_CONTEXT and the relationship of Systems to Tasks to identify the valid
-- TaskID values
CREATE FUNCTION Security.taskIDPredicate(@TaskID int)
    RETURNS TABLE
    WITH SCHEMABINDING
AS
    RETURN SELECT 1 AS isAccessible
    FROM DI.task t 
    JOIN DI.System s ON s.SystemID = t.SystemID
    WHERE 
    (
        -- Use the UserGroups from the Session Context to get the matching System IDs that the 
        -- user can access OR the IsGlobalAdmin value is TRUE in which case they see ALL 
        -- System IDs
        t.TaskID = @TaskID
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
    ) ;
GO


-- Create the initial Security Policies. This is the high-level object and the implementations of
-- it are then added afterwards on a case by case basis.
-- Create it as OFF initially until we apply the rules

-- First one to filter by SystemID
CREATE SECURITY POLICY Security.systemIDSecurityPolicy
WITH (STATE = OFF, SCHEMABINDING = ON);
GO
-- And one to filter by TaskID AND by SystemID
CREATE SECURITY POLICY Security.taskIDSecurityPolicy
WITH (STATE = OFF, SCHEMABINDING = ON);
GO


-- Next we apply the Security Policies for each table that needs it.
-- First up is for the DI.System table itself
ALTER SECURITY POLICY Security.systemIDSecurityPolicy 
ADD BLOCK PREDICATE Security.systemIDPredicate(SystemID) ON DI.System AFTER UPDATE,
ADD BLOCK PREDICATE Security.systemIDPredicate(SystemID) ON DI.System AFTER INSERT,
ADD FILTER PREDICATE Security.systemIDPredicate(SystemID) ON DI.System ;
GO

-- Next up is the DI.Tasks table
ALTER SECURITY POLICY Security.systemIDSecurityPolicy 
ADD BLOCK PREDICATE Security.systemIDPredicate(SystemID) ON DI.Task AFTER UPDATE,
ADD BLOCK PREDICATE Security.systemIDPredicate(SystemID) ON DI.Task AFTER INSERT,
ADD FILTER PREDICATE Security.systemIDPredicate(SystemID) ON DI.Task ;
GO

-- Next is the DI.TaskInstance table
ALTER SECURITY POLICY Security.taskIDSecurityPolicy 
ADD BLOCK PREDICATE Security.taskIDPredicate(TaskID) ON DI.TaskInstance AFTER UPDATE,
ADD BLOCK PREDICATE Security.taskIDPredicate(TaskID) ON DI.TaskInstance AFTER INSERT,
ADD FILTER PREDICATE Security.taskIDPredicate(TaskID) ON DI.TaskInstance ;
GO

-- Finally we want to switch the policies on
ALTER SECURITY POLICY Security.systemIDSecurityPolicy
WITH (STATE = ON);
GO
ALTER SECURITY POLICY Security.taskIDSecurityPolicy
WITH (STATE = ON);
GO