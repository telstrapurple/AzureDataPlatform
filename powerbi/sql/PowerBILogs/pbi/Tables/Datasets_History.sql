CREATE TABLE [pbi].[Datasets_History] (
    [Id]                               VARCHAR (50)       NOT NULL,
    [Name]                             NVARCHAR (MAX)     NULL,
    [ConfiguredBy]                     NVARCHAR (500)     NULL,
    [DefaultRetentionPolicy]           VARCHAR (255)      NULL,
    [AddRowsApiEnabled]                VARCHAR (50)       NULL,
    [Tables]                           VARCHAR (MAX)      NULL,
    [WebUrl]                           VARCHAR (MAX)      NULL,
    [Relationships]                    VARCHAR (MAX)      NULL,
    [Datasources]                      VARCHAR (MAX)      NULL,
    [DefaultMode]                      VARCHAR (100)      NULL,
    [IsRefreshable]                    VARCHAR (50)       NULL,
    [IsEffectiveIdentityRequired]      VARCHAR (50)       NULL,
    [IsEffectiveIdentityRolesRequired] VARCHAR (50)       NULL,
    [IsOnPremGatewayRequired]          VARCHAR (50)       NULL,
    [TargetStorageMode]                VARCHAR (200)      NULL,
    [ActualStorage]                    VARCHAR (200)      NULL,
    [CreatedDate]                      DATETIMEOFFSET (7) NULL,
    [ContentProviderType]              VARCHAR (200)      NULL,
    [ValidFrom]                        DATETIME2 (7)      NOT NULL,
    [ValidTo]                          DATETIME2 (7)      NOT NULL
);

