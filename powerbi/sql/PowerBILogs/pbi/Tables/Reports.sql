﻿CREATE TABLE [pbi].[Reports] (
    [Id]                    VARCHAR (50) NOT NULL,
    [Name]                  NVARCHAR (MAX)   NULL,
	[WebUrl]				NVARCHAR (MAX)   NULL,
	[EmbedUrl]				NVARCHAR (MAX)   NULL,
	[DatasetId]				VARCHAR (50) NULL,
	ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (ValidFrom,ValidTo),
	CONSTRAINT [PK_PBI_Reports] PRIMARY KEY CLUSTERED ([Id] ASC)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = pbi.Reports_History));