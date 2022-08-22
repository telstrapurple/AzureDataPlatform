CREATE TABLE [pbi].[WorkspacesDashboards_History] (
    [Id]          VARCHAR (50)  NOT NULL,
    [WorkspaceId] VARCHAR (50)  NOT NULL,
    [ValidFrom]   DATETIME2 (7) NOT NULL,
    [ValidTo]     DATETIME2 (7) NOT NULL
);

