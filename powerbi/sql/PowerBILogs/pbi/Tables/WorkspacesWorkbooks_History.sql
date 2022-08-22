CREATE TABLE [pbi].[WorkspacesWorkbooks_History] (
    [Name]        NVARCHAR (4000) NOT NULL,
    [WorkspaceId] VARCHAR (50)    NOT NULL,
    [DatasetId]   VARCHAR (50)    NULL,
    [ValidFrom]   DATETIME2 (7)   NOT NULL,
    [ValidTo]     DATETIME2 (7)   NOT NULL
);

