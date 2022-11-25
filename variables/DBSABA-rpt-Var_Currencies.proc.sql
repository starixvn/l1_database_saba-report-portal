SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE	SabaDB;
GO
DECLARE	@Object		SYSNAME		= N'rpt.Var_Currencies'
	,	@Version	SYSNAME		= N'0.0.1'
	;
EXECUTE	dbo.sp_MSR_InitProcedure @Object;
EXECUTE	dbo.sp_MSR_SetVersion @Object, @Version;
GO
ALTER PROCEDURE	rpt.Var_Currencies
					@L				NVARCHAR(128)	= NULL
WITH ENCRYPTION
AS
/*
	Creator:		20221122@Billy
	Location:		DBSABA.SabaDB
	Description:	Variable - Currencies
	Version:		0.0.1
	Revision:
		- [0.0.1]	20221122@Billy		Initialize
*/
BEGIN;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	/** Process Ls */
	DECLARE	@Ls		rpt.Ls;
	DECLARE	@_L		INT;
	BEGIN;
		INSERT INTO	@Ls (L)
		SELECT	item.value
		FROM		base.tf_DecodeURL(@L) AS str
		CROSS APPLY	STRING_SPLIT(SUBSTRING(str.str, 2, LEN(str.str) - 2), ',') AS item
	END;

	DECLARE	@Result		rpt.OneStringValue;

	DECLARE	@Query		NVARCHAR(MAX)
		;

	WHILE	0 = 0
	BEGIN;
		UPDATE	TOP(1)
				@Ls
		SET		@_L		= L
			,	isDone	= 1
		WHERE	isDone	= 0;

		IF	@@ROWCOUNT = 0
			BREAK;

		SELECT	@Query = N'\
SELECT	DISTINCT
		name
FROM	minigame.currencies
WHERE	enabled = 1
	AND	isTest = 0
;';
		INSERT INTO	@Result (value)
		EXECUTE	base.Query @Query, @_L, 0, 1;
	END;

	SELECT	DISTINCT
			value
	FROM	@Result
	ORDER BY value;
END;
GO
EXECUTE	rpt.Var_Currencies @L = '%7B1%2C2%7D';
GO
