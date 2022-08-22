/****** Object:  StoredProcedure [DI].[usp_Config_Clean]    Script Date: 1/12/2020 11:43:32 PM ******/
DROP PROCEDURE IF EXISTS [DI].[usp_Config_Clean]
GO
/****** Object:  StoredProcedure [DI].[usp_Config_Clean]    Script Date: 1/12/2020 11:43:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DI].[usp_Config_Clean]

AS

SET NOCOUNT ON

BEGIN TRY

	TRUNCATE TABLE [SRC].[DatabaseTable]
	TRUNCATE TABLE [SRC].[DatabaseTableColumn]
	TRUNCATE TABLE [SRC].[DatabaseTableConstraint]
	TRUNCATE TABLE [SRC].[DatabaseTableRowCount]
	TRUNCATE TABLE [SRC].[ODBCTable]
	TRUNCATE TABLE [SRC].[ODBCTableColumn]
	TRUNCATE TABLE DI.DataFactoryLog
	TRUNCATE TABLE DI.FileColumnMapping
	TRUNCATE TABLE DI.TaskPropertyPassthroughMapping
	TRUNCATE TABLE DI.SystemDependency
	TRUNCATE TABLE DI.[UserPermission]
	--TRUNCATE TABLE DI.FileLoadLog
	--TRUNCATE TABLE DI.IncrementalLoadLog

	DELETE FROM DI.FileLoadLog
	DBCC CHECKIDENT('DI.FileLoadLog', RESEED, 0)
	DELETE FROM DI.IncrementalLoadLog
	DBCC CHECKIDENT('DI.IncrementalLoadLog', RESEED, 0)
	DELETE FROM DI.CDCLoadLog
	DBCC CHECKIDENT('DI.CDCLoadLog', RESEED, 0)

	DELETE FROM DI.TaskInstance
	DBCC CHECKIDENT('DI.TaskInstance', RESEED, 0)
	DELETE FROM DI.ScheduleInstance
	DBCC CHECKIDENT('DI.ScheduleInstance', RESEED, 0)
	DELETE FROM DI.TaskProperty
	DBCC CHECKIDENT('DI.TaskProperty', RESEED, 0)
	DELETE FROM DI.Task
	DBCC CHECKIDENT('DI.Task', RESEED, 0)
	DELETE FROM DI.[ConnectionProperty] WHERE ConnectionID NOT IN(1,2)
	DBCC CHECKIDENT('DI.ConnectionProperty', RESEED, 0)
	DELETE FROM DI.[Connection] WHERE ConnectionName NOT IN('ADS Config', 'ADS Staging', 'Databricks ETL Cluster', 'ADS Data Lake')
	DBCC CHECKIDENT('DI.Connection', RESEED, 4) -- JN: updated this value to 4 as we are saving 4 records in the DB for generic configs
	DELETE FROM DI.[SystemProperty]
	DBCC CHECKIDENT('DI.SystemProperty', RESEED, 0)
	DELETE FROM DI.UserPermission
	DBCC CHECKIDENT('DI.UserPermission', RESEED, 0)
	DELETE FROM DI.[System]
	DBCC CHECKIDENT('DI.System', RESEED, 0)
	DELETE FROM DI.[User]

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH
GO
