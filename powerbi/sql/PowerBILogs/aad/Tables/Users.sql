CREATE TABLE [aad].[Users] (
    [UserID]            VARCHAR (50)                                       NOT NULL,
    [UserPrincipalName] VARCHAR (100)                                      NOT NULL,
    [DisplayName]       VARCHAR (500)                                      NOT NULL,
    [GivenName]         VARCHAR (100)                                      NULL,
    [Surname]           VARCHAR (100)                                      NULL,
    [Mail]              VARCHAR (100)                                      NULL,
    [MailNickname]      VARCHAR (100)                                      NULL,
    [DeletionTimestamp] DATETIMEOFFSET (7)                                 NULL,
    [AccountEnabled]    BIT                                                NOT NULL,
    [ImmutableID]       VARCHAR (250)                                      NULL,
    [ValidFrom]         DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    [ValidTo]           DATETIME2 (7) GENERATED ALWAYS AS ROW END HIDDEN   NOT NULL,
    CONSTRAINT [PK_AAD_Users] PRIMARY KEY CLUSTERED ([UserID] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[aad].[Users_History], DATA_CONSISTENCY_CHECK=ON));

