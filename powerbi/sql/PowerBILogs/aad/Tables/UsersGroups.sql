CREATE TABLE [aad].[UsersGroups] (
    [UserID]    VARCHAR (50)                                       NOT NULL,
    [GroupID]   VARCHAR (50)                                       NOT NULL,
    [ValidFrom] DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    [ValidTo]   DATETIME2 (7) GENERATED ALWAYS AS ROW END HIDDEN   NOT NULL,
    CONSTRAINT [PK_AAD_UsersGroups] PRIMARY KEY CLUSTERED ([UserID] ASC, [GroupID] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[aad].[UsersGroups_History], DATA_CONSISTENCY_CHECK=ON));

