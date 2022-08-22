CREATE TABLE [aad].[Groups_History] (
    [GroupID]         VARCHAR (50)  NOT NULL,
    [GroupName]       VARCHAR (250) NULL,
    [Mail]            VARCHAR (250) NULL,
    [MailEnabled]     BIT           NOT NULL,
    [SecurityEnabled] BIT           NOT NULL,
    [ValidFrom]       DATETIME2 (7) NOT NULL,
    [ValidTo]         DATETIME2 (7) NOT NULL
);

