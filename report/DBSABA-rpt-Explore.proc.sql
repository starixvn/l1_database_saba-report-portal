SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE	SabaDB;
GO
DECLARE	@Object		SYSNAME		= N'rpt.Explore'
	,	@Version	SYSNAME		= N'0.0.1'
	;
EXECUTE	dbo.sp_MSR_InitProcedure @Object;
EXECUTE	dbo.sp_MSR_SetVersion @Object, @Version;
GO
ALTER PROCEDURE	rpt.Explore
					@Query		NVARCHAR(MAX)
				,	@L			TINYINT
				,	@Type		TINYINT			= 0
WITH ENCRYPTION
AS
EXECUTE	base.Query @Query, @L, @Type, 1;
GO
