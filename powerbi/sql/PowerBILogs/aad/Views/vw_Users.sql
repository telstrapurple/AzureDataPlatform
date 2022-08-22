CREATE VIEW [aad].[vw_Users]

AS

SELECT
	[UserID]
	,[DisplayName] AS [User Display Name]
	,[UserPrincipalName] AS [User Principal Name]
	,[GivenName] AS [Given Name]
	,[Surname]
	,[Mail]
	,[MailNickname] AS [Mail Nickname]
	,[DeletionTimestamp] AS [Deletion Timestamp]
	,[AccountEnabled] AS [Account Enabled]
	,[ImmutableID] AS [Immutable ID]
	,CAST(0 AS BIT) AS [Account Deleted]
FROM
	aad.Users

UNION ALL

--Union on the deleted users

SELECT
	UH.[UserID]
	,UH.[User Display Name]
	,UH.[User Principal Name]
	,UH.[Given Name]
	,UH.[Surname]
	,UH.[Mail]
	,UH.[Mail Nickname]
	,UH.[Deletion Timestamp]
	,UH.[Account Enabled]
	,UH.[Immutable ID]
	,UH.[Account Deleted]
FROM
	(SELECT
		UH.[UserID]
		,UH.[DisplayName] AS [User Display Name]
		,UH.[UserPrincipalName] AS [User Principal Name]
		,UH.[GivenName] AS [Given Name]
		,UH.[Surname]
		,UH.[Mail]
		,UH.[MailNickname] AS [Mail Nickname]
		,UH.ValidTo AS [Deletion Timestamp]
		,UH.[AccountEnabled] AS [Account Enabled]
		,UH.[ImmutableID] AS [Immutable ID]
		,CAST(1 AS BIT) AS [Account Deleted]
		,ROW_NUMBER() OVER(PARTITION BY UserID ORDER BY ValidTo DESC) AS RowID
	FROM
		aad.Users_History UH
	) UH
	INNER JOIN
	(
	SELECT
		UserID
	FROM
		aad.Users_History

	EXCEPT

	SELECT
		UserID
	FROM
		aad.Users
	) DU ON UH.UserID = DU.UserID
WHERE
	UH.RowID = 1




