CREATE SCHEMA [DI]
GO

CREATE SCHEMA [SRC]
GO

/****** Object:  Table [DI].[Task]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[Task](
	[TaskID] [int] IDENTITY(1,1) NOT NULL,
	[TaskName] [nvarchar](100) NOT NULL,
	[TaskDescription] [nvarchar](250) NULL,
	[SystemID] [int] NOT NULL,
	[ScheduleID] [int] NOT NULL,
	[TaskTypeID] [int] NOT NULL,
	[SourceConnectionID] [int] NOT NULL,
	[ETLConnectionID] [int] NULL,
	[StageConnectionID] [int] NULL,
	[TargetConnectionID] [int] NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[TaskOrderID] [int] NULL,
 CONSTRAINT [PK_DI_Task] PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskInstance]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskInstance](
	[TaskInstanceID] [int] IDENTITY(1,1) NOT NULL,
	[TaskID] [int] NOT NULL,
	[ScheduleInstanceID] [int] NOT NULL,
	[RunDate] [datetime] NOT NULL,
	[TaskResultID] [int] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_TaskInstance] PRIMARY KEY CLUSTERED 
(
	[TaskInstanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskType]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskType](
	[TaskTypeID] [int] IDENTITY(1,1) NOT NULL,
	[TaskTypeName] [nvarchar](100) NOT NULL,
	[TaskTypeDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[ScriptIndicator] [bit] NULL,
	[FileLoadIndicator] [bit] NULL,
	[DatabaseLoadIndicator] [bit] NULL,
	[RunType] [varchar](50) NULL,
 CONSTRAINT [PK_DI_TaskType] PRIMARY KEY CLUSTERED 
(
	[TaskTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[Connection]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[Connection](
	[ConnectionID] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionName] [nvarchar](100) NOT NULL,
	[ConnectionDescription] [nvarchar](250) NULL,
	[ConnectionTypeID] [int] NOT NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[AuthenticationTypeID] [int] NULL,
 CONSTRAINT [PK_DI_Connection] PRIMARY KEY CLUSTERED 
(
	[ConnectionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[DataFactoryLog]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[DataFactoryLog](
	[DataFactoryLogID] [int] IDENTITY(1,1) NOT NULL,
	[TaskInstanceID] [int] NULL,
	[LogType] [varchar](50) NOT NULL,
	[DataFactoryName] [varchar](50) NOT NULL,
	[PipelineName] [varchar](100) NOT NULL,
	[PipelineRunID] [varchar](50) NOT NULL,
	[PipelineTriggerID] [varchar](50) NULL,
	[PipelineTriggerName] [varchar](100) NOT NULL,
	[PipelineTriggerTime] [datetimeoffset](7) NULL,
	[PipelineTriggerType] [varchar](50) NOT NULL,
	[ActivityName] [varchar](100) NOT NULL,
	[OutputMessage] [nvarchar](max) NULL,
	[ErrorMessage] [nvarchar](max) NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[EmailSentIndicator] [bit] NOT NULL,
	[FileLoadLogID] [int] NULL,
 CONSTRAINT [PK_DataFactoryLog] PRIMARY KEY CLUSTERED 
(
	[DataFactoryLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [DI].[Schedule]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[Schedule](
	[ScheduleID] [int] IDENTITY(1,1) NOT NULL,
	[ScheduleName] [nvarchar](100) NOT NULL,
	[ScheduleDescription] [nvarchar](250) NULL,
	[ScheduleIntervalID] [int] NOT NULL,
	[Frequency] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_Schedule] PRIMARY KEY CLUSTERED 
(
	[ScheduleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ScheduleInterval]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ScheduleInterval](
	[ScheduleIntervalID] [int] IDENTITY(1,1) NOT NULL,
	[ScheduleIntervalName] [nvarchar](100) NOT NULL,
	[ScheduleIntervalDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_ScheduleInterval] PRIMARY KEY CLUSTERED 
(
	[ScheduleIntervalID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[System]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[System](
	[SystemID] [int] IDENTITY(1,1) NOT NULL,
	[SystemName] [nvarchar](100) NOT NULL,
	[SystemDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[SystemCode] [nvarchar](100) NULL,
 CONSTRAINT [PK_DI_System] PRIMARY KEY CLUSTERED 
(
	[SystemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[SystemProperty]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[SystemProperty](
	[SystemPropertyID] [int] IDENTITY(1,1) NOT NULL,
	[SystemPropertyTypeID] [int] NOT NULL,
	[SystemID] [int] NOT NULL,
	[SystemPropertyValue] [nvarchar](4000) NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_SystemProperty] PRIMARY KEY CLUSTERED 
(
	[SystemPropertyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[SystemPropertyType]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[SystemPropertyType](
	[SystemPropertyTypeID] [int] IDENTITY(1,1) NOT NULL,
	[SystemPropertyTypeName] [nvarchar](100) NOT NULL,
	[SystemPropertyTypeDescription] [nvarchar](250) NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[SystemPropertyTypeValidationID] [int] NULL,
 CONSTRAINT [PK_DI_SystemPropertyType] PRIMARY KEY CLUSTERED 
(
	[SystemPropertyTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskProperty]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskProperty](
	[TaskPropertyID] [int] IDENTITY(1,1) NOT NULL,
	[TaskPropertyTypeID] [int] NOT NULL,
	[TaskID] [int] NOT NULL,
	[TaskPropertyValue] [nvarchar](4000) NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_TaskProperty] PRIMARY KEY CLUSTERED 
(
	[TaskPropertyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskPropertyType]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskPropertyType](
	[TaskPropertyTypeID] [int] IDENTITY(1,1) NOT NULL,
	[TaskPropertyTypeName] [nvarchar](100) NOT NULL,
	[TaskPropertyTypeDescription] [nvarchar](250) NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[TaskPropertyTypeValidationID] [int] NOT NULL,
 CONSTRAINT [PK_DI_TaskPropertyType] PRIMARY KEY CLUSTERED 
(
	[TaskPropertyTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[AuthenticationType]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[AuthenticationType](
	[AuthenticationTypeID] [int] IDENTITY(1,1) NOT NULL,
	[AuthenticationTypeName] [nvarchar](100) NOT NULL,
	[AuthenticationTypeDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_AuthenticationType] PRIMARY KEY CLUSTERED 
(
	[AuthenticationTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ConnectionProperty]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ConnectionProperty](
	[ConnectionPropertyID] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionPropertyTypeID] [int] NOT NULL,
	[ConnectionID] [int] NOT NULL,
	[ConnectionPropertyValue] [nvarchar](4000) NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_ConnectionProperty] PRIMARY KEY CLUSTERED 
(
	[ConnectionPropertyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ConnectionPropertyType]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ConnectionPropertyType](
	[ConnectionPropertyTypeID] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionPropertyTypeName] [nvarchar](100) NOT NULL,
	[ConnectionPropertyTypeDescription] [nvarchar](250) NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[ConnectionPropertyTypeValidationID] [int] NOT NULL,
 CONSTRAINT [PK_DI_ConnectionPropertyType] PRIMARY KEY CLUSTERED 
(
	[ConnectionPropertyTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ConnectionType]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ConnectionType](
	[ConnectionTypeID] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionTypeName] [nvarchar](100) NOT NULL,
	[ConnectionTypeDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[DatabaseConnectionIndicator] [bit] NOT NULL,
	[FileConnectionIndicator] [bit] NOT NULL,
	[CRMConnectionIndicator] [bit] NOT NULL,
	[ODBCConnectionIndicator] [bit] NOT NULL,
 CONSTRAINT [PK_DI_ConnectionType] PRIMARY KEY CLUSTERED 
(
	[ConnectionTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[CDCLoadLog]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[CDCLoadLog](
	[CDCLoadLogID] [int] IDENTITY(1,1) NOT NULL,
	[TaskInstanceID] [int] NOT NULL,
	[LatestLSNValue] [binary](10) NOT NULL,
	[SuccessIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[DateModified] [datetimeoffset](7) NULL,
 CONSTRAINT [PK_CDCLoadLog] PRIMARY KEY CLUSTERED 
(
	[CDCLoadLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ConnectionPropertyTypeOption]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ConnectionPropertyTypeOption](
	[ConnectionPropertyTypeOptionID] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionPropertyTypeID] [int] NOT NULL,
	[ConnectionPropertyTypeOptionName] [nvarchar](250) NOT NULL,
	[ConnectionPropertyTypeOptionDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_ConnectionPropertyTypeOption] PRIMARY KEY CLUSTERED 
(
	[ConnectionPropertyTypeOptionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ConnectionPropertyTypeValidation]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ConnectionPropertyTypeValidation](
	[ConnectionPropertyTypeValidationID] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionPropertyTypeValidationName] [nvarchar](250) NOT NULL,
	[ConnectionPropertyTypeValidationDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_ConnectionPropertyTypeValidation] PRIMARY KEY CLUSTERED 
(
	[ConnectionPropertyTypeValidationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ConnectionTypeAuthenticationTypeMapping]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ConnectionTypeAuthenticationTypeMapping](
	[ConnectionTypeAuthenticationTypeMappingID] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionTypeID] [int] NOT NULL,
	[AuthenticationTypeID] [int] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_ConnectionTypeAuthenticationTypeMapping] PRIMARY KEY CLUSTERED 
(
	[ConnectionTypeAuthenticationTypeMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ConnectionTypeConnectionPropertyTypeMapping]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ConnectionTypeConnectionPropertyTypeMapping](
	[ConnectionTypeConnectionPropertyTypeMappingID] [int] IDENTITY(1,1) NOT NULL,
	[ConnectionPropertyTypeID] [int] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[ConnectionTypeAuthenticationTypeMappingID] [int] NULL,
 CONSTRAINT [PK_DI_ConnectionTypeConnectionPropertyTypeMapping] PRIMARY KEY CLUSTERED 
(
	[ConnectionTypeConnectionPropertyTypeMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[FileColumnMapping]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[FileColumnMapping](
	[FileColumnMappingID] [int] IDENTITY(1,1) NOT NULL,
	[TaskID] [int] NOT NULL,
	[SourceColumnName] [nvarchar](1000) NOT NULL,
	[TargetColumnName] [nvarchar](1000) NOT NULL,
	[FileInterimDataTypeID] [int] NOT NULL,
	[DataLength] [varchar](50) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_FileColumnMapping] PRIMARY KEY CLUSTERED 
(
	[FileColumnMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[FileInterimDataType]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[FileInterimDataType](
	[FileInterimDataTypeID] [int] IDENTITY(1,1) NOT NULL,
	[FileInterimDataTypeName] [nvarchar](100) NOT NULL,
	[FileInterimDataTypeDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_FileInterimDataType] PRIMARY KEY CLUSTERED 
(
	[FileInterimDataTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[FileLoadLog]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[FileLoadLog](
	[FileLoadLogID] [int] IDENTITY(1,1) NOT NULL,
	[TaskInstanceID] [int] NOT NULL,
	[FilePath] [nvarchar](max) NOT NULL,
	[FileName] [nvarchar](max) NOT NULL,
	[FileLastModifiedDate] [datetimeoffset](7) NOT NULL,
	[SuccessIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[TargetFilePath] [nvarchar](max) NULL,
	[TargetFileName] [nvarchar](max) NULL,
 CONSTRAINT [PK_DI_FileLoadLog] PRIMARY KEY CLUSTERED 
(
	[FileLoadLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [DI].[GenericConfig]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[GenericConfig](
	[GenericConfigID] [int] IDENTITY(1,1) NOT NULL,
	[GenericConfigName] [nvarchar](100) NOT NULL,
	[GenericConfigDescription] [nvarchar](250) NULL,
	[GenericConfigValue] [nvarchar](max) NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_GenericConfig] PRIMARY KEY CLUSTERED 
(
	[GenericConfigID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [DI].[IncrementalLoadLog]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[IncrementalLoadLog](
	[IncrementalLoadLogID] [int] IDENTITY(1,1) NOT NULL,
	[TaskInstanceID] [int] NOT NULL,
	[EntityName] [nvarchar](500) NOT NULL,
	[IncrementalColumn] [nvarchar](100) NULL,
	[LatestValue] [nvarchar](100) NULL,
	[SuccessIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[DateModified] [datetimeoffset](7) NULL,
 CONSTRAINT [PK_IncrementalLoadLog] PRIMARY KEY CLUSTERED 
(
	[IncrementalLoadLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[ScheduleInstance]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[ScheduleInstance](
	[ScheduleInstanceID] [int] IDENTITY(1,1) NOT NULL,
	[ScheduleID] [int] NOT NULL,
	[RunDate] [datetime] NOT NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_ScheduleInstance] PRIMARY KEY CLUSTERED 
(
	[ScheduleInstanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[SystemDependency]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[SystemDependency](
	[SystemDependencyID] [int] IDENTITY(1,1) NOT NULL,
	[SystemID] [int] NOT NULL,
	[DependencyID] [int] NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_SystemDependency] PRIMARY KEY CLUSTERED 
(
	[SystemDependencyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[SystemPropertyTypeOption]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[SystemPropertyTypeOption](
	[SystemPropertyTypeOptionID] [int] IDENTITY(1,1) NOT NULL,
	[SystemPropertyTypeID] [int] NOT NULL,
	[SystemPropertyTypeOptionName] [nvarchar](250) NOT NULL,
	[SystemPropertyTypeOptionDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_SystemPropertyTypeOption] PRIMARY KEY CLUSTERED 
(
	[SystemPropertyTypeOptionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[SystemPropertyTypeValidation]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[SystemPropertyTypeValidation](
	[SystemPropertyTypeValidationID] [int] IDENTITY(1,1) NOT NULL,
	[SystemPropertyTypeValidationName] [nvarchar](250) NOT NULL,
	[SystemPropertyTypeValidationDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_SystemPropertyTypeValidation] PRIMARY KEY CLUSTERED 
(
	[SystemPropertyTypeValidationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskPropertyPassthroughMapping]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskPropertyPassthroughMapping](
	[TaskPropertyPassthroughMappingID] [int] IDENTITY(1,1) NOT NULL,
	[TaskID] [int] NOT NULL,
	[TaskPassthroughID] [int] NOT NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_TaskPropertyPassthroughMapping] PRIMARY KEY CLUSTERED 
(
	[TaskPropertyPassthroughMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskPropertyTypeOption]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskPropertyTypeOption](
	[TaskPropertyTypeOptionID] [int] IDENTITY(1,1) NOT NULL,
	[TaskPropertyTypeID] [int] NOT NULL,
	[TaskPropertyTypeOptionName] [nvarchar](250) NOT NULL,
	[TaskPropertyTypeOptionDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_TaskPropertyTypeOption] PRIMARY KEY CLUSTERED 
(
	[TaskPropertyTypeOptionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskPropertyTypeValidation]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskPropertyTypeValidation](
	[TaskPropertyTypeValidationID] [int] IDENTITY(1,1) NOT NULL,
	[TaskPropertyTypeValidationName] [nvarchar](250) NOT NULL,
	[TaskPropertyTypeValidationDescription] [nvarchar](250) NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_TaskPropertyTypeValidation] PRIMARY KEY CLUSTERED 
(
	[TaskPropertyTypeValidationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskResult]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskResult](
	[TaskResultID] [int] IDENTITY(1,1) NOT NULL,
	[TaskResultName] [nvarchar](100) NOT NULL,
	[TaskResultDescription] [nvarchar](250) NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[RetryIndicator] [bit] NOT NULL,
 CONSTRAINT [PK_DI_TaskResult] PRIMARY KEY CLUSTERED 
(
	[TaskResultID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[TaskTypeTaskPropertyTypeMapping]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[TaskTypeTaskPropertyTypeMapping](
	[TaskTypeTaskPropertyTypeMappingID] [int] IDENTITY(1,1) NOT NULL,
	[TaskTypeID] [int] NOT NULL,
	[TaskPropertyTypeID] [int] NOT NULL,
	[DeletedIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[DateModified] [datetimeoffset](7) NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_TaskTypeTaskPropertyTypeMapping] PRIMARY KEY CLUSTERED 
(
	[TaskTypeTaskPropertyTypeMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[User]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[User](
	[UserID] [nchar](36) NOT NULL,
	[UserName] [nvarchar](100) NOT NULL,
	[EmailAddress] [nvarchar](100) NOT NULL,
	[EnabledIndicator] [bit] NOT NULL,
	[AdminIndicator] [bit] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[DateModified] [datetimeoffset](7) NULL,
 CONSTRAINT [PK_DI_User] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DI].[UserPermission]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DI].[UserPermission](
	[UserPermissionID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [nchar](36) NOT NULL,
	[SystemID] [int] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
 CONSTRAINT [PK_DI_UserPermission] PRIMARY KEY CLUSTERED 
(
	[UserPermissionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [SRC].[DatabaseTable]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SRC].[DatabaseTable](
	[SourceType] [nvarchar](50) NOT NULL,
	[SourceSystem] [nvarchar](50) NOT NULL,
	[Schema] [nvarchar](50) NOT NULL,
	[TableName] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [SRC].[DatabaseTableColumn]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SRC].[DatabaseTableColumn](
	[ConnectionID] [int] NOT NULL,
	[Schema] [varchar](100) NOT NULL,
	[TableName] [varchar](100) NOT NULL,
	[ColumnID] [int] NOT NULL,
	[ColumnName] [varchar](100) NOT NULL,
	[DataType] [varchar](50) NOT NULL,
	[DataLength] [decimal](22, 0) NULL,
	[DataPrecision] [decimal](22, 0) NULL,
	[DataScale] [decimal](22, 0) NULL,
	[Nullable] [char](1) NULL,
	[ComputedIndicator] [char](1) NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_DatabaseTableColumn] PRIMARY KEY CLUSTERED 
(
	[ConnectionID] ASC,
	[Schema] ASC,
	[TableName] ASC,
	[ColumnID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [SRC].[DatabaseTableConstraint]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SRC].[DatabaseTableConstraint](
	[ConnectionID] [int] NOT NULL,
	[Schema] [varchar](100) NOT NULL,
	[TableName] [varchar](100) NOT NULL,
	[ColumnName] [varchar](100) NOT NULL,
	[ConstraintPosition] [int] NULL,
	[ConstraintType] [varchar](100) NOT NULL,
	[ConstraintName] [varchar](100) NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_DatabaseTableConstraint] PRIMARY KEY CLUSTERED 
(
	[ConnectionID] ASC,
	[Schema] ASC,
	[TableName] ASC,
	[ColumnName] ASC,
	[ConstraintName] ASC,
	[ConstraintType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [SRC].[DatabaseTableRowCount]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SRC].[DatabaseTableRowCount](
	[ConnectionID] [int] NOT NULL,
	[Schema] [varchar](100) NOT NULL,
	[TableName] [varchar](100) NOT NULL,
	[NoOfRows] [bigint] NOT NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_DatabaseTableRowCount] PRIMARY KEY CLUSTERED 
(
	[ConnectionID] ASC,
	[Schema] ASC,
	[TableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [SRC].[ODBCTable]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SRC].[ODBCTable](
	[SourceSystem] [nvarchar](50) NOT NULL,
	[Schema] [nvarchar](50) NOT NULL,
	[TableName] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [SRC].[ODBCTableColumn]    Script Date: 1/12/2020 10:36:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SRC].[ODBCTableColumn](
	[Schema] [varchar](100) NOT NULL,
	[TableName] [varchar](100) NOT NULL,
	[ColumnID] [int] NOT NULL,
	[ColumnName] [varchar](100) NOT NULL,
	[DataType] [varchar](50) NOT NULL,
	[DataLength] [decimal](22, 0) NULL,
	[DataPrecision] [decimal](22, 0) NULL,
	[DataScale] [decimal](22, 0) NULL,
	[Nullable] [char](1) NULL,
	[DateCreated] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_ODBCTableColumn] PRIMARY KEY CLUSTERED 
(
	[Schema] ASC,
	[TableName] ASC,
	[ColumnID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [DI].[AuthenticationType] ON 

INSERT [DI].[AuthenticationType] ([AuthenticationTypeID], [AuthenticationTypeName], [AuthenticationTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, N'Managed Service Identity', N'AAD Managed Service Identity', 1, 0, CAST(N'2020-04-21T06:23:29.0770520+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[AuthenticationType] ([AuthenticationTypeID], [AuthenticationTypeName], [AuthenticationTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, N'SQL Authentication or Managed Service Identity', N'SQL Authentication or AAD Managed Service Identity', 1, 0, CAST(N'2020-04-21T06:23:29.0770520+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[AuthenticationType] ([AuthenticationTypeID], [AuthenticationTypeName], [AuthenticationTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, N'Token', N'Token', 1, 0, CAST(N'2020-04-21T06:23:29.0770520+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[AuthenticationType] ([AuthenticationTypeID], [AuthenticationTypeName], [AuthenticationTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, N'Office365', N'Office365 Username and Password', 1, 0, CAST(N'2020-04-21T06:23:29.0770520+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[AuthenticationType] ([AuthenticationTypeID], [AuthenticationTypeName], [AuthenticationTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (5, N'Basic', N'Username and Password', 1, 0, CAST(N'2020-04-21T06:23:29.0770520+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[AuthenticationType] ([AuthenticationTypeID], [AuthenticationTypeName], [AuthenticationTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (6, N'OAuth', N'OAuth Token', 1, 0, CAST(N'2020-04-21T06:23:29.0770520+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[AuthenticationType] ([AuthenticationTypeID], [AuthenticationTypeName], [AuthenticationTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (7, N'SQL Authentication', N'SQL Authentication', 1, 0, CAST(N'2020-04-21T06:23:29.0770520+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[AuthenticationType] ([AuthenticationTypeID], [AuthenticationTypeName], [AuthenticationTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (8, N'Anonymous', N'Anonymous authentication', 1, 0, CAST(N'2020-05-04T11:01:29.9185451+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[AuthenticationType] OFF
SET IDENTITY_INSERT [DI].[Connection] ON 

INSERT [DI].[Connection] ([ConnectionID], [ConnectionName], [ConnectionDescription], [ConnectionTypeID], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [AuthenticationTypeID]) VALUES (1, N'ADS Config', N'This is the connection to the ADS_Config database', 1, 1, 0, CAST(N'2019-12-02T03:47:47.0000000+00:00' AS DateTimeOffset), N'Mystery', NULL, NULL, 2)
INSERT [DI].[Connection] ([ConnectionID], [ConnectionName], [ConnectionDescription], [ConnectionTypeID], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [AuthenticationTypeID]) VALUES (2, N'ADS Staging', N'This is the connection to the ADS_Stage database', 1, 1, 0, CAST(N'2019-12-02T03:48:12.3461899+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[Connection] ([ConnectionID], [ConnectionName], [ConnectionDescription], [ConnectionTypeID], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [AuthenticationTypeID]) VALUES (3, N'Databricks ETL Cluster', N'This is the connection for the Databricks ETL cluster', 4, 1, 0, CAST(N'2019-12-02T06:11:21.0000000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 3)
INSERT [DI].[Connection] ([ConnectionID], [ConnectionName], [ConnectionDescription], [ConnectionTypeID], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [AuthenticationTypeID]) VALUES (4, N'ADS Data Lake', N'This is the connection for the ADS data lake connection', 3, 1, 0, CAST(N'2019-12-02T06:12:49.0000000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
SET IDENTITY_INSERT [DI].[Connection] OFF
SET IDENTITY_INSERT [DI].[ConnectionProperty] ON 

INSERT [DI].[ConnectionProperty] ([ConnectionPropertyID], [ConnectionPropertyTypeID], [ConnectionID], [ConnectionPropertyValue], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, 5, 1, N'sqlDatabaseConnectionStringConfig', 0, CAST(N'2019-12-02T03:47:47.6116565+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionProperty] ([ConnectionPropertyID], [ConnectionPropertyTypeID], [ConnectionID], [ConnectionPropertyValue], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, 5, 2, N'sqlDatabaseConnectionStringStage', 0, CAST(N'2019-12-02T03:48:12.3461899+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[ConnectionProperty] OFF
SET IDENTITY_INSERT [DI].[ConnectionPropertyType] ON 

INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (5, N'KeyVault Secret Name', N'This is the KeyVault Secret Name', 0, CAST(N'2019-02-06T23:52:13.0500000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (6, N'Service Endpoint', N'This is the Service Endpoint for the storage server', 0, CAST(N'2019-02-06T23:59:51.4133333+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (7, N'Databricks URL', N'The URL for the Azure Databricks workspace', 0, CAST(N'2019-02-07T05:50:52.9200000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (8, N'Databricks Cluster ID', N'The cluster id for the Azure Databricks cluster', 0, CAST(N'2019-02-07T05:50:52.9200000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (12, N'Data Lake Date Mask', N'This is the format of the date mask in the data lake used for daily snapshots', 0, CAST(N'2019-11-01T03:43:33.7415812+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (14, N'CRM User Name KeyVault Secret', N'This is the name of the KeyVault secret which stores the user name for the CRM online connection', 0, CAST(N'2019-02-06T23:52:13.0500000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (15, N'CRM Password KeyVault Secret', N'This is the name of the KeyVault secret which stores the password for the CRM online connection', 0, CAST(N'2019-02-06T23:52:13.0500000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (23, N'KeyVault Secret - Connection String', N'The is the name of the KeyVault secret which stores the connection string', 0, CAST(N'2020-03-27T00:00:00.0000000+08:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (25, N'KeyVault Secret - User Name', N'The is the name of the KeyVault secret which stores the user name for the connection', 0, CAST(N'2020-03-27T00:00:00.0000000+08:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (26, N'KeyVault Secret - Password', N'The is the name of the KeyVault secret which stores the pasword for the connection', 0, CAST(N'2020-03-27T00:00:00.0000000+08:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (28, N'KeyVault Secret Name - Client ID', N'KeyVault Secret Name for the Service Principal ID', 0, CAST(N'2020-04-22T01:12:38.8283876+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (29, N'KeyVault Secret Name - Client Secret', N'KeyVault Secret Name for the Service Principal Secret', 0, CAST(N'2020-04-22T01:12:38.8283876+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (30, N'Authorization Endpoint', N'This is the URL for the Authorization Server.', 0, CAST(N'2020-04-22T02:11:25.0644778+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (32, N'ODBC Connection Type', N'The type of ODBC connection to use', 0, CAST(N'2020-07-14T02:20:31.5343064+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID], [ConnectionPropertyTypeName], [ConnectionPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionPropertyTypeValidationID]) VALUES (34, N'REST Connection Type', N'The type of OREST connection to use', 0, CAST(N'2020-07-14T02:20:31.5343064+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
SET IDENTITY_INSERT [DI].[ConnectionPropertyType] OFF
SET IDENTITY_INSERT [DI].[ConnectionPropertyTypeOption] ON 

INSERT [DI].[ConnectionPropertyTypeOption] ([ConnectionPropertyTypeOptionID], [ConnectionPropertyTypeID], [ConnectionPropertyTypeOptionName], [ConnectionPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, 12, N'', NULL, 1, 0, CAST(N'2020-03-09T15:08:31.0365501+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeOption] ([ConnectionPropertyTypeOptionID], [ConnectionPropertyTypeID], [ConnectionPropertyTypeOptionName], [ConnectionPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, 12, N'yyyy/MM/dd', NULL, 1, 0, CAST(N'2020-03-09T15:08:31.0365501+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeOption] ([ConnectionPropertyTypeOptionID], [ConnectionPropertyTypeID], [ConnectionPropertyTypeOptionName], [ConnectionPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, 12, N'yyyy/MM/dd/HH', NULL, 1, 0, CAST(N'2020-05-11T15:24:50.4310081+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeOption] ([ConnectionPropertyTypeOptionID], [ConnectionPropertyTypeID], [ConnectionPropertyTypeOptionName], [ConnectionPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (5, 12, N'yyyy/MM/dd/HH/mm', NULL, 1, 0, CAST(N'2020-05-11T15:24:50.4310081+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeOption] ([ConnectionPropertyTypeOptionID], [ConnectionPropertyTypeID], [ConnectionPropertyTypeOptionName], [ConnectionPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (7, 32, N'Generic', NULL, 1, 0, CAST(N'2020-07-14T02:20:31.5499892+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeOption] ([ConnectionPropertyTypeOptionID], [ConnectionPropertyTypeID], [ConnectionPropertyTypeOptionName], [ConnectionPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (8, 32, N'MySQL', NULL, 1, 0, CAST(N'2020-07-14T02:20:31.5499892+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeOption] ([ConnectionPropertyTypeOptionID], [ConnectionPropertyTypeID], [ConnectionPropertyTypeOptionName], [ConnectionPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (9, 34, N'Generic', NULL, 1, 0, CAST(N'2020-07-14T02:20:31.5499892+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeOption] ([ConnectionPropertyTypeOptionID], [ConnectionPropertyTypeID], [ConnectionPropertyTypeOptionName], [ConnectionPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (10, 34, N'Oracle Services Cloud', NULL, 1, 0, CAST(N'2020-07-14T02:20:31.5499892+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[ConnectionPropertyTypeOption] OFF
SET IDENTITY_INSERT [DI].[ConnectionPropertyTypeValidation] ON 

INSERT [DI].[ConnectionPropertyTypeValidation] ([ConnectionPropertyTypeValidationID], [ConnectionPropertyTypeValidationName], [ConnectionPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, N'TextBox', N'This is the validation type for the TextBox form control', 1, 0, CAST(N'2020-02-28T03:48:10.2672753+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeValidation] ([ConnectionPropertyTypeValidationID], [ConnectionPropertyTypeValidationName], [ConnectionPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, N'DropDownList', N'This is the validation type for the DropDownList form control', 1, 0, CAST(N'2020-02-28T03:48:10.2672753+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeValidation] ([ConnectionPropertyTypeValidationID], [ConnectionPropertyTypeValidationName], [ConnectionPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, N'NumberBox', N'This is the validation type for the NumberBox form control', 1, 0, CAST(N'2020-02-28T03:48:10.2672753+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionPropertyTypeValidation] ([ConnectionPropertyTypeValidationID], [ConnectionPropertyTypeValidationName], [ConnectionPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, N'MultiLineTextBox', N'This is the validation type for the MultiLineTextBox form control', 1, 0, CAST(N'2020-03-23T04:52:10.3563614+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[ConnectionPropertyTypeValidation] OFF
SET IDENTITY_INSERT [DI].[ConnectionType] ON 

INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (1, N'Azure SQL', N'A SQL Azure connection', 1, 0, CAST(N'2019-02-06T23:25:46.9833333+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1, 0, 0, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (3, N'Azure Data Lake Gen 2', N'An Azure Data Lake Gen 2 connection', 1, 0, CAST(N'2019-02-06T23:25:46.9833333+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (4, N'Azure Databricks', N'An Azure Databricks connection', 1, 0, CAST(N'2019-02-07T05:58:34.4233333+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (5, N'Oracle', N'An Oracle database connection', 1, 0, CAST(N'2019-10-29T01:11:30.0133333+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1, 0, 0, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (6, N'SQL Server', N'An on premise SQL Server database connection', 1, 0, CAST(N'2019-10-29T01:13:38.4400000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1, 0, 0, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (7, N'Azure Blob Storage', N'An Azure Blob Storage connection', 1, 0, CAST(N'2019-12-19T03:27:55.6923370+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (8, N'File Share', N'A local file share connection', 1, 0, CAST(N'2019-12-19T03:27:55.6923370+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (12, N'Azure Synapse', N'SQL DW Connection', 1, 0, CAST(N'2020-01-14T07:51:43.5651062+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1, 0, 0, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (13, N'Dynamics CRM', N'An online Dynamics CRM connection', 1, 0, CAST(N'2020-01-25T00:00:00.0000000+08:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 1, 0)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (14, N'ODBC', N'A Generic ODBC Source', 1, 0, CAST(N'2020-03-27T02:27:25.2300839+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, 1)
INSERT [DI].[ConnectionType] ([ConnectionTypeID], [ConnectionTypeName], [ConnectionTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [DatabaseConnectionIndicator], [FileConnectionIndicator], [CRMConnectionIndicator], [ODBCConnectionIndicator]) VALUES (15, N'REST API', N'REST API Connection', 1, 0, CAST(N'2020-04-21T06:17:46.9722008+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, 0)
SET IDENTITY_INSERT [DI].[ConnectionType] OFF
SET IDENTITY_INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ON 

INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, 7, 1, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, 6, 7, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, 1, 2, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, 12, 2, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (5, 4, 3, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (6, 3, 1, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (7, 13, 4, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (8, 15, 5, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (9, 15, 6, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (10, 8, 5, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (11, 14, 5, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (12, 5, 7, 0, CAST(N'2020-04-21T06:24:44.4510732+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID], [ConnectionTypeID], [AuthenticationTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (13, 15, 8, 0, CAST(N'2020-05-04T11:02:42.4971123+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[ConnectionTypeAuthenticationTypeMapping] OFF
SET IDENTITY_INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ON 

INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (1, 5, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 3)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (2, 12, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 6)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (3, 6, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 6)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (4, 8, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 5)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (5, 7, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 5)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (6, 5, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 12)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (7, 5, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (8, 6, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (9, 5, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 4)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (10, 6, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 7)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (11, 14, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 7)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (12, 15, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 7)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (13, 23, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 11)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (14, 25, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 11)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (15, 26, 0, CAST(N'2020-04-20T06:52:10.7293308+00:00' AS DateTimeOffset), NULL, NULL, NULL, 11)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (16, 6, 0, CAST(N'2020-04-22T02:24:04.9769355+00:00' AS DateTimeOffset), NULL, NULL, NULL, 9)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (17, 28, 0, CAST(N'2020-04-22T02:24:04.9769355+00:00' AS DateTimeOffset), NULL, NULL, NULL, 9)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (18, 29, 0, CAST(N'2020-04-22T02:24:04.9769355+00:00' AS DateTimeOffset), NULL, NULL, NULL, 9)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (19, 30, 0, CAST(N'2020-04-22T02:24:04.9769355+00:00' AS DateTimeOffset), NULL, NULL, NULL, 9)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (20, 6, 0, CAST(N'2020-04-22T02:24:04.9769355+00:00' AS DateTimeOffset), NULL, NULL, NULL, 8)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (21, 25, 0, CAST(N'2020-04-22T02:24:04.9769355+00:00' AS DateTimeOffset), NULL, NULL, NULL, 8)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (22, 26, 0, CAST(N'2020-04-22T02:24:04.9769355+00:00' AS DateTimeOffset), NULL, NULL, NULL, 8)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (23, 25, 0, CAST(N'2020-04-24T05:03:51.4824529+00:00' AS DateTimeOffset), NULL, NULL, NULL, 10)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (24, 26, 0, CAST(N'2020-04-24T05:03:51.4824529+00:00' AS DateTimeOffset), NULL, NULL, NULL, 10)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (25, 6, 0, CAST(N'2020-05-04T11:05:07.2637689+00:00' AS DateTimeOffset), NULL, NULL, NULL, 13)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (26, 32, 0, CAST(N'2020-07-14T02:30:07.9053237+00:00' AS DateTimeOffset), NULL, NULL, NULL, 11)
INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] ([ConnectionTypeConnectionPropertyTypeMappingID], [ConnectionPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ConnectionTypeAuthenticationTypeMappingID]) VALUES (27, 34, 0, CAST(N'2020-07-14T02:30:07.9053237+00:00' AS DateTimeOffset), NULL, NULL, NULL, 8)
SET IDENTITY_INSERT [DI].[ConnectionTypeConnectionPropertyTypeMapping] OFF
SET IDENTITY_INSERT [DI].[FileInterimDataType] ON 

INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, N'Byte', N'Byte', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, N'Boolean', N'Boolean', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, N'Datetime', N'Datetime', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, N'Datetimeoffset', N'Datetimeoffset', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (5, N'Decimal', N'Decimal', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (6, N'Double', N'Double', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (7, N'Guid', N'Guid', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (8, N'Int16', N'Int16', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (9, N'Int32', N'Int32', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (10, N'Int64', N'Int64', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (11, N'Single', N'Single', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (12, N'String', N'String', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (13, N'Timespan', N'Timespan', 1, 0, CAST(N'2019-12-19T03:03:38.6470865+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (14, N'Date', N'Date', 1, 0, CAST(N'2020-07-27T03:11:08.8086962+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[FileInterimDataType] ([FileInterimDataTypeID], [FileInterimDataTypeName], [FileInterimDataTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (15, N'Unicode String', N'Unicode String', 1, 0, CAST(N'2020-07-27T03:11:08.8086962+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[FileInterimDataType] OFF
SET IDENTITY_INSERT [DI].[GenericConfig] ON 

INSERT [DI].[GenericConfig] ([GenericConfigID], [GenericConfigName], [GenericConfigDescription], [GenericConfigValue], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, N'Logic App Send Email URL', N'This is the URL for the HTTP trigger which fires the Logic App to send an email', N'$LogicAppSendEmailUrl$', CAST(N'2019-11-12T09:52:06.0000000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[GenericConfig] ([GenericConfigID], [GenericConfigName], [GenericConfigDescription], [GenericConfigValue], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, N'Notification Email Address', N'This is the email address that notifications are sent to. Separate multiple email addresses with ";".', N'$WebAppAdminUPN$', CAST(N'2019-11-12T09:59:41.0000000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[GenericConfig] ([GenericConfigID], [GenericConfigName], [GenericConfigDescription], [GenericConfigValue], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (5, N'Logic App Scale Azure VM URL', N'This is the URL for the HTTP trigger which fires the Logic App to scale an Azure VM', N'$LogicAppScaleVMUrl$', CAST(N'2019-12-03T03:29:41.0000000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[GenericConfig] ([GenericConfigID], [GenericConfigName], [GenericConfigDescription], [GenericConfigValue], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (6, N'Logic App Scale Azure SQL URL', N'This is the URL for the HTTP trigger which fires the Logic App to scale an Azure SQL database', N'$LogicAppScaleSQLUrl$', CAST(N'2019-12-03T03:29:41.0000000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[GenericConfig] ([GenericConfigID], [GenericConfigName], [GenericConfigDescription], [GenericConfigValue], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (7, N'KeyVault Name', N'This is the name of the KeyVault resource', N'$KeyVaultName$', CAST(N'2020-01-20T02:39:58.0000000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[GenericConfig] OFF
SET IDENTITY_INSERT [DI].[Schedule] ON 

INSERT [DI].[Schedule] ([ScheduleID], [ScheduleName], [ScheduleDescription], [ScheduleIntervalID], [Frequency], [StartDate], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, N'Once a day', N'This schedule runs once a day', 3, 1, CAST(N'2019-01-01T00:00:00.000' AS DateTime), 1, 0, CAST(N'2019-02-05T04:36:32.0000000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[Schedule] ([ScheduleID], [ScheduleName], [ScheduleDescription], [ScheduleIntervalID], [Frequency], [StartDate], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, N'Once every hour', N'This schedule runs once an hour', 2, 1, CAST(N'2019-01-01T00:00:00.000' AS DateTime), 1, 0, CAST(N'2019-02-05T07:16:55.3700000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[Schedule] ([ScheduleID], [ScheduleName], [ScheduleDescription], [ScheduleIntervalID], [Frequency], [StartDate], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, N'Once every 15 minutes', N'This schedule runs once every 15 minutes', 1, 15, CAST(N'2019-01-01T00:00:00.000' AS DateTime), 1, 0, CAST(N'2019-02-05T07:16:55.3700000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[Schedule] ([ScheduleID], [ScheduleName], [ScheduleDescription], [ScheduleIntervalID], [Frequency], [StartDate], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (5, N'Once a month', N'This schedule runs once a month', 5, 1, CAST(N'2019-01-01T00:00:00.000' AS DateTime), 1, 0, CAST(N'2020-05-27T05:55:00.0040928+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[Schedule] OFF
SET IDENTITY_INSERT [DI].[ScheduleInterval] ON 

INSERT [DI].[ScheduleInterval] ([ScheduleIntervalID], [ScheduleIntervalName], [ScheduleIntervalDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, N'Minutes', N'This schedule runs every x minutes', 1, 0, CAST(N'2019-02-05T03:11:11.4833333+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ScheduleInterval] ([ScheduleIntervalID], [ScheduleIntervalName], [ScheduleIntervalDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, N'Hours', N'This schedule runs every x Hours', 1, 0, CAST(N'2019-02-05T03:11:17.7966667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ScheduleInterval] ([ScheduleIntervalID], [ScheduleIntervalName], [ScheduleIntervalDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, N'Days', N'This schedule runs every x Days', 1, 0, CAST(N'2019-02-05T03:11:22.8266667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ScheduleInterval] ([ScheduleIntervalID], [ScheduleIntervalName], [ScheduleIntervalDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, N'Weeks', N'This schedule runs every x weeks', 1, 0, CAST(N'2020-03-31T13:57:28.3522815+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[ScheduleInterval] ([ScheduleIntervalID], [ScheduleIntervalName], [ScheduleIntervalDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (5, N'Months', N'This schedule runs every x months', 1, 0, CAST(N'2020-03-31T13:57:28.3522815+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[ScheduleInterval] OFF
SET IDENTITY_INSERT [DI].[SystemPropertyType] ON 

INSERT [DI].[SystemPropertyType] ([SystemPropertyTypeID], [SystemPropertyTypeName], [SystemPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [SystemPropertyTypeValidationID]) VALUES (1, N'Allow Schema Drift', N'This setting will allow you to handle schema drift without raising an errors.', 0, CAST(N'2019-11-06T00:05:20.0943850+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[SystemPropertyType] ([SystemPropertyTypeID], [SystemPropertyTypeName], [SystemPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [SystemPropertyTypeValidationID]) VALUES (3, N'Partition Count', N'This is the number of partitions to use for batch loads from source', 0, CAST(N'2019-11-21T01:18:43.9730529+00:00' AS DateTimeOffset), NULL, NULL, NULL, 3)
INSERT [DI].[SystemPropertyType] ([SystemPropertyTypeID], [SystemPropertyTypeName], [SystemPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [SystemPropertyTypeValidationID]) VALUES (4, N'Delta Lake Retention Days', N'The default number of days to maintain history in Delta Lake tables', 0, CAST(N'2020-02-06T00:15:08.0756760+00:00' AS DateTimeOffset), NULL, NULL, NULL, 3)
INSERT [DI].[SystemPropertyType] ([SystemPropertyTypeID], [SystemPropertyTypeName], [SystemPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [SystemPropertyTypeValidationID]) VALUES (5, N'Include SQL Data Lineage', N'This setting will allow you to add data lineage columns to all tables in the SQL staging database ', 0, CAST(N'2020-04-30T01:57:00.8858067+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[SystemPropertyType] ([SystemPropertyTypeID], [SystemPropertyTypeName], [SystemPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [SystemPropertyTypeValidationID]) VALUES (6, N'Target Schema', N'The name of the target schema in the SQL staging database', 0, CAST(N'2020-05-13T10:25:55.4906067+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[SystemPropertyType] ([SystemPropertyTypeID], [SystemPropertyTypeName], [SystemPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [SystemPropertyTypeValidationID]) VALUES (7, N'System Priority', N'The priority number used to order the systems in an asecending order where a higher number has a lower priority. A blank priorty will result in the system having the lowest priority.', 0, CAST(N'2020-05-18T01:40:48.7289181+00:00' AS DateTimeOffset), NULL, NULL, NULL, 3)
SET IDENTITY_INSERT [DI].[SystemPropertyType] OFF
SET IDENTITY_INSERT [DI].[SystemPropertyTypeOption] ON 

INSERT [DI].[SystemPropertyTypeOption] ([SystemPropertyTypeOptionID], [SystemPropertyTypeID], [SystemPropertyTypeOptionName], [SystemPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, 1, N'N', NULL, 1, 0, CAST(N'2020-02-06T01:08:55.8970324+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[SystemPropertyTypeOption] ([SystemPropertyTypeOptionID], [SystemPropertyTypeID], [SystemPropertyTypeOptionName], [SystemPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, 1, N'Y', NULL, 1, 0, CAST(N'2020-02-06T01:08:55.8970324+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[SystemPropertyTypeOption] ([SystemPropertyTypeOptionID], [SystemPropertyTypeID], [SystemPropertyTypeOptionName], [SystemPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, 5, N'N', NULL, 1, 0, CAST(N'2020-04-30T01:58:22.3987337+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[SystemPropertyTypeOption] ([SystemPropertyTypeOptionID], [SystemPropertyTypeID], [SystemPropertyTypeOptionName], [SystemPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, 5, N'Y', NULL, 1, 0, CAST(N'2020-04-30T01:58:22.3987337+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[SystemPropertyTypeOption] OFF
SET IDENTITY_INSERT [DI].[SystemPropertyTypeValidation] ON 

INSERT [DI].[SystemPropertyTypeValidation] ([SystemPropertyTypeValidationID], [SystemPropertyTypeValidationName], [SystemPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, N'TextBox', NULL, 1, 0, CAST(N'2020-02-06T01:05:03.4165230+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[SystemPropertyTypeValidation] ([SystemPropertyTypeValidationID], [SystemPropertyTypeValidationName], [SystemPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, N'DropDownList', NULL, 1, 0, CAST(N'2020-02-06T01:05:03.4165230+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[SystemPropertyTypeValidation] ([SystemPropertyTypeValidationID], [SystemPropertyTypeValidationName], [SystemPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, N'NumberBox', NULL, 1, 0, CAST(N'2020-02-06T01:05:03.4165230+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[SystemPropertyTypeValidation] ([SystemPropertyTypeValidationID], [SystemPropertyTypeValidationName], [SystemPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, N'MultiLineTextBox', N'This is the validation type for the MultiLineTextBox form control', 1, 0, CAST(N'2020-03-23T04:54:25.3572151+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[SystemPropertyTypeValidation] OFF
SET IDENTITY_INSERT [DI].[TaskPropertyType] ON 

INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (1, N'SQL Command', N'This is the property type for a SQL select statement. Please note that CDC enabled sources do not support custom SQL command.', 0, CAST(N'2019-02-05T04:39:59.4166667+00:00' AS DateTimeOffset), NULL, NULL, NULL, 4)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (2, N'Source Table', N'This is the name of the source table', 0, CAST(N'2019-02-05T12:24:32.0766667+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (3, N'Target File Path', N'This is the target file path', 0, CAST(N'2019-02-07T04:04:32.8000000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (4, N'Target Table', N'This is the name of the target table', 0, CAST(N'2019-02-07T04:05:40.1000000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (5, N'Source File Path', N'This is the source file path', 0, CAST(N'2019-10-31T03:43:24.2944316+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (6, N'Source File Name', N'This is the name of the source file', 0, CAST(N'2019-10-31T09:54:14.7288818+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (7, N'Target File Name', N'This is the name of the target file', 0, CAST(N'2019-10-31T09:54:14.7288818+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (8, N'Task Load Type', N'This is the load type for the task, either Full or Incremental', 0, CAST(N'2019-11-01T00:38:07.0940700+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (9, N'Incremental Column', N'This is the name of the source column that is to be used for the incremental load logic', 0, CAST(N'2019-11-19T01:47:22.7208833+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (10, N'Incremental Value', N'This is value that the incremental load column should be decreased by for the incremental load. Ensure there is some overlap', 0, CAST(N'2019-11-19T01:50:41.4788596+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (11, N'Batch Column', N'This is the column that will be used to perform batch loads for large tables', 0, CAST(N'2019-11-21T01:07:53.9467492+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (12, N'Ignore Source Key', N'This setting will allow you to ignore the source key constraint if it is not required in the target. Values are N or Y', 0, CAST(N'2019-12-17T02:20:20.9716048+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (13, N'Compression Type', N'This is the compression type for the source file', 0, CAST(N'2019-12-20T03:15:42.9860765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (14, N'Column Delimiter', N'This is the column delimiter for the source file', 0, CAST(N'2019-12-20T03:15:42.9860765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (16, N'Encoding', N'This is the encoding for the source file', 0, CAST(N'2019-12-20T03:15:42.9860765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (17, N'Escape Character', N'This is the escape charaster for the source file', 0, CAST(N'2019-12-20T03:15:42.9860765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (18, N'Quote Character', N'This is the quote charaster for the source file', 0, CAST(N'2019-12-20T03:15:42.9860765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (19, N'First Row as Header', N'This is the indicator to use the first row as the header row for the source file', 0, CAST(N'2019-12-20T03:15:42.9860765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (20, N'Null Value', N'This is the null value character for the source file', 0, CAST(N'2019-12-20T03:15:42.9860765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (21, N'Skip Line Count', N'This is the number of rows to skip for the source file', 0, CAST(N'2019-12-20T03:15:42.9860765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 3)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (22, N'Host', N'This is the host for a Local File System', 0, CAST(N'2020-01-08T05:38:03.6066526+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (23, N'File Format', N'This is the file format for a file load', 0, CAST(N'2020-01-10T01:30:58.0445201+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (25, N'Stored Procedure', N'This is the name of the stored procedure to execute', 0, CAST(N'2020-01-29T05:42:33.9594049+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (26, N'Databricks notebook', N'This is the path of the databricks notebook', 0, CAST(N'2020-01-29T06:42:16.9771274+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (27, N'Collection Reference', N'This is the name of the nested array in a json document', 0, CAST(N'2020-01-30T23:56:41.1658765+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (29, N'Use Delta Lake', N'This is an indicator of whether or not to use Delta Lake', 0, CAST(N'2020-02-06T06:15:11.9739691+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (32, N'Target Key Column List', N'This is the comma separated list of key columns for the target table and delta lake', 0, CAST(N'2020-02-11T04:43:12.8206305+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (33, N'Target Database', N'This is the name of the target ADS database', 0, CAST(N'2020-02-13T02:55:36.3156090+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (34, N'Entity Name', N'This is the property type for the Entity name', 0, CAST(N'2020-02-25T00:00:00.0000000+08:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (37, N'Lapse Days', N'This is the number of days to go back for incremental loads', 0, CAST(N'2020-02-25T00:00:00.0000000+08:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (38, N'Clustered Columnstore Index', N'This is the property type to indicate if a clustered columnstore index should be created on the target database table', 0, CAST(N'2020-02-27T00:19:43.7787227+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (40, N'File Load Order By', N'This is the order in which the files will load by. The options available are DateModified or FilePathName (a concatenation of file path and file name).', 0, CAST(N'2020-02-27T10:51:03.1215637+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (41, N'Force File Reload', N'Reloads the same file(s) in the Source File Path specified.', 0, CAST(N'2020-03-05T02:37:45.2451511+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (42, N'Fetch XML', N'This is the custom Fetch XML that gets executed at the source', 0, CAST(N'2020-03-23T06:29:17.4386165+00:00' AS DateTimeOffset), NULL, NULL, NULL, 4)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (43, N'Incremental File Load Type', N'This is the property to define whether an incremental file load should be Insert or InsertUpdate.', 0, CAST(N'2020-03-24T12:08:20.2131766+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (44, N'Incremental Column Format', N'This is the format in which the incremental date is queried against source', 0, CAST(N'2020-04-02T02:24:47.4139911+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (46, N'Relative URL', N'Relative URL appended to the end of the REST endpoint URL specified in the REST API connection.', 0, CAST(N'2020-04-23T02:51:43.8019660+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (48, N'Token Request Additional Body', N'Only applicable for OAuth APIs. Specify additional request body. For example: "&grant_type=client_credentials&resource=https://management.azure.com/".', 0, CAST(N'2020-05-04T14:08:32.6375931+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (49, N'Data Lake Date Mask Overwrite', N'Overwrite value for the Data Lake Date Mask configured in Connection Properties.', 0, CAST(N'2020-05-11T13:57:09.8827372+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (50, N'History Table', N'Generate a history table in SQL and Data Lake. The table must have a key otherwise the load will fail.', 0, CAST(N'2020-06-24T01:16:13.4350106+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (51, N'Use SQL CDC', N'Perform ingestion using an existing CDC table from an Azure SQL or On-Prem SQL Server connection. The table must have a key otherwise the load will fail.', 0, CAST(N'2020-07-06T03:21:49.2081683+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (52, N'Data Lake Staging Create', N'Write a copy of the Delta Lake table to the Data Lake Staging area in a parquet format. Delta Lake will need to be enabled to use this feature.', 0, CAST(N'2020-07-16T08:52:38.4010000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 2)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (53, N'Data Lake Staging Partitions', N'The number of file partitions to be written to the Data Lake Staging area. If this is left blank or set to "0", then it will default to Spark''s optimal file partitioning.', 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL, 3)
INSERT [DI].[TaskPropertyType] ([TaskPropertyTypeID], [TaskPropertyTypeName], [TaskPropertyTypeDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [TaskPropertyTypeValidationID]) VALUES (55, N'Target Schema Overwrite', N'Overwrite value for the target schema configured in System Properties', 0, CAST(N'2020-08-12T04:20:53.4877799+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
SET IDENTITY_INSERT [DI].[TaskPropertyType] OFF
SET IDENTITY_INSERT [DI].[TaskPropertyTypeOption] ON 

INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (68, 16, N'UTF-8', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (69, 16, N'UTF-16', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (70, 16, N'UTF-16BE', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (71, 16, N'UTF-32', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (72, 16, N'UTF-32BE', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (73, 16, N'US-ASCII', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (74, 16, N'UTF-7', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (75, 16, N'BIG5', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (76, 16, N'EUC-JP', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (77, 16, N'EUC-KR', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (78, 16, N'GB2312', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (79, 16, N'GB18030', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (80, 16, N'JOHAB', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (81, 16, N'SHIFT-JIS', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (82, 16, N'CP875', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (83, 16, N'CP866', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (84, 16, N'IBM00858', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (85, 16, N'IBM037', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (86, 16, N'IBM273', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (87, 16, N'IBM437', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (88, 16, N'IBM500', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (89, 16, N'IBM737', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (90, 16, N'IBM775', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (91, 16, N'IBM850', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (92, 16, N'IBM852', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (93, 16, N'IBM855', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (94, 16, N'IBM857', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (95, 16, N'IBM860', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (96, 16, N'IBM861', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (97, 16, N'IBM863', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (98, 16, N'IBM864', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (99, 16, N'IBM865', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (100, 16, N'IBM869', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (101, 16, N'IBM870', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (102, 16, N'IBM01140', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (103, 16, N'IBM01141', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (104, 16, N'IBM01142', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (105, 16, N'IBM01143', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (106, 16, N'IBM01144', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (107, 16, N'IBM01145', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (108, 16, N'IBM01146', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (109, 16, N'IBM01147', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (110, 16, N'IBM01148', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (111, 16, N'IBM01149', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (112, 16, N'ISO-2022-JP', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (113, 16, N'ISO-2022-KR', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (114, 16, N'ISO-8859-1', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (115, 16, N'ISO-8859-2', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (116, 16, N'ISO-8859-3', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (117, 16, N'ISO-8859-4', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (118, 16, N'ISO-8859-5', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (119, 16, N'ISO-8859-6', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (120, 16, N'ISO-8859-7', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (121, 16, N'ISO-8859-8', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (122, 16, N'ISO-8859-9', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (123, 16, N'ISO-8859-13', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (124, 16, N'ISO-8859-15', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (125, 16, N'WINDOWS-874', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (126, 16, N'WINDOWS-1250', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (127, 16, N'WINDOWS-1251', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (128, 16, N'WINDOWS-1252', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (129, 16, N'WINDOWS-1253', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (130, 16, N'WINDOWS-1254', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (131, 16, N'WINDOWS-1255', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (132, 16, N'WINDOWS-1256', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (133, 16, N'WINDOWS-1257', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (134, 16, N'WINDOWS-1258', NULL, 1, 0, CAST(N'2020-02-05T02:37:32.5180480+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (135, 13, N'', NULL, 1, 0, CAST(N'2020-02-05T02:38:57.8968879+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (136, 13, N'bzip2', NULL, 1, 0, CAST(N'2020-02-05T02:38:57.8968879+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (137, 13, N'gzip', NULL, 1, 0, CAST(N'2020-02-05T02:38:57.8968879+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (138, 13, N'deflate', NULL, 1, 0, CAST(N'2020-02-05T02:38:57.8968879+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (139, 13, N'ZipDeflate', NULL, 1, 0, CAST(N'2020-02-05T02:38:57.8968879+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (140, 13, N'snappy', NULL, 1, 0, CAST(N'2020-02-05T02:38:57.8968879+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (141, 13, N'Iz4', NULL, 1, 0, CAST(N'2020-02-05T02:38:57.8968879+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (142, 23, N'DelimitedText', NULL, 1, 0, CAST(N'2020-02-05T02:39:53.4618736+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (143, 23, N'Parquet', NULL, 1, 0, CAST(N'2020-02-05T02:39:53.4618736+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (144, 23, N'Json', NULL, 1, 0, CAST(N'2020-02-05T02:39:53.4618736+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (147, 12, N'N', NULL, 1, 0, CAST(N'2020-02-05T02:40:28.9166092+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (148, 12, N'Y', NULL, 1, 0, CAST(N'2020-02-05T02:40:28.9166092+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (149, 8, N'Full', NULL, 1, 0, CAST(N'2020-02-05T02:40:57.8866519+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (150, 8, N'Incremental', NULL, 1, 0, CAST(N'2020-02-05T02:40:57.8866519+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (151, 19, N'', NULL, 1, 0, CAST(N'2020-02-06T01:13:57.6936981+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (152, 19, N'true', NULL, 1, 0, CAST(N'2020-02-06T01:15:01.6501494+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (153, 19, N'false', NULL, 1, 0, CAST(N'2020-02-06T01:15:01.6501494+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (156, 29, N'N', N'No', 1, 0, CAST(N'2020-02-11T08:21:24.6005778+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (157, 29, N'Y', N'Yes', 1, 0, CAST(N'2020-02-11T08:21:24.6005778+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (158, 33, N'$StageDatabaseName$', N'', 1, 0, CAST(N'2020-02-13T02:58:46.6296847+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (159, 33, N'$StageDatabaseName$_Synapse', N'', 1, 0, CAST(N'2020-02-13T02:58:46.6296847+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (162, 38, N'N', N'No', 1, 0, CAST(N'2020-02-27T00:21:48.2333328+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (163, 38, N'Y', N'Yes', 1, 0, CAST(N'2020-02-27T00:21:48.2333328+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (164, 40, N'FilePathName', NULL, 1, 0, CAST(N'2020-02-27T10:52:20.3248142+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (165, 40, N'LastModifiedDate', NULL, 1, 0, CAST(N'2020-02-27T10:52:20.3248142+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (166, 41, N'false', NULL, 1, 0, CAST(N'2020-03-05T02:39:01.3399069+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (167, 41, N'true', NULL, 1, 0, CAST(N'2020-03-05T02:39:01.3399069+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (168, 43, N'InsertUpdate', NULL, 1, 0, CAST(N'2020-03-24T12:09:35.1667838+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (169, 43, N'Insert', NULL, 1, 0, CAST(N'2020-03-24T12:09:35.1667838+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (170, 44, N'', N'Not applicable', 1, 0, CAST(N'2020-04-02T02:27:00.7092581+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (171, 44, N'dd-mm-yyyy', N'For ODBC Deafult', 1, 0, CAST(N'2020-04-02T02:28:00.2553369+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (172, 49, N'', NULL, 1, 0, CAST(N'2020-05-11T14:03:52.2119365+00:00' AS DateTimeOffset), NULL, NULL, NULL)
GO
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (173, 49, N'yyyy/MM/dd', NULL, 1, 0, CAST(N'2020-05-11T14:03:52.2119365+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (174, 49, N'yyyy/MM/dd/HH', NULL, 1, 0, CAST(N'2020-05-11T14:03:52.2119365+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (175, 49, N'yyyy/MM/dd/HH/mm', NULL, 1, 0, CAST(N'2020-05-11T14:03:52.2119365+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (176, 50, N'False', NULL, 1, 0, CAST(N'2020-06-24T01:16:23.6546345+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (177, 50, N'True', NULL, 1, 0, CAST(N'2020-06-24T01:16:23.6546345+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (178, 44, N'yyyy-MM-dd', N'For all other sources', 1, 0, CAST(N'2020-07-02T07:45:38.9662981+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (179, 51, N'False', NULL, 1, 0, CAST(N'2020-07-06T03:21:49.2237576+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (180, 51, N'True', NULL, 1, 0, CAST(N'2020-07-06T03:21:49.2237576+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (182, 44, N'Number', N'For numeric sources', 1, 0, CAST(N'2020-07-13T08:17:51.2119127+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (183, 44, N'#dd-mm-yyyy#', N'For ODBC Access', 1, 0, CAST(N'2020-07-13T08:17:51.2119127+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (184, 52, N'False', NULL, 1, 0, CAST(N'2020-07-16T08:52:38.4010000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (185, 52, N'True', NULL, 1, 0, CAST(N'2020-07-16T08:52:38.4010000+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeOption] ([TaskPropertyTypeOptionID], [TaskPropertyTypeID], [TaskPropertyTypeOptionName], [TaskPropertyTypeOptionDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (186, 23, N'XML', NULL, 1, 0, CAST(N'2020-02-05T02:39:53.4618736+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[TaskPropertyTypeOption] OFF
SET IDENTITY_INSERT [DI].[TaskPropertyTypeValidation] ON 

INSERT [DI].[TaskPropertyTypeValidation] ([TaskPropertyTypeValidationID], [TaskPropertyTypeValidationName], [TaskPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, N'TextBox', N'This is the validation type for the TextBox form control', 1, 0, CAST(N'2020-02-05T01:28:57.3513986+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeValidation] ([TaskPropertyTypeValidationID], [TaskPropertyTypeValidationName], [TaskPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, N'DropDownList', N'This is the validation type for the DropDownList form control', 1, 0, CAST(N'2020-02-05T01:28:57.3513986+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeValidation] ([TaskPropertyTypeValidationID], [TaskPropertyTypeValidationName], [TaskPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, N'NumberBox', N'This is the validation type for the NumberBox form control', 1, 0, CAST(N'2020-02-05T01:28:57.3513986+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskPropertyTypeValidation] ([TaskPropertyTypeValidationID], [TaskPropertyTypeValidationName], [TaskPropertyTypeValidationDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, N'MultiLineTextBox', N'This is the validation type for the MultiLineTextBox form control', 1, 0, CAST(N'2020-03-23T04:30:50.5359247+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[TaskPropertyTypeValidation] OFF
SET IDENTITY_INSERT [DI].[TaskResult] ON 

INSERT [DI].[TaskResult] ([TaskResultID], [TaskResultName], [TaskResultDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [RetryIndicator]) VALUES (1, N'Success', N'This is to indicate successful completion of the task', 0, CAST(N'2019-02-05T03:21:48.3700000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0)
INSERT [DI].[TaskResult] ([TaskResultID], [TaskResultName], [TaskResultDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [RetryIndicator]) VALUES (2, N'Failure - Retry', N'This is to indicate that the task has failed and should be retried', 0, CAST(N'2019-02-05T03:21:48.3700000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
INSERT [DI].[TaskResult] ([TaskResultID], [TaskResultName], [TaskResultDescription], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [RetryIndicator]) VALUES (3, N'Untried', N'This is to indicate that the task has not yet been executed', 0, CAST(N'2019-02-05T04:51:03.7100000+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1)
SET IDENTITY_INSERT [DI].[TaskResult] OFF
SET IDENTITY_INSERT [DI].[TaskType] ON 

INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (1, N'Azure SQL to SQL', N'This is the task type for any Azure SQL data source to SQL target', 1, 0, CAST(N'2019-02-05T07:41:19.3266667+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 1, N'Database to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (2, N'Oracle to SQL', N'This is the task type for any Oracle data source to SQL target', 1, 0, CAST(N'2019-02-07T03:45:25.6266667+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 1, N'Database to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (3, N'On Prem SQL to SQL', N'This is the task type for any On prem SQL data source to SQL target', 1, 0, CAST(N'2019-11-12T08:05:09.7685260+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 1, N'Database to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (4, N'Azure Data Lake File to Lake', N'This is the task type for any file stored in Azure Data Lake which need to be moved to the data lake', 1, 0, CAST(N'2019-12-19T03:44:38.9105405+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'File to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (5, N'Azure Blob File to Lake', N'This is the task type for any file stored in Azure Blob Storage which need to be moved to the data lake', 1, 0, CAST(N'2020-01-07T06:42:55.6560311+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'File to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (6, N'File System File to Lake', N'This is the task type for any file stored in a Local File System Storage which need to be moved to the data lake', 1, 0, CAST(N'2020-01-08T03:23:27.3294814+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'File to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (8, N'Azure SQL to Synapse', N'This is the task type for any Azure SQL data source to Azure Synapse target', 1, 0, CAST(N'2020-01-14T07:42:46.5723481+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 1, N'Database to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (9, N'Azure Data Lake File to SQL', N'This is the task type for any file stored in Azure Data Lake which needs to be moved to SQL target', 1, 0, CAST(N'2020-01-21T02:02:25.7115218+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'File to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (10, N'Azure Blob File to SQL', N'This is the task type for any file stored in Azure Blob which needs to be moved to SQL target', 1, 0, CAST(N'2020-01-21T02:02:25.7115218+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'File to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (11, N'File System File to SQL', N'This is the task type for any file stored in a File System which needs to be moved to SQL target', 1, 0, CAST(N'2020-01-21T02:02:25.7115218+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'File to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (12, N'Databricks notebook', N'This is the task type for any databricks notebook run', 1, 0, CAST(N'2020-01-28T08:49:59.7275558+00:00' AS DateTimeOffset), NULL, NULL, NULL, 1, 0, 0, N'Script')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (13, N'SQL Stored Procedure', N'This is the task type for any Azure SQL stored procedure run', 1, 0, CAST(N'2020-01-28T08:49:59.7275558+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'Script')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (15, N'Oracle to Synapse', N'This is the task type for any Oracle data source to Azure Synapse target', 1, 0, CAST(N'2020-02-03T03:14:55.0898455+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'Database to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (16, N'On Prem SQL to Synapse', N'This is the task type for any On prem SQL data source to Azure Synapse target', 1, 0, CAST(N'2020-02-03T03:15:21.3097535+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'Database to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (17, N'Azure SQL to Lake', N'This is the task type for any Azure SQL data source to data lake target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'Database to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (18, N'Oracle to Lake', N'This is the task type for any Oracle data source to data lake target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'Database to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (19, N'On Prem SQL to Lake', N'This is the task type for any On prem SQL data source to data lake target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'Database to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (20, N'CRM to Lake', N'This is the task type for any CRM data source to data lake target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'CRM to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (21, N'CRM to SQL', N'This is the task type for any CRM data source to SQL database target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'CRM to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (22, N'CRM to Synapse', N'This is the task type for any CRM data source to Azure Synapse target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'CRM to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (23, N'Azure Data Lake File to Synapse', N'This is the task type for any file stored in Azure Data Lake which needs to be moved to Synapse target', 1, 0, CAST(N'2020-02-27T00:14:06.4353257+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'File to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (24, N'Azure Blob File to Synapse', N'This is the task type for any file stored in Azure Blob which needs to be moved to Synapse target', 1, 0, CAST(N'2020-02-27T00:14:06.4353257+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'File to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (25, N'File System File to Synapse', N'This is the task type for any file stored in a File System which needs to be moved to Synapse target', 1, 0, CAST(N'2020-02-27T00:14:06.4353257+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 0, 0, N'File to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (26, N'ODBC to Lake', N'This is the task type for any ODBC data source to data lake target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'ODBC to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (27, N'ODBC to SQL', N'This is the task type for any ODBC data source to SQL target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'ODBC to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (28, N'ODBC to Synapse', N'This is the task type for any ODBC data source to Snapse target', 1, 0, CAST(N'2020-02-10T03:14:06.2010722+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'ODBC to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (29, N'REST API to Lake', N'This is the task type for any REST API data source to Data Lake target', 1, 0, CAST(N'2020-04-23T03:27:42.8993732+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'REST to Lake')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (31, N'REST API to SQL', N'This is the task type for any REST API data source to Azure SQL target', 1, 0, CAST(N'2020-04-23T03:27:42.8993732+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'REST to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (32, N'REST API to Synapse', N'This is the task type for any REST API data source to AZure Synapse target', 1, 0, CAST(N'2020-04-23T03:27:42.8993732+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'REST to Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (33, N'ADS Stage to DW Stage', N'This is the task type for copying data from the ADS Staging database to the tempstage schema in a data warehouse', 1, 0, CAST(N'2020-08-12T03:21:09.6837631+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'Database to DW Stage')
INSERT [DI].[TaskType] ([TaskTypeID], [TaskTypeName], [TaskTypeDescription], [EnabledIndicator], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy], [ScriptIndicator], [FileLoadIndicator], [DatabaseLoadIndicator], [RunType]) VALUES (35, N'ADS Stage to DW Stage Synapse', N'This is the task type for copying data from the ADS Staging database to the tempstage schema in a Synapse data warehouse', 1, 0, CAST(N'2020-08-20T10:49:44.4451865+00:00' AS DateTimeOffset), NULL, NULL, NULL, 0, 1, 0, N'Database to DW Stage Synapse')
SET IDENTITY_INSERT [DI].[TaskType] OFF
SET IDENTITY_INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ON 

INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (1, 1, 1, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (2, 1, 2, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (3, 1, 3, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (4, 1, 4, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (5, 1, 7, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (6, 1, 8, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (7, 1, 9, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (8, 1, 10, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (9, 1, 11, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (10, 1, 12, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (11, 3, 1, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (12, 3, 2, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (13, 3, 3, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (14, 3, 4, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (15, 3, 7, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (16, 3, 8, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (17, 3, 9, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (18, 3, 10, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (19, 3, 11, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (20, 3, 12, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (21, 2, 1, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (22, 2, 2, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (23, 2, 3, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (24, 2, 4, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (25, 2, 7, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (26, 2, 8, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (27, 2, 9, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (28, 2, 10, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (29, 2, 11, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (30, 2, 12, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (31, 4, 6, 0, CAST(N'2019-12-19T03:46:03.9757114+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (32, 4, 5, 0, CAST(N'2019-12-19T03:46:03.9757114+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (33, 4, 13, 0, CAST(N'2019-12-20T03:16:21.4873744+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (34, 4, 14, 0, CAST(N'2019-12-20T03:16:21.4873744+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (36, 4, 16, 0, CAST(N'2019-12-20T03:16:21.4873744+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (37, 4, 17, 0, CAST(N'2019-12-20T03:16:21.4873744+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (38, 4, 18, 0, CAST(N'2019-12-20T03:16:21.4873744+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (39, 4, 19, 0, CAST(N'2019-12-20T03:16:21.4873744+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (40, 4, 20, 0, CAST(N'2019-12-20T03:16:21.4873744+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (41, 4, 21, 0, CAST(N'2019-12-20T03:16:21.4873744+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (45, 5, 6, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (46, 5, 5, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (47, 5, 13, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (48, 5, 14, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (49, 5, 16, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (50, 5, 17, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (51, 5, 18, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (52, 5, 19, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (53, 5, 20, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (54, 5, 21, 0, CAST(N'2020-01-16T03:00:25.3338202+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (55, 6, 6, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (56, 6, 5, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (57, 6, 13, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (58, 6, 14, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (59, 6, 16, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (60, 6, 17, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (61, 6, 18, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (62, 6, 19, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (63, 6, 20, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (64, 6, 21, 0, CAST(N'2020-01-16T03:00:32.4903599+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (65, 4, 7, 0, CAST(N'2020-01-21T04:24:12.5274068+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (66, 5, 7, 0, CAST(N'2020-01-21T04:24:12.5274068+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (67, 6, 7, 0, CAST(N'2020-01-21T04:24:12.5274068+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (70, 11, 7, 0, CAST(N'2020-01-21T04:24:12.5274068+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (71, 4, 3, 0, CAST(N'2020-01-21T04:24:32.9659427+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (72, 5, 3, 0, CAST(N'2020-01-21T04:24:32.9659427+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (73, 6, 3, 0, CAST(N'2020-01-21T04:24:32.9659427+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (76, 11, 3, 0, CAST(N'2020-01-21T04:24:32.9659427+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (77, 4, 23, 0, CAST(N'2020-01-21T04:24:52.5612441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (78, 5, 23, 0, CAST(N'2020-01-21T04:24:52.5612441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (79, 6, 23, 0, CAST(N'2020-01-21T04:24:52.5612441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (82, 11, 23, 0, CAST(N'2020-01-21T04:24:52.5612441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (83, 4, 4, 0, CAST(N'2020-01-21T04:26:49.0500519+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (84, 5, 4, 0, CAST(N'2020-01-21T04:26:49.0500519+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (85, 6, 4, 0, CAST(N'2020-01-21T04:26:49.0500519+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (90, 6, 22, 0, CAST(N'2020-01-21T04:28:20.0395905+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (91, 11, 22, 0, CAST(N'2020-01-21T04:28:20.0395905+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (92, 8, 1, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (93, 8, 2, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (94, 8, 3, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (95, 8, 4, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (96, 8, 7, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (97, 8, 8, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (98, 8, 9, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (99, 8, 10, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (100, 8, 11, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (101, 8, 12, 0, CAST(N'2020-01-22T07:35:24.2539304+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (102, 11, 4, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (103, 11, 5, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (104, 11, 6, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (105, 11, 13, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (106, 11, 14, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (107, 11, 16, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (108, 11, 17, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (109, 11, 18, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (110, 11, 19, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (111, 11, 20, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (112, 11, 21, 0, CAST(N'2020-01-29T03:45:11.0679663+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (113, 5, 27, 0, CAST(N'2020-01-30T23:57:28.2461381+00:00' AS DateTimeOffset), NULL, NULL, NULL)
GO
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (115, 4, 27, 0, CAST(N'2020-01-30T23:57:28.2461381+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (117, 6, 27, 0, CAST(N'2020-01-30T23:57:28.2461381+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (118, 11, 27, 0, CAST(N'2020-01-30T23:57:28.2461381+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (119, 12, 26, 0, CAST(N'2020-01-31T08:05:19.0944531+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (120, 13, 25, 0, CAST(N'2020-01-31T08:05:19.0944531+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (121, 13, 25, 0, CAST(N'2020-01-31T08:05:19.0944531+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (122, 1, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (123, 2, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (124, 3, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (125, 4, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (126, 5, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (127, 6, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (128, 8, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (131, 11, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (132, 15, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (133, 16, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (134, 17, 1, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (135, 17, 2, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (136, 17, 3, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (137, 17, 4, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (138, 17, 7, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (139, 17, 8, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (140, 17, 9, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (142, 17, 11, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (143, 17, 12, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (144, 17, 29, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (145, 18, 1, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (146, 18, 2, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (147, 18, 3, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (148, 18, 4, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (149, 18, 7, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (150, 18, 8, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (151, 18, 9, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (153, 18, 11, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (154, 18, 12, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (155, 18, 29, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (156, 19, 1, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (157, 19, 2, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (158, 19, 3, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (159, 19, 4, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (160, 19, 7, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (161, 19, 8, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (162, 19, 9, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (164, 19, 11, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (165, 19, 12, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (166, 19, 29, 0, CAST(N'2020-02-10T03:18:02.5412044+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (167, 5, 32, 0, CAST(N'2020-02-11T04:44:28.7619944+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (169, 4, 32, 0, CAST(N'2020-02-11T04:44:28.7619944+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (171, 6, 32, 0, CAST(N'2020-02-11T04:44:28.7619944+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (172, 11, 32, 0, CAST(N'2020-02-11T04:44:28.7619944+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (175, 1, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (176, 8, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (177, 11, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (178, 3, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (179, 16, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (180, 2, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (181, 15, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (194, 21, 34, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (196, 21, 3, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (197, 21, 4, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (198, 21, 7, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (199, 21, 8, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (204, 21, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (205, 21, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (206, 20, 34, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (208, 20, 3, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (210, 20, 7, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (211, 20, 8, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (216, 20, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (218, 20, 9, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (219, 21, 9, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (220, 22, 34, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (221, 22, 3, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (222, 22, 4, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (223, 22, 7, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (224, 22, 8, 0, CAST(N'2019-12-19T03:43:46.1276547+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (225, 22, 29, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (226, 22, 33, 0, CAST(N'2020-02-13T02:56:51.1907334+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (227, 22, 9, 0, CAST(N'2020-02-06T06:17:44.1224356+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (236, 25, 7, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (239, 25, 3, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (242, 25, 23, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (243, 25, 22, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (244, 25, 4, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (245, 25, 5, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (246, 25, 6, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (247, 25, 13, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (248, 25, 14, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (249, 25, 16, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (250, 25, 17, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (251, 25, 18, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (252, 25, 19, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (253, 25, 20, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (254, 25, 21, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (257, 25, 27, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (260, 25, 29, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (263, 25, 32, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (266, 25, 33, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (272, 1, 38, 0, CAST(N'2020-02-27T00:20:30.4675598+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (273, 11, 38, 0, CAST(N'2020-02-27T00:20:30.4675598+00:00' AS DateTimeOffset), NULL, NULL, NULL)
GO
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (274, 3, 38, 0, CAST(N'2020-02-27T00:20:30.4675598+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (275, 2, 38, 0, CAST(N'2020-02-27T00:20:30.4675598+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (276, 4, 40, 0, CAST(N'2020-02-27T10:57:48.6227354+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (277, 5, 40, 0, CAST(N'2020-02-27T10:57:48.6227354+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (278, 6, 40, 0, CAST(N'2020-02-27T10:57:48.6227354+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (281, 11, 40, 0, CAST(N'2020-02-27T10:57:48.6227354+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (284, 25, 40, 0, CAST(N'2020-02-27T10:57:48.6227354+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (285, 4, 41, 0, CAST(N'2020-03-05T02:41:54.1391811+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (286, 5, 41, 0, CAST(N'2020-03-05T02:41:54.1391811+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (287, 6, 41, 0, CAST(N'2020-03-05T02:41:54.1391811+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (290, 11, 41, 0, CAST(N'2020-03-05T02:41:54.1391811+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (291, 9, 7, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (292, 9, 3, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (293, 9, 23, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (294, 9, 22, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (295, 9, 4, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (296, 9, 5, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (297, 9, 6, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (298, 9, 13, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (299, 9, 14, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (300, 9, 16, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (301, 9, 17, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (302, 9, 18, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (303, 9, 19, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (304, 9, 20, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (305, 9, 21, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (306, 9, 27, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (307, 9, 29, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (308, 9, 32, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (309, 9, 33, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (311, 9, 40, 0, CAST(N'2020-03-07T06:48:32.7712293+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (312, 10, 7, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (313, 10, 3, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (314, 10, 23, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (315, 10, 22, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (316, 10, 4, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (317, 10, 5, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (318, 10, 6, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (319, 10, 13, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (320, 10, 14, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (321, 10, 16, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (322, 10, 17, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (323, 10, 18, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (324, 10, 19, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (325, 10, 20, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (326, 10, 21, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (327, 10, 27, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (328, 10, 29, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (329, 10, 32, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (330, 10, 33, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (332, 10, 40, 0, CAST(N'2020-03-07T06:48:37.7088018+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (333, 23, 7, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (334, 23, 3, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (335, 23, 23, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (336, 23, 22, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (337, 23, 4, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (338, 23, 5, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (339, 23, 6, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (340, 23, 13, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (341, 23, 14, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (342, 23, 16, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (343, 23, 17, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (344, 23, 18, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (345, 23, 19, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (346, 23, 20, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (347, 23, 21, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (348, 23, 27, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (349, 23, 29, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (350, 23, 32, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (351, 23, 33, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (353, 23, 40, 0, CAST(N'2020-03-07T06:48:42.8026277+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (354, 24, 7, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (355, 24, 3, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (356, 24, 23, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (357, 24, 22, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (358, 24, 4, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (359, 24, 5, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (360, 24, 6, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (361, 24, 13, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (362, 24, 14, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (363, 24, 16, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (364, 24, 17, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (365, 24, 18, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (366, 24, 19, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (367, 24, 20, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (368, 24, 21, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (369, 24, 27, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (370, 24, 29, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (371, 24, 32, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (372, 24, 33, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (374, 24, 40, 0, CAST(N'2020-03-07T06:48:46.7401712+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (375, 5, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (376, 10, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (377, 24, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (378, 4, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (379, 9, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (380, 23, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (381, 6, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (382, 11, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (383, 25, 41, 0, CAST(N'2020-03-10T08:29:44.0914343+00:00' AS DateTimeOffset), NULL, NULL, NULL)
GO
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (384, 21, 38, 0, CAST(N'2020-03-12T05:02:25.3705725+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (385, 22, 38, 0, CAST(N'2020-03-12T05:02:25.3705725+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (386, 21, 32, 0, CAST(N'2020-03-12T05:02:25.3705725+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (387, 22, 32, 0, CAST(N'2020-03-12T05:02:25.3705725+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (388, 20, 4, 0, CAST(N'2020-03-13T10:05:45.9145166+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (389, 20, 32, 0, CAST(N'2020-03-13T10:05:45.9145166+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (390, 4, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (391, 5, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (392, 6, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (393, 9, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (394, 10, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (395, 11, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (396, 23, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (397, 24, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (398, 25, 8, 0, CAST(N'2020-03-18T08:25:10.3729864+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (399, 20, 42, 0, CAST(N'2020-03-24T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (400, 21, 42, 0, CAST(N'2020-03-24T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (401, 22, 42, 0, CAST(N'2020-03-24T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (402, 4, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (403, 5, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (404, 6, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (405, 9, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (406, 10, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (407, 11, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (408, 23, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (409, 24, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (410, 25, 43, 0, CAST(N'2020-03-24T12:12:16.6675931+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (411, 26, 1, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (412, 26, 2, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (413, 26, 3, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (414, 26, 4, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (415, 26, 7, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (416, 26, 8, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (417, 26, 9, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (419, 26, 11, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (420, 26, 12, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (421, 26, 29, 0, CAST(N'2020-03-27T02:54:05.3866667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (422, 27, 1, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (423, 27, 2, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (424, 27, 3, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (425, 27, 4, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (426, 27, 7, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (427, 27, 8, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (428, 27, 9, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (430, 27, 11, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (431, 27, 12, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (432, 27, 29, 0, CAST(N'2020-03-27T02:54:56.7666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (433, 28, 1, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (434, 28, 2, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (435, 28, 3, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (436, 28, 4, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (437, 28, 7, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (438, 28, 8, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (439, 28, 9, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (441, 28, 11, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (442, 28, 12, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (443, 28, 29, 0, CAST(N'2020-03-27T02:55:02.4666667+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (444, 26, 44, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (445, 27, 44, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (446, 28, 44, 0, CAST(N'2020-02-27T00:15:02.9197330+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (447, 26, 10, 0, CAST(N'2020-04-08T05:43:00.8814478+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (448, 27, 10, 0, CAST(N'2020-04-08T05:43:00.8814478+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (449, 28, 10, 0, CAST(N'2020-04-08T05:43:00.8814478+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (450, 29, 3, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (451, 29, 4, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (452, 29, 7, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (453, 29, 8, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (454, 29, 29, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (455, 29, 27, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (456, 29, 32, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (457, 29, 46, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (458, 31, 3, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (459, 31, 4, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (460, 31, 7, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (461, 31, 8, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (462, 31, 29, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (463, 31, 27, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (464, 31, 32, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (465, 31, 33, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (466, 31, 46, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (467, 32, 3, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (468, 32, 4, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (469, 32, 7, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (470, 32, 8, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (471, 32, 29, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (472, 32, 27, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (473, 32, 32, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (474, 32, 33, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (475, 32, 46, 0, CAST(N'2020-04-23T03:44:15.5271130+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (476, 29, 48, 0, CAST(N'2020-05-04T14:11:57.8421423+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (477, 31, 48, 0, CAST(N'2020-05-04T14:11:57.8421423+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (478, 32, 48, 0, CAST(N'2020-05-04T14:11:57.8421423+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (480, 28, 10, 0, CAST(N'2020-04-08T05:43:00.8814478+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (481, 28, 33, 0, CAST(N'2020-05-07T04:54:01.7716554+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (482, 26, 32, 0, CAST(N'2020-05-07T08:55:23.0318365+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (483, 27, 32, 0, CAST(N'2020-05-07T08:55:23.0318365+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (484, 28, 32, 0, CAST(N'2020-05-07T08:55:23.0318365+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (485, 5, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (486, 10, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (487, 24, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
GO
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (488, 4, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (489, 9, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (490, 23, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (491, 17, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (492, 1, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (493, 8, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (494, 20, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (495, 21, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (496, 22, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (498, 6, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (499, 11, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (500, 25, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (501, 26, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (502, 27, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (503, 28, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (504, 19, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (505, 3, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (506, 16, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (507, 18, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (508, 2, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (509, 15, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (510, 29, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (511, 31, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (512, 32, 49, 0, CAST(N'2020-05-11T13:58:50.7108772+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (514, 27, 38, 0, CAST(N'2020-05-14T12:23:45.2545840+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (515, 28, 38, 0, CAST(N'2020-05-14T12:23:45.2545840+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (516, 5, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (517, 10, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (518, 24, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (519, 4, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (520, 9, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (521, 23, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (522, 17, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (523, 1, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (524, 8, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (525, 20, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (526, 21, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (527, 22, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (528, 12, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (529, 6, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (530, 11, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (531, 25, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (532, 26, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (533, 27, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (534, 28, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (535, 19, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (536, 3, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (537, 16, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (538, 18, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (539, 2, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (540, 15, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (541, 29, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (542, 31, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (543, 32, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (544, 13, 50, 0, CAST(N'2020-06-24T01:33:51.5821294+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (545, 17, 51, 0, CAST(N'2020-07-06T03:21:49.2237576+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (546, 1, 51, 0, CAST(N'2020-07-06T03:21:49.2237576+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (547, 8, 51, 0, CAST(N'2020-07-06T03:21:49.2237576+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (548, 19, 51, 0, CAST(N'2020-07-06T03:21:49.2237576+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (549, 3, 51, 0, CAST(N'2020-07-06T03:21:49.2237576+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (550, 16, 51, 0, CAST(N'2020-07-06T03:21:49.2237576+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (551, 5, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (552, 10, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (553, 24, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (554, 4, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (555, 9, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (556, 23, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (557, 17, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (558, 1, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (559, 8, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (560, 20, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (561, 21, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (562, 22, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (563, 12, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (564, 6, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (565, 11, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (566, 25, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (567, 26, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (568, 27, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (569, 28, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (570, 19, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (571, 3, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (572, 16, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (573, 18, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (574, 2, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (575, 15, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (576, 29, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (577, 31, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (578, 32, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (579, 13, 52, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (580, 5, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (581, 10, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (582, 24, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (583, 4, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (584, 9, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (585, 23, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (586, 17, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (587, 1, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (588, 8, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (589, 20, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
GO
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (590, 21, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (591, 22, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (592, 12, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (593, 6, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (594, 11, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (595, 25, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (596, 26, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (597, 27, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (598, 28, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (599, 19, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (600, 3, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (601, 16, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (602, 18, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (603, 2, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (604, 15, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (605, 29, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (606, 31, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (607, 32, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (608, 13, 53, 0, CAST(N'2020-07-16T08:52:38.4166266+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (609, 17, 10, 0, CAST(N'2020-07-31T06:29:03.8630830+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (610, 18, 10, 0, CAST(N'2020-07-31T06:31:17.6395670+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (611, 19, 10, 0, CAST(N'2020-07-31T06:31:17.6395670+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (612, 20, 10, 0, CAST(N'2020-07-31T06:31:17.6395670+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (613, 21, 10, 0, CAST(N'2020-07-31T06:31:17.6395670+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (614, 22, 10, 0, CAST(N'2020-07-31T06:31:17.6395670+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (615, 1, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (616, 2, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (617, 3, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (618, 8, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (619, 17, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (620, 18, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (621, 19, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (622, 20, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (623, 21, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (624, 22, 44, 0, CAST(N'2020-08-03T04:25:52.4612693+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (625, 1, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (626, 2, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (627, 3, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (628, 4, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (629, 5, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (630, 6, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (631, 8, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (632, 9, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (633, 10, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (634, 11, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (635, 15, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (636, 16, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (637, 17, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (638, 18, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (639, 19, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (640, 20, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (641, 21, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (642, 22, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (643, 23, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (644, 24, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (645, 25, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (646, 26, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (647, 27, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (648, 28, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (649, 29, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (650, 31, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (651, 32, 55, 0, CAST(N'2020-08-12T04:20:53.5033907+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (685, 33, 1, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (686, 33, 2, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (687, 33, 3, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (688, 33, 4, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (689, 33, 7, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (690, 33, 8, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (691, 33, 9, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (692, 33, 10, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (693, 33, 11, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (694, 33, 29, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (695, 33, 49, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (696, 33, 52, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (697, 33, 53, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (698, 33, 44, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (699, 33, 55, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (700, 33, 33, 0, CAST(N'2020-08-20T14:34:57.5414192+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (701, 35, 1, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (702, 35, 2, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (703, 35, 3, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (704, 35, 4, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (705, 35, 7, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (706, 35, 8, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (707, 35, 9, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (708, 35, 10, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (709, 35, 11, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (710, 35, 29, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (711, 35, 49, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (712, 35, 52, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (713, 35, 53, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (714, 35, 44, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (715, 35, 55, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (716, 35, 33, 0, CAST(N'2020-08-20T14:34:57.5570475+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (717, 17, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (718, 1, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (719, 8, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (720, 19, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (721, 3, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (722, 16, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
GO
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (723, 18, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (724, 2, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
INSERT [DI].[TaskTypeTaskPropertyTypeMapping] ([TaskTypeTaskPropertyTypeMappingID], [TaskTypeID], [TaskPropertyTypeID], [DeletedIndicator], [DateCreated], [CreatedBy], [DateModified], [ModifiedBy]) VALUES (725, 15, 32, 0, CAST(N'2020-08-27T01:35:36.1168441+00:00' AS DateTimeOffset), NULL, NULL, NULL)
SET IDENTITY_INSERT [DI].[TaskTypeTaskPropertyTypeMapping] OFF
ALTER TABLE [DI].[AuthenticationType] ADD  CONSTRAINT [DF_DI_AuthenticationType_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[AuthenticationType] ADD  CONSTRAINT [DF_DI_AuthenticationType_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[AuthenticationType] ADD  CONSTRAINT [DF_DI_AuthenticationType_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[CDCLoadLog] ADD  CONSTRAINT [DF_DI_CDCLoadLog_SuccessIndicator]  DEFAULT ((0)) FOR [SuccessIndicator]
GO
ALTER TABLE [DI].[CDCLoadLog] ADD  CONSTRAINT [DF_DI_CDCLoadLog_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[CDCLoadLog] ADD  CONSTRAINT [DF_DI_CDCLoadLog_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[Connection] ADD  CONSTRAINT [DF_DI_Connection_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[Connection] ADD  CONSTRAINT [DF_DI_Connection_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[Connection] ADD  CONSTRAINT [DF_DI_Connection_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ConnectionProperty] ADD  CONSTRAINT [DF_DI_ConnectionProperty_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ConnectionProperty] ADD  CONSTRAINT [DF_DI_ConnectionProperty_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ConnectionPropertyType] ADD  CONSTRAINT [DF_DI_ConnectionPropertyType_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ConnectionPropertyType] ADD  CONSTRAINT [DF_DI_ConnectionPropertyType_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ConnectionPropertyTypeOption] ADD  CONSTRAINT [DF_DI_ConnectionPropertyTypeOption_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[ConnectionPropertyTypeOption] ADD  CONSTRAINT [DF_DI_ConnectionPropertyTypeOption_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ConnectionPropertyTypeOption] ADD  CONSTRAINT [DF_DI_ConnectionPropertyTypeOption_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ConnectionPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_ConnectionPropertyTypeValidation_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[ConnectionPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_ConnectionPropertyTypeValidation_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ConnectionPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_ConnectionPropertyTypeValidation_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ConnectionType] ADD  CONSTRAINT [DF_DI_ConnectionType_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[ConnectionType] ADD  CONSTRAINT [DF_DI_ConnectionType_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ConnectionType] ADD  CONSTRAINT [DF_DI_ConnectionType_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ConnectionType] ADD  CONSTRAINT [DF_ConnectionType_DatabaseConnectionIndicator]  DEFAULT ((0)) FOR [DatabaseConnectionIndicator]
GO
ALTER TABLE [DI].[ConnectionType] ADD  CONSTRAINT [DF_ConnectionType_FileConnectionIndicator]  DEFAULT ((0)) FOR [FileConnectionIndicator]
GO
ALTER TABLE [DI].[ConnectionType] ADD  CONSTRAINT [DF_ConnectionType_CRMConnectionIndicator]  DEFAULT ((0)) FOR [CRMConnectionIndicator]
GO
ALTER TABLE [DI].[ConnectionType] ADD  CONSTRAINT [DF_ConnectionType_ODBCConnectionIndicator]  DEFAULT ((0)) FOR [ODBCConnectionIndicator]
GO
ALTER TABLE [DI].[ConnectionTypeAuthenticationTypeMapping] ADD  CONSTRAINT [DF_DI_ConnectionTypeAuthenticationTypeMapping_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ConnectionTypeAuthenticationTypeMapping] ADD  CONSTRAINT [DF_DI_ConnectionTypeAuthenticationTypeMapping_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ConnectionTypeConnectionPropertyTypeMapping] ADD  CONSTRAINT [DF_DI_ConnectionTypeConnectionPropertyTypeMapping_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ConnectionTypeConnectionPropertyTypeMapping] ADD  CONSTRAINT [DF_DI_ConnectionTypeConnectionPropertyTypeMapping_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[DataFactoryLog] ADD  CONSTRAINT [DF_DataFactoryLog_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[DataFactoryLog] ADD  CONSTRAINT [DF_DataFactoryLog_EmailSentIndicator]  DEFAULT ((0)) FOR [EmailSentIndicator]
GO
ALTER TABLE [DI].[FileColumnMapping] ADD  CONSTRAINT [DF_DI_FileColumnMapping_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[FileColumnMapping] ADD  CONSTRAINT [DF_DI_FileColumnMapping_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[FileColumnMapping] ADD  CONSTRAINT [DF_DI_FileColumnMapping_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[FileInterimDataType] ADD  CONSTRAINT [DF_DI_FileInterimDataType_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[FileInterimDataType] ADD  CONSTRAINT [DF_DI_FileInterimDataType_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[FileInterimDataType] ADD  CONSTRAINT [DF_DI_FileInterimDataType_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[FileLoadLog] ADD  CONSTRAINT [DF_DI_FileLoadLog_SuccessIndicator]  DEFAULT ((0)) FOR [SuccessIndicator]
GO
ALTER TABLE [DI].[FileLoadLog] ADD  CONSTRAINT [DF_DI_FileLoadLog_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[FileLoadLog] ADD  CONSTRAINT [DF_DI_FileLoadLog_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[GenericConfig] ADD  CONSTRAINT [DF_DI_GenericConfig_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[Schedule] ADD  CONSTRAINT [DF_DI_Schedule_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[Schedule] ADD  CONSTRAINT [DF_DI_Schedule_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[Schedule] ADD  CONSTRAINT [DF_DI_Schedule_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ScheduleInstance] ADD  CONSTRAINT [DF_DI_ScheduleInstance]  DEFAULT (sysutcdatetime()) FOR [RunDate]
GO
ALTER TABLE [DI].[ScheduleInstance] ADD  CONSTRAINT [DF_DI_ScheduleInstance_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[ScheduleInstance] ADD  CONSTRAINT [DF_DI_ScheduleInstance_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ScheduleInstance] ADD  CONSTRAINT [DF_DI_ScheduleInstance_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[ScheduleInterval] ADD  CONSTRAINT [DF_DI_ScheduleInterval_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[ScheduleInterval] ADD  CONSTRAINT [DF_DI_ScheduleInterval_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[ScheduleInterval] ADD  CONSTRAINT [DF_DI_ScheduleInterval_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[System] ADD  CONSTRAINT [DF_DI_System_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[System] ADD  CONSTRAINT [DF_DI_System_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[System] ADD  CONSTRAINT [DF_DI_System_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[SystemDependency] ADD  CONSTRAINT [DF_DI_SystemDependency_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[SystemDependency] ADD  CONSTRAINT [DF_DI_SystemDependency_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[SystemDependency] ADD  CONSTRAINT [DF_DI_SystemDependency_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[SystemProperty] ADD  CONSTRAINT [DF_DI_SystemProperty_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[SystemProperty] ADD  CONSTRAINT [DF_DI_SystemProperty_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[SystemPropertyType] ADD  CONSTRAINT [DF_DI_SystemPropertyType_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[SystemPropertyType] ADD  CONSTRAINT [DF_DI_SystemPropertyType_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[SystemPropertyTypeOption] ADD  CONSTRAINT [DF_DI_SystemPropertyTypeOption_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[SystemPropertyTypeOption] ADD  CONSTRAINT [DF_DI_SystemPropertyTypeOption_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[SystemPropertyTypeOption] ADD  CONSTRAINT [DF_DI_SystemPropertyTypeOption_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[SystemPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_SystemPropertyTypeValidation_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[SystemPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_SystemPropertyTypeValidation_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[SystemPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_SystemPropertyTypeValidation_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[Task] ADD  CONSTRAINT [DF_DI_Task_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[Task] ADD  CONSTRAINT [DF_DI_Task_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[Task] ADD  CONSTRAINT [DF_DI_Task_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[Task] ADD  DEFAULT (NULL) FOR [TaskOrderID]
GO
ALTER TABLE [DI].[TaskInstance] ADD  CONSTRAINT [DF_DI_TaskInstance_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[TaskProperty] ADD  CONSTRAINT [DF_DI_TaskProperty_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[TaskProperty] ADD  CONSTRAINT [DF_DI_TaskProperty_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[TaskPropertyPassthroughMapping] ADD  CONSTRAINT [DF_DI_TaskPropertyPassthroughMapping_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[TaskPropertyPassthroughMapping] ADD  CONSTRAINT [DF_DI_TaskPropertyPassthroughMapping_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[TaskPropertyPassthroughMapping] ADD  CONSTRAINT [DF_DI_TaskPropertyPassthroughMapping_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[TaskPropertyType] ADD  CONSTRAINT [DF_DI_TaskPropertyType_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[TaskPropertyType] ADD  CONSTRAINT [DF_DI_TaskPropertyType_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[TaskPropertyTypeOption] ADD  CONSTRAINT [DF_DI_TaskPropertyTypeOption_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[TaskPropertyTypeOption] ADD  CONSTRAINT [DF_DI_TaskPropertyTypeOption_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[TaskPropertyTypeOption] ADD  CONSTRAINT [DF_DI_TaskPropertyTypeOption_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[TaskPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_TaskPropertyTypeValidation_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[TaskPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_TaskPropertyTypeValidation_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[TaskPropertyTypeValidation] ADD  CONSTRAINT [DF_DI_TaskPropertyTypeValidation_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[TaskResult] ADD  CONSTRAINT [DF_DI_TaskResult_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[TaskResult] ADD  CONSTRAINT [DF_DI_TaskResult_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[TaskResult] ADD  CONSTRAINT [DF_DI_TaskResult]  DEFAULT ((1)) FOR [RetryIndicator]
GO
ALTER TABLE [DI].[TaskType] ADD  CONSTRAINT [DF_DI_TaskType_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[TaskType] ADD  CONSTRAINT [DF_DI_TaskType_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[TaskType] ADD  CONSTRAINT [DF_DI_TaskType_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[TaskType] ADD  CONSTRAINT [DF_DI_TaskType_ScriptIndicator]  DEFAULT ((0)) FOR [ScriptIndicator]
GO
ALTER TABLE [DI].[TaskType] ADD  CONSTRAINT [DF_DI_TaskType_FileLoadIndicator]  DEFAULT ((0)) FOR [FileLoadIndicator]
GO
ALTER TABLE [DI].[TaskType] ADD  CONSTRAINT [DF_DI_TaskType_DatabaseLoadIndicator]  DEFAULT ((0)) FOR [DatabaseLoadIndicator]
GO
ALTER TABLE [DI].[TaskTypeTaskPropertyTypeMapping] ADD  CONSTRAINT [DF_DI_TaskTypeTaskPropertyTypeMapping_DeletedIndicator]  DEFAULT ((0)) FOR [DeletedIndicator]
GO
ALTER TABLE [DI].[TaskTypeTaskPropertyTypeMapping] ADD  CONSTRAINT [DF_DI_TaskTypeTaskPropertyTypeMapping_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[User] ADD  CONSTRAINT [DF_DI_User_EnabledIndicator]  DEFAULT ((1)) FOR [EnabledIndicator]
GO
ALTER TABLE [DI].[User] ADD  CONSTRAINT [DF_DI_User_AdminIndicator]  DEFAULT ((0)) FOR [AdminIndicator]
GO
ALTER TABLE [DI].[User] ADD  CONSTRAINT [DF_DI_User_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[UserPermission] ADD  CONSTRAINT [DF_DI_UserPermission_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [SRC].[DatabaseTableColumn] ADD  CONSTRAINT [DF_DatabaseTableColumn_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [SRC].[DatabaseTableConstraint] ADD  CONSTRAINT [DF_DatabaseTableConstraint_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [SRC].[DatabaseTableRowCount] ADD  CONSTRAINT [DF_DatabaseTableRowCount_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [SRC].[ODBCTableColumn] ADD  CONSTRAINT [DF_ODBCTableColumn_DateCreated]  DEFAULT (sysutcdatetime()) FOR [DateCreated]
GO
ALTER TABLE [DI].[CDCLoadLog]  WITH CHECK ADD  CONSTRAINT [FK_CDCLoadLog_TaskInstance] FOREIGN KEY([TaskInstanceID])
REFERENCES [DI].[TaskInstance] ([TaskInstanceID])
GO
ALTER TABLE [DI].[CDCLoadLog] CHECK CONSTRAINT [FK_CDCLoadLog_TaskInstance]
GO
ALTER TABLE [DI].[Connection]  WITH CHECK ADD  CONSTRAINT [FK_DI_Connection_AuthenticationType] FOREIGN KEY([AuthenticationTypeID])
REFERENCES [DI].[AuthenticationType] ([AuthenticationTypeID])
GO
ALTER TABLE [DI].[Connection] CHECK CONSTRAINT [FK_DI_Connection_AuthenticationType]
GO
ALTER TABLE [DI].[Connection]  WITH CHECK ADD  CONSTRAINT [FK_DI_Connection_ConnectionType] FOREIGN KEY([ConnectionTypeID])
REFERENCES [DI].[ConnectionType] ([ConnectionTypeID])
GO
ALTER TABLE [DI].[Connection] CHECK CONSTRAINT [FK_DI_Connection_ConnectionType]
GO
ALTER TABLE [DI].[ConnectionProperty]  WITH CHECK ADD  CONSTRAINT [DF_DI_ConnectionProperty_Connection] FOREIGN KEY([ConnectionID])
REFERENCES [DI].[Connection] ([ConnectionID])
GO
ALTER TABLE [DI].[ConnectionProperty] CHECK CONSTRAINT [DF_DI_ConnectionProperty_Connection]
GO
ALTER TABLE [DI].[ConnectionProperty]  WITH CHECK ADD  CONSTRAINT [FK_DI_ConnectionProperty_ConnectionPropertyType] FOREIGN KEY([ConnectionPropertyTypeID])
REFERENCES [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID])
GO
ALTER TABLE [DI].[ConnectionProperty] CHECK CONSTRAINT [FK_DI_ConnectionProperty_ConnectionPropertyType]
GO
ALTER TABLE [DI].[ConnectionPropertyType]  WITH CHECK ADD  CONSTRAINT [FK_DI_ConnectionPropertyType_ConnectionPropertyTypeValidation] FOREIGN KEY([ConnectionPropertyTypeValidationID])
REFERENCES [DI].[ConnectionPropertyTypeValidation] ([ConnectionPropertyTypeValidationID])
GO
ALTER TABLE [DI].[ConnectionPropertyType] CHECK CONSTRAINT [FK_DI_ConnectionPropertyType_ConnectionPropertyTypeValidation]
GO
ALTER TABLE [DI].[ConnectionPropertyTypeOption]  WITH CHECK ADD  CONSTRAINT [FK_DI_ConnectionPropertyTypeOption_ConnectionPropertyType] FOREIGN KEY([ConnectionPropertyTypeID])
REFERENCES [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID])
GO
ALTER TABLE [DI].[ConnectionPropertyTypeOption] CHECK CONSTRAINT [FK_DI_ConnectionPropertyTypeOption_ConnectionPropertyType]
GO
ALTER TABLE [DI].[ConnectionTypeAuthenticationTypeMapping]  WITH CHECK ADD  CONSTRAINT [FK_ConnectionTypeAuthenticationTypeMapping_AuthenticationTypeID] FOREIGN KEY([AuthenticationTypeID])
REFERENCES [DI].[AuthenticationType] ([AuthenticationTypeID])
GO
ALTER TABLE [DI].[ConnectionTypeAuthenticationTypeMapping] CHECK CONSTRAINT [FK_ConnectionTypeAuthenticationTypeMapping_AuthenticationTypeID]
GO
ALTER TABLE [DI].[ConnectionTypeAuthenticationTypeMapping]  WITH CHECK ADD  CONSTRAINT [FK_ConnectionTypeAuthenticationTypeMapping_ConnectionTypeID] FOREIGN KEY([ConnectionTypeID])
REFERENCES [DI].[ConnectionType] ([ConnectionTypeID])
GO
ALTER TABLE [DI].[ConnectionTypeAuthenticationTypeMapping] CHECK CONSTRAINT [FK_ConnectionTypeAuthenticationTypeMapping_ConnectionTypeID]
GO
ALTER TABLE [DI].[ConnectionTypeConnectionPropertyTypeMapping]  WITH CHECK ADD  CONSTRAINT [FK_ConnectionTypeAuthenticationTypeMappingConnectionPropertyTypeMapping_ConnectionTypeAuthenticationTypeMappingID] FOREIGN KEY([ConnectionTypeAuthenticationTypeMappingID])
REFERENCES [DI].[ConnectionTypeAuthenticationTypeMapping] ([ConnectionTypeAuthenticationTypeMappingID])
GO
ALTER TABLE [DI].[ConnectionTypeConnectionPropertyTypeMapping] CHECK CONSTRAINT [FK_ConnectionTypeAuthenticationTypeMappingConnectionPropertyTypeMapping_ConnectionTypeAuthenticationTypeMappingID]
GO
ALTER TABLE [DI].[ConnectionTypeConnectionPropertyTypeMapping]  WITH CHECK ADD  CONSTRAINT [FK_ConnectionTypeConnectionPropertyTypeMapping_ConnectionPropertyTypeID] FOREIGN KEY([ConnectionPropertyTypeID])
REFERENCES [DI].[ConnectionPropertyType] ([ConnectionPropertyTypeID])
GO
ALTER TABLE [DI].[ConnectionTypeConnectionPropertyTypeMapping] CHECK CONSTRAINT [FK_ConnectionTypeConnectionPropertyTypeMapping_ConnectionPropertyTypeID]
GO
ALTER TABLE [DI].[DataFactoryLog]  WITH CHECK ADD  CONSTRAINT [FK_DataFactoryLog_FileLoadLog] FOREIGN KEY([FileLoadLogID])
REFERENCES [DI].[FileLoadLog] ([FileLoadLogID])
GO
ALTER TABLE [DI].[DataFactoryLog] CHECK CONSTRAINT [FK_DataFactoryLog_FileLoadLog]
GO
ALTER TABLE [DI].[DataFactoryLog]  WITH CHECK ADD  CONSTRAINT [FK_DataFactoryLog_TaskInstance] FOREIGN KEY([TaskInstanceID])
REFERENCES [DI].[TaskInstance] ([TaskInstanceID])
GO
ALTER TABLE [DI].[DataFactoryLog] CHECK CONSTRAINT [FK_DataFactoryLog_TaskInstance]
GO
ALTER TABLE [DI].[FileColumnMapping]  WITH CHECK ADD  CONSTRAINT [FK_FileColumnMapping_FileInterimDataTypeID] FOREIGN KEY([FileInterimDataTypeID])
REFERENCES [DI].[FileInterimDataType] ([FileInterimDataTypeID])
GO
ALTER TABLE [DI].[FileColumnMapping] CHECK CONSTRAINT [FK_FileColumnMapping_FileInterimDataTypeID]
GO
ALTER TABLE [DI].[FileColumnMapping]  WITH CHECK ADD  CONSTRAINT [FK_FileColumnMapping_TaskID] FOREIGN KEY([TaskID])
REFERENCES [DI].[Task] ([TaskID])
GO
ALTER TABLE [DI].[FileColumnMapping] CHECK CONSTRAINT [FK_FileColumnMapping_TaskID]
GO
ALTER TABLE [DI].[FileLoadLog]  WITH CHECK ADD  CONSTRAINT [FK_DI_FileLoadLog_TaskInstance] FOREIGN KEY([TaskInstanceID])
REFERENCES [DI].[TaskInstance] ([TaskInstanceID])
GO
ALTER TABLE [DI].[FileLoadLog] CHECK CONSTRAINT [FK_DI_FileLoadLog_TaskInstance]
GO
ALTER TABLE [DI].[IncrementalLoadLog]  WITH CHECK ADD  CONSTRAINT [FK_IncrementalLoadLog_TaskInstance] FOREIGN KEY([TaskInstanceID])
REFERENCES [DI].[TaskInstance] ([TaskInstanceID])
GO
ALTER TABLE [DI].[IncrementalLoadLog] CHECK CONSTRAINT [FK_IncrementalLoadLog_TaskInstance]
GO
ALTER TABLE [DI].[Schedule]  WITH CHECK ADD  CONSTRAINT [DI_Schedule_ScheduleInstance] FOREIGN KEY([ScheduleIntervalID])
REFERENCES [DI].[ScheduleInterval] ([ScheduleIntervalID])
GO
ALTER TABLE [DI].[Schedule] CHECK CONSTRAINT [DI_Schedule_ScheduleInstance]
GO
ALTER TABLE [DI].[ScheduleInstance]  WITH CHECK ADD  CONSTRAINT [FK_DI_Schedule_ScheduleInstance] FOREIGN KEY([ScheduleID])
REFERENCES [DI].[Schedule] ([ScheduleID])
GO
ALTER TABLE [DI].[ScheduleInstance] CHECK CONSTRAINT [FK_DI_Schedule_ScheduleInstance]
GO
ALTER TABLE [DI].[SystemDependency]  WITH CHECK ADD  CONSTRAINT [FK_SystemDependency_DependencyID] FOREIGN KEY([DependencyID])
REFERENCES [DI].[System] ([SystemID])
GO
ALTER TABLE [DI].[SystemDependency] CHECK CONSTRAINT [FK_SystemDependency_DependencyID]
GO
ALTER TABLE [DI].[SystemDependency]  WITH CHECK ADD  CONSTRAINT [FK_SystemDependency_SystemID] FOREIGN KEY([SystemID])
REFERENCES [DI].[System] ([SystemID])
GO
ALTER TABLE [DI].[SystemDependency] CHECK CONSTRAINT [FK_SystemDependency_SystemID]
GO
ALTER TABLE [DI].[SystemProperty]  WITH CHECK ADD  CONSTRAINT [DF_DI_SystemProperty_System] FOREIGN KEY([SystemID])
REFERENCES [DI].[System] ([SystemID])
GO
ALTER TABLE [DI].[SystemProperty] CHECK CONSTRAINT [DF_DI_SystemProperty_System]
GO
ALTER TABLE [DI].[SystemProperty]  WITH CHECK ADD  CONSTRAINT [FK_DI_SystemProperty_SystemPropertyType] FOREIGN KEY([SystemPropertyTypeID])
REFERENCES [DI].[SystemPropertyType] ([SystemPropertyTypeID])
GO
ALTER TABLE [DI].[SystemProperty] CHECK CONSTRAINT [FK_DI_SystemProperty_SystemPropertyType]
GO
ALTER TABLE [DI].[SystemPropertyType]  WITH CHECK ADD  CONSTRAINT [FK_DI_SystemPropertyType_SystemPropertyTypeValidation] FOREIGN KEY([SystemPropertyTypeValidationID])
REFERENCES [DI].[SystemPropertyTypeValidation] ([SystemPropertyTypeValidationID])
GO
ALTER TABLE [DI].[SystemPropertyType] CHECK CONSTRAINT [FK_DI_SystemPropertyType_SystemPropertyTypeValidation]
GO
ALTER TABLE [DI].[SystemPropertyTypeOption]  WITH CHECK ADD  CONSTRAINT [FK_DI_SystemPropertyTypeOption_SystemPropertyType] FOREIGN KEY([SystemPropertyTypeID])
REFERENCES [DI].[SystemPropertyType] ([SystemPropertyTypeID])
GO
ALTER TABLE [DI].[SystemPropertyTypeOption] CHECK CONSTRAINT [FK_DI_SystemPropertyTypeOption_SystemPropertyType]
GO
ALTER TABLE [DI].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_ETLConnectionID] FOREIGN KEY([ETLConnectionID])
REFERENCES [DI].[Connection] ([ConnectionID])
GO
ALTER TABLE [DI].[Task] CHECK CONSTRAINT [FK_Task_ETLConnectionID]
GO
ALTER TABLE [DI].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_Schedule] FOREIGN KEY([ScheduleID])
REFERENCES [DI].[Schedule] ([ScheduleID])
GO
ALTER TABLE [DI].[Task] CHECK CONSTRAINT [FK_Task_Schedule]
GO
ALTER TABLE [DI].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_SourceConnection] FOREIGN KEY([SourceConnectionID])
REFERENCES [DI].[Connection] ([ConnectionID])
GO
ALTER TABLE [DI].[Task] CHECK CONSTRAINT [FK_Task_SourceConnection]
GO
ALTER TABLE [DI].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_StageConnectionID] FOREIGN KEY([StageConnectionID])
REFERENCES [DI].[Connection] ([ConnectionID])
GO
ALTER TABLE [DI].[Task] CHECK CONSTRAINT [FK_Task_StageConnectionID]
GO
ALTER TABLE [DI].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_System] FOREIGN KEY([SystemID])
REFERENCES [DI].[System] ([SystemID])
GO
ALTER TABLE [DI].[Task] CHECK CONSTRAINT [FK_Task_System]
GO
ALTER TABLE [DI].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_TargetConnection] FOREIGN KEY([TargetConnectionID])
REFERENCES [DI].[Connection] ([ConnectionID])
GO
ALTER TABLE [DI].[Task] CHECK CONSTRAINT [FK_Task_TargetConnection]
GO
ALTER TABLE [DI].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_TaskType] FOREIGN KEY([TaskTypeID])
REFERENCES [DI].[TaskType] ([TaskTypeID])
GO
ALTER TABLE [DI].[Task] CHECK CONSTRAINT [FK_Task_TaskType]
GO
ALTER TABLE [DI].[TaskInstance]  WITH CHECK ADD  CONSTRAINT [FK_DI_ScheduleInstance_TaskInstance] FOREIGN KEY([ScheduleInstanceID])
REFERENCES [DI].[ScheduleInstance] ([ScheduleInstanceID])
GO
ALTER TABLE [DI].[TaskInstance] CHECK CONSTRAINT [FK_DI_ScheduleInstance_TaskInstance]
GO
ALTER TABLE [DI].[TaskInstance]  WITH CHECK ADD  CONSTRAINT [FK_DI_Task_TaskInstance] FOREIGN KEY([TaskID])
REFERENCES [DI].[Task] ([TaskID])
GO
ALTER TABLE [DI].[TaskInstance] CHECK CONSTRAINT [FK_DI_Task_TaskInstance]
GO
ALTER TABLE [DI].[TaskInstance]  WITH CHECK ADD  CONSTRAINT [FK_DI_TaskResult_TaskInstance] FOREIGN KEY([TaskResultID])
REFERENCES [DI].[TaskResult] ([TaskResultID])
GO
ALTER TABLE [DI].[TaskInstance] CHECK CONSTRAINT [FK_DI_TaskResult_TaskInstance]
GO
ALTER TABLE [DI].[TaskProperty]  WITH CHECK ADD  CONSTRAINT [FK_DI_TaskProperty_Task] FOREIGN KEY([TaskID])
REFERENCES [DI].[Task] ([TaskID])
GO
ALTER TABLE [DI].[TaskProperty] CHECK CONSTRAINT [FK_DI_TaskProperty_Task]
GO
ALTER TABLE [DI].[TaskProperty]  WITH CHECK ADD  CONSTRAINT [FK_DI_TaskProperty_TaskPropertyType] FOREIGN KEY([TaskPropertyTypeID])
REFERENCES [DI].[TaskPropertyType] ([TaskPropertyTypeID])
GO
ALTER TABLE [DI].[TaskProperty] CHECK CONSTRAINT [FK_DI_TaskProperty_TaskPropertyType]
GO
ALTER TABLE [DI].[TaskPropertyPassthroughMapping]  WITH CHECK ADD  CONSTRAINT [FK_TaskPropertyPassthroughMapping_TaskID] FOREIGN KEY([TaskID])
REFERENCES [DI].[Task] ([TaskID])
GO
ALTER TABLE [DI].[TaskPropertyPassthroughMapping] CHECK CONSTRAINT [FK_TaskPropertyPassthroughMapping_TaskID]
GO
ALTER TABLE [DI].[TaskPropertyPassthroughMapping]  WITH CHECK ADD  CONSTRAINT [FK_TaskPropertyPassthroughMapping_TaskPassthroughID] FOREIGN KEY([TaskPassthroughID])
REFERENCES [DI].[Task] ([TaskID])
GO
ALTER TABLE [DI].[TaskPropertyPassthroughMapping] CHECK CONSTRAINT [FK_TaskPropertyPassthroughMapping_TaskPassthroughID]
GO
ALTER TABLE [DI].[TaskPropertyType]  WITH CHECK ADD  CONSTRAINT [FK_DI_TaskPropertyType_TaskPropertyTypeValidation] FOREIGN KEY([TaskPropertyTypeValidationID])
REFERENCES [DI].[TaskPropertyTypeValidation] ([TaskPropertyTypeValidationID])
GO
ALTER TABLE [DI].[TaskPropertyType] CHECK CONSTRAINT [FK_DI_TaskPropertyType_TaskPropertyTypeValidation]
GO
ALTER TABLE [DI].[TaskPropertyTypeOption]  WITH CHECK ADD  CONSTRAINT [FK_DI_TaskPropertyTypeOption_TaskPropertyType] FOREIGN KEY([TaskPropertyTypeID])
REFERENCES [DI].[TaskPropertyType] ([TaskPropertyTypeID])
GO
ALTER TABLE [DI].[TaskPropertyTypeOption] CHECK CONSTRAINT [FK_DI_TaskPropertyTypeOption_TaskPropertyType]
GO
ALTER TABLE [DI].[TaskTypeTaskPropertyTypeMapping]  WITH CHECK ADD  CONSTRAINT [FK_TaskTypeTaskPropertyTypeMapping_TaskPropertyTypeID] FOREIGN KEY([TaskPropertyTypeID])
REFERENCES [DI].[TaskPropertyType] ([TaskPropertyTypeID])
GO
ALTER TABLE [DI].[TaskTypeTaskPropertyTypeMapping] CHECK CONSTRAINT [FK_TaskTypeTaskPropertyTypeMapping_TaskPropertyTypeID]
GO
ALTER TABLE [DI].[TaskTypeTaskPropertyTypeMapping]  WITH CHECK ADD  CONSTRAINT [FK_TaskTypeTaskPropertyTypeMapping_TaskTypeID] FOREIGN KEY([TaskTypeID])
REFERENCES [DI].[TaskType] ([TaskTypeID])
GO
ALTER TABLE [DI].[TaskTypeTaskPropertyTypeMapping] CHECK CONSTRAINT [FK_TaskTypeTaskPropertyTypeMapping_TaskTypeID]
GO
ALTER TABLE [DI].[UserPermission]  WITH CHECK ADD  CONSTRAINT [FK_UserPermission_System] FOREIGN KEY([SystemID])
REFERENCES [DI].[System] ([SystemID])
GO
ALTER TABLE [DI].[UserPermission] CHECK CONSTRAINT [FK_UserPermission_System]
GO
ALTER TABLE [DI].[UserPermission]  WITH CHECK ADD  CONSTRAINT [FK_UserPermission_User] FOREIGN KEY([UserID])
REFERENCES [DI].[User] ([UserID])
GO
ALTER TABLE [DI].[UserPermission] CHECK CONSTRAINT [FK_UserPermission_User]
GO
ALTER TABLE [SRC].[DatabaseTableColumn]  WITH CHECK ADD  CONSTRAINT [FK_DatabaseTableColumn_Connection] FOREIGN KEY([ConnectionID])
REFERENCES [DI].[Connection] ([ConnectionID])
GO
ALTER TABLE [SRC].[DatabaseTableColumn] CHECK CONSTRAINT [FK_DatabaseTableColumn_Connection]
GO
ALTER TABLE [SRC].[DatabaseTableConstraint]  WITH CHECK ADD  CONSTRAINT [FK_DatabaseTableConstraint_Connection] FOREIGN KEY([ConnectionID])
REFERENCES [DI].[Connection] ([ConnectionID])
GO
ALTER TABLE [SRC].[DatabaseTableConstraint] CHECK CONSTRAINT [FK_DatabaseTableConstraint_Connection]
GO
ALTER TABLE [SRC].[DatabaseTableRowCount]  WITH CHECK ADD  CONSTRAINT [FK_DatabaseTableRowCount_Connection] FOREIGN KEY([ConnectionID])
REFERENCES [DI].[Connection] ([ConnectionID])
GO
ALTER TABLE [SRC].[DatabaseTableRowCount] CHECK CONSTRAINT [FK_DatabaseTableRowCount_Connection]
GO
