CREATE PROCEDURE [pbi].[usp_Set_ActivityEvents_Timestamp]
	@StartDateTime DATETIMEOFFSET(7),
	@EndDateTime DATETIMEOFFSET(7)
AS
BEGIN TRY 
	
	
	IF EXISTS (SELECT 1 FROM pbi.ActivityEventsLoadLog WHERE [StartDateTime] = @StartDateTime AND [EndDateTime] = @EndDateTime)
	BEGIN
		PRINT 'Log already exists for the Activity Event'
	END 
	ELSE 
	BEGIN 
		INSERT INTO pbi.ActivityEventsLoadLog ([StartDateTime], [EndDateTime])
		VALUES(@StartDateTime, @EndDateTime)
	END 

END TRY

BEGIN CATCH

	DECLARE @Error VARCHAR(MAX)
	SET @Error = ERROR_MESSAGE()
	;
	THROW 51000, @Error, 1 
END CATCH