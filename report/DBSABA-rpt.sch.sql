SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


USE	SabaDB;
GO
DECLARE	@sch	NVARCHAR(128)		= N'rpt'
	,	@label	NVARCHAR(20)		= N'Schema'
	,	@msg	NVARCHAR(MAX)
	;


BEGIN TRY;
IF	SCHEMA_ID(@sch) IS NULL
BEGIN
	SELECT	@msg	= CONCAT(N'CREATE SCHEMA [', @sch ,N'] AUTHORIZATION dbo');
	EXECUTE	sys.sp_executesql @msg;

	SELECT	@msg	= CONCAT(N'Successfully created schema [', @sch, N']');
	EXECUTE	logger.Info @label, @msg;
END;
ELSE
BEGIN;
	SELECT	@msg	= CONCAT(N'Schema [', @sch, N'] has already existed');
	EXECUTE	logger.Info @label, @msg;
END;

SELECT	@msg	= CONCAT(N'GRANT EXECUTE ON SCHEMA::[', @sch ,N'] TO lmnReport;');
EXECUTE	sys.sp_executesql @msg;

END TRY BEGIN CATCH
	SELECT	@msg	= CONCAT(N'Failed to create schema [', @sch, N']');
	EXECUTE	logger.Error @label, @msg;
END CATCH;
GO
