SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE	SabaDB;
GO
DECLARE	@Object		SYSNAME		= N'rpt.GameStatistics_Operator'
	,	@Version	SYSNAME		= N'0.0.1'
	;
EXECUTE	dbo.sp_MSR_InitProcedure @Object;
EXECUTE	dbo.sp_MSR_SetVersion @Object, @Version;
GO
ALTER PROCEDURE	rpt.GameStatistics_Operator
					@L				INT
				,	@Operator		NVARCHAR(128)	= NULL
				,	@Game			NVARCHAR(128)	= NULL
				,	@TimeFrom		DATETIME		= NULL
				,	@TimeTo			DATETIME		= NULL
				,	@Currency		NVARCHAR(10)	= NULL
WITH ENCRYPTION
AS
/*
	Creator:		20220921@Billy
	Location:		DBSABA.SabaDB
	Description:	Game Statistics - Operator View
	Version:		0.0.1
	Revision:
		- [0.0.1]	20220921@Billy		Initialize
*/
BEGIN;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	EXECUTE	base.Wait 2;

	DECLARE	@ResultSummary	rpt.OperatorCurrency_Summary;
	DECLARE	@ResultPlayers	rpt.OperatorCurrency_Players;

	DECLARE	@Query		NVARCHAR(MAX)
		,	@Filter		NVARCHAR(MAX)
		;

	DECLARE	@GameId		INT
		;

	/** Get @gameId from @Game */
	EXECUTE	rpt.GetGameMetadata @L = @L, @Game = @Game, @GameId = @GameId OUTPUT;

	/** Build filter to apply to queries */
	SELECT	@Filter	= CONCAT_WS(CONCAT(NCHAR(13), NCHAR(10), NCHAR(9), N'AND', NCHAR(9))
					, IIF(@Operator IS NULL, NULL, CONCAT(N'operatorId = "', @Operator, N'"'))
					, IIF(@GameId   IS NULL, NULL, CONCAT(N'gameId = "'    , @GameId  , N'"'))
					, IIF(@TimeFrom IS NULL, NULL, CONCAT(N'time >= "'     , CONVERT(NVARCHAR(MAX), @TimeFrom, 127), N'"'))
					, IIF(@TimeTo   IS NULL, NULL, CONCAT(N'time < "'      , CONVERT(NVARCHAR(MAX), @TimeTo  , 127), N'"'))
					, IIF(@Currency IS NULL, NULL, CONCAT(N'currency = "'  , @Currency, N'"'))
					)
		,	@Filter = IIF(NULLIF(@Filter, N'') IS NULL, NULL, CONCAT(N'WHERE	', @Filter))
		;

	SELECT	@Query	= CONCAT_WS(CONCAT(NCHAR(13), NCHAR(10))
					, N'\
SELECT	operatorId		AS "operatorId"
	,	currency		AS "currency"
	,	SUM(tickets)	AS "tickets"
	,	SUM(stake)		AS "stake"
	,	SUM(payout)		AS "payout"
	,	SUM(refund)		AS "refund"
FROM	summary.daily_summaries'
					, @Filter
					, N'\
GROUP BY operatorId, currency'
					);
	INSERT INTO	@ResultSummary (operatorId, currency, tickets, stake, payout, refund)
	EXECUTE	base.Query @Query, @L, 0, 1;

	SELECT	@Query	= CONCAT_WS(CONCAT(NCHAR(13), NCHAR(10))
					, N'\
SELECT	operatorId					AS "operatorId"
	,	currency					AS "currency"
	,	COUNT(DISTINCT playerId)	AS "players"
FROM	summary.daily_players'
					, @Filter
					, N'\
GROUP BY operatorId, currency'
					);
	INSERT INTO	@ResultPlayers (operatorId, currency, players)
	EXECUTE	base.Query @Query, @L, 0, 1;

	SELECT	[operator]	= s.operatorId
		,	[players]	= p.players
		,	[tickets]	= s.tickets
		,	[currency]	= s.currency
		,	[stake]		= s.stake
		,	[win]		= s.payout
		,	[income]	= s.stake - s.payout
		,	[payout]	= s.payout / s.stake
		,	[refund]	= s.refund
	FROM		@ResultSummary AS s
	INNER JOIN	@ResultPlayers AS p
			ON	s.operatorId = p.operatorId
			AND	s.currency = p.currency
	WHERE	s.currency <> N'UUS'
	ORDER BY s.operatorId, s.currency
	;
END;
GO
DECLARE	@Today		DATE	= GETUTCDATE()
	,	@Yesterday	DATE	= GETUTCDATE() - 1
EXECUTE	rpt.GameStatistics_Operator @L = 1, @TimeFrom = @Yesterday, @TimeTo = @Today;
GO
DECLARE	@Today		DATE		= GETUTCDATE()
	,	@Now		DATETIME	= GETUTCDATE()
EXECUTE	rpt.GameStatistics_Operator @L = 1, @TimeFrom = @Today, @TimeTo = @Now;
GO
