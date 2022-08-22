CREATE PROCEDURE [pbi].[usp_Get_ActivityEvents_Timestamp]
AS
BEGIN TRY 
	SELECT MAX([EndDateTime]) AS [EndDateTime] FROM pbi.ActivityEventsLoadLog
END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH