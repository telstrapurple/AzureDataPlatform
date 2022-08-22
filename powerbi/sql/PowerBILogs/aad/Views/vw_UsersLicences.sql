CREATE VIEW aad.vw_UsersLicences

AS

SELECT
	[UserID]
	,[SKUID] AS [SKU ID]
	,[SKUName] AS [SKU Name]
FROM
	aad.UsersLicences
