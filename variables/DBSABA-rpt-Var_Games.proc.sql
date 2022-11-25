SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE	SabaDB;
GO
DECLARE	@Object		SYSNAME		= N'rpt.Var_Games'
	,	@Version	SYSNAME		= N'0.0.1'
	;
EXECUTE	dbo.sp_MSR_InitProcedure @Object;
EXECUTE	dbo.sp_MSR_SetVersion @Object, @Version;
GO
ALTER PROCEDURE	rpt.Var_Games
					@L				NVARCHAR(128)	= NULL
				,	@Level			NVARCHAR(128)	= NULL
WITH ENCRYPTION
AS
/*
	Creator:		20221122@Billy
	Location:		DBSABA.SabaDB
	Description:	Variable - Games
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

	/** Process @Level */
	DECLARE	@Column	NVARCHAR(128);

	SELECT	@Column = map.col
	FROM		base.tf_DecodeURL(@Level) AS str
	CROSS APPLY	rpt.tf_GameLevel(str.str) AS map;

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

		SELECT	@Query = CONCAT(N'\
SELECT	DISTINCT
		', @Column, N'
FROM	summary.game_summary_config
;');
		INSERT INTO	@Result (value)
		EXECUTE	base.Query @Query, @_L, 0, 1;
	END;

	SELECT	DISTINCT
			value
	FROM	@Result
	WHERE	value IS NOT NULL
	ORDER BY value;
END;
GO
EXECUTE	rpt.Var_Games @L = '%7B1%2C2%7D';
GO
