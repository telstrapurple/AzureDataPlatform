CREATE TABLE [aad].[UsersLicences] (
    [UserID]    VARCHAR (50)                                       NOT NULL,
    [SKUID]     VARCHAR (50)                                       NOT NULL,
    [SKUName]   VARCHAR (500)                                      NOT NULL,
    [ValidFrom] DATETIME2 (7) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    [ValidTo]   DATETIME2 (7) GENERATED ALWAYS AS ROW END HIDDEN   NOT NULL,
    CONSTRAINT [PK_AAD_UsersLicences] PRIMARY KEY CLUSTERED ([UserID] ASC, [SKUID] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[aad].[UsersLicences_History], DATA_CONSISTENCY_CHECK=ON));

