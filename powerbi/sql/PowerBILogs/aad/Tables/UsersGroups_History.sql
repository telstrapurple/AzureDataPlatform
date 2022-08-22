CREATE TABLE [aad].[UsersGroups_History] (
    [UserID]    VARCHAR (50)  NOT NULL,
    [GroupID]   VARCHAR (50)  NOT NULL,
    [ValidFrom] DATETIME2 (7) NOT NULL,
    [ValidTo]   DATETIME2 (7) NOT NULL
);

