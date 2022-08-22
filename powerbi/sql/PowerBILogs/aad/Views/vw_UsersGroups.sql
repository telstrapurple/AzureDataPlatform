CREATE VIEW aad.vw_UsersGroups

AS

SELECT
	[UserID]
	,UG.GroupID
	,G.GroupName AS [Group Name]
	,G.Mail AS [Group Mail]
	,G.MailEnabled AS [Mail Enabled]
	,G.SecurityEnabled AS [Security Enabled]
FROM
	aad.UsersGroups UG
	INNER JOIN aad.Groups G ON UG.GroupID = G.GroupID
