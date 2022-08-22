-- Create new connection type for 'Azure File Share' 
INSERT INTO DI.ConnectionType (
    ConnectionTypeName, 
    ConnectionTypeDescription,
    EnabledIndicator,
    DeletedIndicator, 
    DatabaseConnectionIndicator, 
    FileConnectionIndicator, 
    CRMConnectionIndicator,
    ODBCConnectionIndicator
) VALUES 
(
    'Azure File Share',
    'An Azure File Share connection',
    1,
    0,
    0,
    1,
    0,
    0
)

-- Create new Connection Property Type
INSERT INTO DI.ConnectionPropertyType (
    ConnectionPropertyTypeName,
    ConnectionPropertyTypeDescription, 
    ConnectionPropertyTypeValidationID
)
VALUES ( 
    'Storage Account Name',
    'The name of the storage account of the file share.',
    1
),
( 
    'File Share',
    'The the name of the file share.',
    1
),
( 
    'Account Key Secret Name',
    'The the name of the KeyVault secret which stores the account key.',
    1
)

-- Create new authentication type 
INSERT INTO DI.AuthenticationType ( 
    AuthenticationTypeName, 
    AuthenticationTypeDescription,
    EnabledIndicator,
    DeletedIndicator
) VALUES ( 
    'Account Key', 
    'Account Key',
    1,
    0
)

-- Add new mapping for authentication type against connection type
INSERT INTO DI.ConnectionTypeAuthenticationTypeMapping (
    ConnectionTypeID,
    AuthenticationTypeID,
    DeletedIndicator
) VALUES ( 
    (SELECT ConnectionTypeID FROM DI.ConnectionType WHERE ConnectionTypeName = 'Azure File Share'),
	(SELECT AuthenticationTypeID FROM DI.AuthenticationType WHERE AuthenticationTypeName = 'Account Key'),
    0
)

-- Add new mapping for connection property type and connection authentication type mapping
INSERT INTO DI.ConnectionTypeConnectionPropertyTypeMapping (
    ConnectionPropertyTypeID,
    ConnectionTypeAuthenticationTypeMappingID,
    DeletedIndicator
)
VALUES ( 
    (SELECT ConnectionPropertyTypeID FROM DI.ConnectionPropertyType WHERE ConnectionPropertyTypeName = 'Storage Account Name'),
	(SELECT ConnectionTypeAuthenticationTypeMappingID FROM DI.ConnectionTypeAuthenticationTypeMapping WHERE 
        ConnectionTypeID = (
            SELECT ConnectionTypeID FROM DI.ConnectionType WHERE ConnectionTypeName = 'Azure File Share'
        ) AND 
        AuthenticationTypeID = (
            SELECT AuthenticationTypeID FROM DI.AuthenticationType WHERE AuthenticationTypeName = 'Account Key'
        )
    ),
    0
),
( 
    (SELECT ConnectionPropertyTypeID FROM DI.ConnectionPropertyType WHERE ConnectionPropertyTypeName = 'File Share'),
	(SELECT ConnectionTypeAuthenticationTypeMappingID FROM DI.ConnectionTypeAuthenticationTypeMapping WHERE 
        ConnectionTypeID = (
            SELECT ConnectionTypeID FROM DI.ConnectionType WHERE ConnectionTypeName = 'Azure File Share'
        ) AND 
        AuthenticationTypeID = (
            SELECT AuthenticationTypeID FROM DI.AuthenticationType WHERE AuthenticationTypeName = 'Account Key'
        )
    ),
    0
),
( 
    (SELECT ConnectionPropertyTypeID FROM DI.ConnectionPropertyType WHERE ConnectionPropertyTypeName = 'Account Key Secret Name'),
	(SELECT ConnectionTypeAuthenticationTypeMappingID FROM DI.ConnectionTypeAuthenticationTypeMapping WHERE 
        ConnectionTypeID = (
            SELECT ConnectionTypeID FROM DI.ConnectionType WHERE ConnectionTypeName = 'Azure File Share'
        ) AND 
        AuthenticationTypeID = (
            SELECT AuthenticationTypeID FROM DI.AuthenticationType WHERE AuthenticationTypeName = 'Account Key'
        )
    ),
    0
)