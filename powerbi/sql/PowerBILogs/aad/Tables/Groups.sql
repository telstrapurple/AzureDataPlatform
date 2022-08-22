CREATE TABLE [aad].[Groups] (
    [GroupID]         VARCHAR (50)                                       NOT NULL,
    [GroupName]       VARCHAR (250)                                      NULL,
    [Mail]            VARCHAR (250)                                      NULL,
    [MailEnabled]     BIT                                                NOT NULL,
    [SecurityEnabled] BIT                                                NOT NULL,
    [ValidFrom]       DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    [ValidTo]         DATETIME2 (7) GENERATED ALWAYS AS ROW END HIDDEN   NOT NULL,
    CONSTRAINT [PK_AAD_Groups] PRIMARY KEY CLUSTERED ([GroupID] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[aad].[Groups_History], DATA_CONSISTENCY_CHECK=ON));

