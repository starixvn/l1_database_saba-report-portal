SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE	SabaDB;
GO
DECLARE	@Object		SYSNAME		= N'rpt.GetGameMetadata'
	,	@Version	SYSNAME		= N'0.0.2'
	;
EXECUTE	dbo.sp_MSR_InitProcedure @Object;
EXECUTE	dbo.sp_MSR_SetVersion @Object, @Version;
GO
ALTER PROCEDURE	rpt.GetGameMetadata
					@L				INT
				,	@Game			NVARCHAR(128)	= NULL	OUTPUT
				,	@GameId			INT				= NULL	OUTPUT
				,	@GameTypeId		INT				= NULL	OUTPUT
				,	@BaseName		NVARCHAR(128)	= NULL	OUTPUT
				,	@Output			BIT				= NULL
WITH ENCRYPTION
AS
/*
	Creator:		20220921@Billy
	Location:		DBSABA.SabaDB
	Description:	
	Version:		0.0.2
	Revision:
		- [0.0.2]	20220921@Billy		Using table type
		- [0.0.1]	20220921@Billy		Initialize
*/
BEGIN;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	IF	COALESCE(@Game, @BaseName) IS NULL AND COALESCE(@GameId, @GameTypeId) IS NULL
		RETURN;

	DECLARE	@Result	rpt.GameMetadata;

	DECLARE	@Query		NVARCHAR(MAX)
		,	@Filter		NVARCHAR(MAX)
		;

	/** Build filter to apply to queries */
	SELECT	@Filter	= CONCAT_WS(CONCAT(NCHAR(13), NCHAR(10), NCHAR(9), N'AND', NCHAR(9))
					, IIF(@Game       IS NULL, NULL, CONCAT(N'nameEN = "'   , @Game      , N'"'))
					, IIF(@GameId     IS NULL, NULL, CONCAT(N'gameId = '    , @GameId  	 , N''))
					, IIF(@GameTypeId IS NULL, NULL, CONCAT(N'gameTypeId = ', @GameTypeId, N''))
					, IIF(@BaseName   IS NULL, NULL, CONCAT(N'coll = "'     , @BaseName  , N'"'))
					)
		,	@Filter = IIF(NULLIF(@Filter, N'') IS NULL, NULL, CONCAT(N'WHERE', NCHAR(9), @Filter))
		;

	SELECT	@Query	= CONCAT_WS(CONCAT(NCHAR(13), NCHAR(10))
					, N'\
SELECT	nameEN, gameId, gameTypeId, coll
FROM	summary.game_summary_config'
					, @Filter);

	INSERT INTO	@Result (Game, GameId, GameTypeId, BaseName)
	EXECUTE	base.Query @Query, @L, 0, 1;

	SELECT	@Game		= Game
		,	@GameId		= GameId
		,	@GameTypeId	= GameTypeId
		,	@BaseName	= BaseName
	FROM	@Result;

	IF	@Output = 1
	BEGIN;
		SELECT	Game, GameId, GameTypeId, BaseName
		FROM	@Result;
	END;
END;
GO
DECLARE	@Game		NVARCHAR(128)
	,	@GameId		INT
	,	@GameTypeId	INT
	,	@BaseName	NVARCHAR(128)
	;
EXECUTE	rpt.GetGameMetadata @L = 1, @Game = 'Big Small', @GameId = @GameId OUTPUT, @GameTypeId = @GameTypeId OUTPUT, @BaseName = @BaseName OUTPUT;
SELECT	[Game] = 'Big Small', [@GameId] = @GameId, [@GameTypeId] = @GameTypeId, [@BaseName] = @BaseName;
GO
DECLARE	@Game		NVARCHAR(128)
	,	@GameId		INT
	,	@GameTypeId	INT
	,	@BaseName	NVARCHAR(128)
	;
EXECUTE	rpt.GetGameMetadata @L = 1, @GameId = 2, @Game = @Game OUTPUT, @GameTypeId = @GameTypeId OUTPUT, @BaseName = @BaseName OUTPUT, @Output = 1;
SELECT	[@Game] = @Game, [GameId] = 2, [@GameTypeId] = @GameTypeId, [@BaseName] = @BaseName;
