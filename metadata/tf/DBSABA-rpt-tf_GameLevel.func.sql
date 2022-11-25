SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE	SabaDB;
GO
DECLARE	@Object		SYSNAME		= N'rpt.tf_GameLevel'
	,	@Version	SYSNAME		= N'0.0.1'
	;
EXECUTE	dbo.sp_MSR_InitInlineTableFunction @Object;
EXECUTE	dbo.sp_MSR_SetVersion @Object, @Version;
GO
ALTER FUNCTION	rpt.tf_GameLevel (
					@Level			NVARCHAR(128)
				)
RETURNS TABLE
WITH ENCRYPTION
AS
/*
	Creator:		20221125@Billy
	Location:		DBSABA.SabaDB
	Description:	
	Version:		0.0.1
	Revision:
		- [0.0.1]	20221125@Billy		Initialize
*/
RETURN (
	SELECT	map.val, map.col
	FROM	(
		VALUES	(N'Details', N'nameEN')
			,	(N'Game'   , N'gameName')
			,	(N'Group'  , N'groupName')
			,	(N''       , N'gameName')
	) AS map(val, col)
	WHERE	map.val = ISNULL(@Level, map.val)
);
GO
