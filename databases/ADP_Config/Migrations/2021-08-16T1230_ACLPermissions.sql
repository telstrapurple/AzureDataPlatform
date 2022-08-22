ALTER TABLE [DI].[SystemPropertyType]
ALTER COLUMN [SystemPropertyTypeDescription] NVARCHAR (MAX)
GO
ALTER TABLE [DI].[TaskPropertyType]
ALTER COLUMN [TaskPropertyTypeDescription] NVARCHAR (MAX)
GO
DECLARE
	@TaskPropertyTypeID INT

--Add a new task property type--

IF NOT EXISTS (SELECT 1 FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'ACL Permissions') 
BEGIN

	INSERT INTO DI.TaskPropertyType
	(
		TaskPropertyTypeName
		,TaskPropertyTypeDescription
		,TaskPropertyTypeValidationID
	)
	SELECT
		'ACL Permissions'
		,'A json array defining the required ACL permissions on an Azure AD object level .e.g
		  [
		    {
		      "objectType": ["User","Group","ServicePrincipal"],
			  "objectName": "<Azure AD Object Name>",
			  "permission": ["rwx","rw-","r-x","-wx","r--","-w-","--x","---"],
			  "path": "<Data lake blob or folder path, including container>"
		    }
		  ]
		'
		,(SELECT TPTV.TaskPropertyTypeValidationID FROM DI.TaskPropertyTypeValidation TPTV WHERE TPTV.TaskPropertyTypeValidationName = 'MultiLineTextBox')

END

SELECT @TaskPropertyTypeID = TaskPropertyTypeID FROM DI.TaskPropertyType WHERE TaskPropertyTypeName = 'ACL Permissions'

IF NOT EXISTS (SELECT 1 FROM DI.TaskTypeTaskPropertyTypeMapping TTTPTM INNER JOIN DI.TaskPropertyType TPT ON TTTPTM.TaskPropertyTypeID = TPT.TaskPropertyTypeID WHERE TPT.TaskPropertyTypeName = 'ACL Permissions') 
BEGIN

	INSERT INTO DI.TaskTypeTaskPropertyTypeMapping
	(
		TaskTypeID
		,TaskPropertyTypeID
	)
	SELECT
		TT.TaskTypeID
		,TPT.TaskPropertyTypeID
	FROM
		DI.TaskType TT
		,DI.TaskPropertyType TPT
	WHERE
		TT.TaskTypeName <> 'Databricks notebook'
		AND TT.TaskTypeName <> 'SQL Stored Procedure'
		AND TPT.TaskPropertyTypeName = 'ACL Permissions'

END
GO

--Add a new system property--

IF NOT EXISTS (SELECT 1 FROM DI.SystemPropertyType SPT WHERE SPT.SystemPropertyTypeName = 'ACL Permissions') 
BEGIN

	INSERT INTO DI.SystemPropertyType
	(
		SystemPropertyTypeName
		,SystemPropertyTypeDescription
		,SystemPropertyTypeValidationID
	)
	SELECT
		'ACL Permissions'
		,'A json array defining the required ACL permissions on an Azure AD object level .e.g
		  [
		    {
		      "objectType": ["User","Group","ServicePrincipal"],
			  "objectName": "<Azure AD Object Name>",
			  "permission": ["rwx","rw-","r-x","-wx","r--","-w-","--x","---"],
			  "path": "<Data lake blob or folder path, including container>"
		    }
		  ]
		'
		,(SELECT SPTV.SystemPropertyTypeValidationID FROM DI.SystemPropertyTypeValidation SPTV WHERE SPTV.SystemPropertyTypeValidationName = 'MultiLineTextBox')

END
GO