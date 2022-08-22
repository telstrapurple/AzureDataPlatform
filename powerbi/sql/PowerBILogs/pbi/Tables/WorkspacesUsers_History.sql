CREATE TABLE [pbi].[WorkspacesUsers_History] (
    [Identifier]        VARCHAR (250) NOT NULL,
    [WorkspaceId]       VARCHAR (50)  NOT NULL,
    [AccessRight]       VARCHAR (50)  NULL,
    [UserPrincipalName] VARCHAR (250) NULL,
    [PrincipalType]     VARCHAR (50)  NULL,
    [ValidFrom]         DATETIME2 (7) NOT NULL,
    [ValidTo]           DATETIME2 (7) NOT NULL
);

