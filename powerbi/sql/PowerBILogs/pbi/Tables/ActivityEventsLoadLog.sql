CREATE TABLE [pbi].[ActivityEventsLoadLog]
(
	[Id] INT IDENTITY (1, 1) NOT NULL,
	[StartDateTime] DATETIMEOFFSET (7) NOT NULL, 
	[EndDateTime] DATETIMEOFFSET (7) NOT NULL, 
	CONSTRAINT [PK_PBI_ActivityEventLoadLog] PRIMARY KEY CLUSTERED ([Id] ASC),
	CONSTRAINT [UC_PBI_ActivityEventLoadLog_StartDateTime] UNIQUE([StartDateTime]),
	CONSTRAINT [UC_PBI_ActivityEventLoadLog_EndDateTime] UNIQUE([EndDateTime])
)