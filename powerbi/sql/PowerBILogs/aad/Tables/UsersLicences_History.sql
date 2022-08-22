CREATE TABLE [aad].[UsersLicences_History] (
    [UserID]    VARCHAR (50)  NOT NULL,
    [SKUID]     VARCHAR (50)  NOT NULL,
    [SKUName]   VARCHAR (500) NOT NULL,
    [ValidFrom] DATETIME2 (7) NOT NULL,
    [ValidTo]   DATETIME2 (7) NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_UsersLicences_History]
    ON [aad].[UsersLicences_History]([ValidTo] ASC, [ValidFrom] ASC) WITH (DATA_COMPRESSION = PAGE);

