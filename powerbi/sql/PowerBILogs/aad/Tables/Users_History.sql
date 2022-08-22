CREATE TABLE [aad].[Users_History] (
    [UserID]            VARCHAR (50)       NOT NULL,
    [UserPrincipalName] VARCHAR (100)      NOT NULL,
    [DisplayName]       VARCHAR (500)      NOT NULL,
    [GivenName]         VARCHAR (100)      NULL,
    [Surname]           VARCHAR (100)      NULL,
    [Mail]              VARCHAR (100)      NULL,
    [MailNickname]      VARCHAR (100)      NULL,
    [DeletionTimestamp] DATETIMEOFFSET (7) NULL,
    [AccountEnabled]    BIT                NOT NULL,
    [ImmutableID]       VARCHAR (250)      NULL,
    [ValidFrom]         DATETIME2 (7)      NOT NULL,
    [ValidTo]           DATETIME2 (7)      NOT NULL
);

