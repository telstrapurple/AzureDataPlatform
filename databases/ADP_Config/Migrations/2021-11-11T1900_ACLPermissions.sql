ALTER TABLE [DI].[SystemPropertyType]
ALTER COLUMN [SystemPropertyTypeDescription] NVARCHAR (MAX)
GO

--The telstra purple version of this migration includes task permissions
--but the permission model in S32 only manages permissions at the system level

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
		  {
            "serviceEndpoint": "<Service Endpoint URL>",
            "aclPermissions": 
                [
                    {
						"objectType": ["User","Group","ServicePrincipal"],
						"objectID": "<Azure AD Object ID>",
						"permission": ["rwx","rw-","r-x","-wx","r--","-w-","--x","---"],
						"path": "<Data lake blob or folder path, including container>"
                    }
                ]
          }
		'
		,(SELECT SPTV.SystemPropertyTypeValidationID FROM DI.SystemPropertyTypeValidation SPTV WHERE SPTV.SystemPropertyTypeValidationName = 'MultiLineTextBox')

END
GO
