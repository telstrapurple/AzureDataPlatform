CREATE   PROCEDURE [pbi].[usp_Constraint_Enable_Disable]
(
	@Action VARCHAR(50) = 'Disable'
)

AS

BEGIN

	DECLARE
		@ExecCommand NVARCHAR(MAX) = ''

	IF @Action = 'Disable'

	BEGIN

		SELECT
			@ExecCommand = STRING_AGG('ALTER TABLE [' + TABLE_SCHEMA + '].[' + TABLE_NAME + '] NOCHECK CONSTRAINT ALL', ';')
		FROM
			INFORMATION_SCHEMA.TABLES
		WHERE
			TABLE_TYPE = 'Base Table'
			AND TABLE_SCHEMA IN('pbi', 'lga')

	END

	ELSE IF @Action = 'Enable'

	BEGIN

		SELECT
			@ExecCommand = STRING_AGG('ALTER TABLE [' + TABLE_SCHEMA + '].[' + TABLE_NAME + '] WITH CHECK CHECK CONSTRAINT ALL', ';')
		FROM
			INFORMATION_SCHEMA.TABLES
		WHERE
			TABLE_TYPE = 'Base Table'
			AND TABLE_SCHEMA IN('pbi', 'lga')

	END

	EXECUTE sp_executeSQL @ExecCommand

END