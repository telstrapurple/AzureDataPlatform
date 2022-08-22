UPDATE DI.TaskPropertyType
SET TaskPropertyTypeDescription = 'A json array defining the required ACL permissions on an Azure AD object level .e.g
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
WHERE TaskPropertyTypeID = (
    SELECT TaskPropertyTypeID FROM DI.TaskPropertyType TPT WHERE TPT.TaskPropertyTypeName = 'ACL Permissions'
)

UPDATE DI.SystemPropertyType
SET SystemPropertyTypeDescription = 'A json array defining the required ACL permissions on an Azure AD object level .e.g
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
WHERE SystemPropertyTypeID = (
    SELECT SystemPropertyTypeID FROM DI.SystemPropertyType SPT WHERE SPT.SystemPropertyTypeName = 'ACL Permissions'
)