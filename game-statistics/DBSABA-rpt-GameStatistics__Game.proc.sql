SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

USE	SabaDB;
GO
DECLARE	@Object		SYSNAME		= N'rpt.GameStatistics__Game'
	,	@Version	SYSNAME		= N'0.1.0'
	;
EXECUTE	dbo.sp_MSR_InitProcedure @Object;
EXECUTE	dbo.sp_MSR_SetVersion @Object, @Version;
GO
ALTER PROCEDURE	rpt.GameStatistics__Game
					@TimeFrom		DATETIME		= NULL
				,	@TimeTo			DATETIME		= NULL
				,	@L				NVARCHAR(128)	= NULL
				,	@isRM			NVARCHAR(128)	= NULL
				,	@Operator		NVARCHAR(MAX)	= NULL
				,	@Currency		NVARCHAR(MAX)	= NULL
				,	@Level			NVARCHAR(128)	= NULL
				,	@Game			NVARCHAR(MAX)	= NULL
WITH ENCRYPTION
AS
/*
	Creator:		20220921@Billy
	Location:		DBSABA.SabaDB
	Description:	Game Statistics - Game View
	Version:		0.1.0
	Revision:
		- [0.1.0]	20221123@Billy		Handle dynamic parameters
		- [0.0.3]	20221122@Billy		Combine Ls into 1 result
		- [0.0.2]	20221121@Billy		Add @isRM parameter
		- [0.0.1]	20220921@Billy		Initialize
*/
BEGIN;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	/** Process Variables */ 
	DECLARE	@Ls		rpt.Ls;
	DECLARE	@_L		INT;
	INSERT INTO	@Ls (L)
	SELECT	value
	FROM	base.tf_ParseMultiVariable(@L);

	SELECT	@Operator = STRING_AGG(QUOTENAME(value, '"'), ', ')
	FROM	base.tf_ParseMultiVariable(@Operator);

	SELECT	@Currency = STRING_AGG(QUOTENAME(value, '"'), ', ')
	FROM	base.tf_ParseMultiVariable(@Currency);

	/** Process @Level */
	DECLARE	@Column	NVARCHAR(128);
	SELECT	@Column = map.col
	FROM		base.tf_DecodeURL(@Level) AS str
	CROSS APPLY	rpt.tf_GameLevel(str.str) AS map;

	/** Processing @Game */
	SELECT	@Game = STRING_AGG(QUOTENAME(value, '"'), ', ')
	FROM	base.tf_ParseMultiVariable(@Game);

	DECLARE	@Currencies		rpt.Currencies;
	DECLARE	@ExchangeRates	rpt.ExchangeRates;
	DECLARE	@GameMetadata	rpt.GameMetadata;
	DECLARE	@ResultSummary	rpt.TimeSummary;
	DECLARE	@ResultPlayers	rpt.TimePlayers;

	DECLARE	@Result AS TABLE (
		game			NVARCHAR(128)
	,	gameId			INT
	,	players			INT
	,	tickets			INT
	,	currency		NVARCHAR(128)
	,	stake			DECIMAL(38,19)
	,	win				DECIMAL(38,19)
	,	income			DECIMAL(38,19)
	,	refund			DECIMAL(38,19)
	);

	DECLARE	@Query		NVARCHAR(MAX)
		,	@Filter		NVARCHAR(MAX)
		;

	DECLARE	@GameId		NVARCHAR(MAX)
		,	@RM			BIT
		,	@Rate		DECIMAL(38,19)
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

		/** Get rate */
		SELECT	@RM	= IIF(@isRM = N'yes', 1, 0);

		DELETE	@Currencies;
		SELECT	@Query = N'\
SELECT	name, code, multiplier, partnerId
FROM	minigame.currencies
WHERE	enabled = 1
	AND	isTest = 0';
		INSERT INTO	@Currencies (name, code, multiplier, operatorId)
		EXECUTE	base.Query @Query, @_L, 0, 1;

		DELETE	@ExchangeRates;
		SELECT	@Query = N'\
SELECT	exId, exDate, code, rate, source, time
FROM	minigame.exchange_rates
WHERE	time = ( SELECT	time FROM minigame.exchange_rates ORDER BY time DESC LIMIT 1 )';
		INSERT INTO	@ExchangeRates (exId, exDate, code, rate, source, time)
		EXECUTE	base.Query @Query, @_L, 0, 1;

		SELECT	@Rate = CAST(rate AS DECIMAL(38,9))
		FROM	@ExchangeRates
		WHERE	(@RM = 1 AND code = 'MYR')
			OR	(@RM = 0 AND rate = 1)
		;

		DELETE	@GameMetadata;
		SELECT	@Query = CONCAT(N'\
SELECT	nameEN, gameId, gameTypeId, coll
FROM	summary.game_summary_config', IIF(@Game != '"-"', CONCAT(N'
WHERE	', @Column, N' IN (', @Game, ')'), N''), N';');
		INSERT INTO	@GameMetadata (game, gameId, gameTypeId, baseName)
		EXECUTE	base.Query @Query, @_L, 0, 1;

		IF	@Game != '"-"'
		BEGIN;
			SELECT	@GameId = STRING_AGG(gameId, N', ')
			FROM	@GameMetadata;
		END;

		/** Build filter to apply to queries */
		SELECT	@Filter	= CONCAT_WS(CONCAT(NCHAR(13), NCHAR(10), NCHAR(9), N'AND', NCHAR(9))
						, IIF(NULLIF(@Operator, N'"-"') IS NULL, NULL                , CONCAT(N'operatorId IN (', @Operator, N')'))
						, IIF(NULLIF(@Game, N'"-"')     IS NULL, NULL                , CONCAT(N'gameId IN ('    , @GameId  , N')'))
						, IIF(@TimeFrom                 IS NULL, NULL                , CONCAT(N'time >= "'      , CONVERT(NVARCHAR(MAX), @TimeFrom, 127), N'"'))
						, IIF(@TimeTo                   IS NULL, NULL                , CONCAT(N'time < "'       , CONVERT(NVARCHAR(MAX), @TimeTo  , 127), N'"'))
						, IIF(NULLIF(@Currency, N'"-"') IS NULL, N'currency <> "UUS"', CONCAT(N'currency IN ('  , @Currency, N')'))
						)
			,	@Filter = IIF(NULLIF(@Filter, N'') IS NULL, NULL, CONCAT(N'WHERE	', @Filter))
			;

		DELETE	@ResultSummary;
		SELECT	@Query	= CONCAT_WS(CONCAT(NCHAR(13), NCHAR(10))
						, N'\
SELECT	time, currency, gameId, isCash, operatorId, tickets, stake, payout, refund
FROM	summary.daily_summaries'
						, @Filter
						);
		INSERT INTO	@ResultSummary (time, currency, gameId, isCash, operatorId, tickets, stake, payout, refund)
		EXECUTE	base.Query @Query, @_L, 0, 1;

		DELETE	@ResultPlayers;
		SELECT	@Query	= CONCAT_WS(CONCAT(NCHAR(13), NCHAR(10))
						, N'\
SELECT	time, currency, gameId, isCash, operatorId, playerId
FROM	summary.daily_players'
						, @Filter
						);
		INSERT INTO	@ResultPlayers (time, currency, gameId, isCash, operatorId, playerId)
		EXECUTE	base.Query @Query, @_L, 0, 1;

		INSERT INTO	@Result (game, gameId, players, tickets, currency, stake, win, income, refund)
		SELECT	rs.game, rs.gameId, rp.players, rs.tickets, rs.currency, rs.stake, rs.win, rs.income, rs.refund
		FROM	(
			SELECT	[game]		= g.game
				,	[gameId]	= s.gameId
				,	[tickets]	= SUM(s.tickets)
				,	[currency]	= c.currency
				,	[stake]		= ROUND(SUM(c.stake), 4)
				,	[win]		= ROUND(SUM(c.payout), 4)
				,	[income]	= ROUND(SUM(c.stake) - SUM(c.payout), 4)
				,	[refund]	= ROUND(SUM(c.refund), 4)
			FROM		@ResultSummary AS s
			OUTER APPLY	(
				SELECT	TOP(1)
						[multiplier] = _c.multiplier
				FROM	@Currencies AS _c
				WHERE	_c.operatorId = s.operatorId
					AND	_c.name = s.currency
			) AS e
			CROSS APPLY	(
				SELECT	[currency]	= IIF(@RM = 1, N'RM', s.currency)
					,	[stake]		= s.stake / @Rate * ISNULL(e.multiplier, 1)
					,	[payout]	= s.payout / @Rate * ISNULL(e.multiplier, 1)
					,	[refund]	= s.refund / @Rate * ISNULL(e.multiplier, 1)
			) AS c
			INNER JOIN	@GameMetadata AS g
					ON	g.gameId = s.gameId
			GROUP BY g.game, s.gameId, c.currency
		) AS rs
		CROSS APPLY	(
			SELECT	[players]	= COUNT(DISTINCT p.playerId)
			FROM		@ResultPlayers AS p
			CROSS APPLY	(
				SELECT	[currency]	= IIF(@RM = 1, N'RM', p.currency)
			) AS c
			WHERE	p.gameId = rs.gameId
				AND	c.currency = rs.currency
		) AS rp
		;
	END;

	SELECT	[#]				= gameId
		,	[Game]			= game
		,	[No. Players]	= SUM(players)
		,	[Bet Count]		= SUM(tickets)
		,	[Currency]		= currency
		,	[Total Bets]	= SUM(stake)
		,	[Total Win]		= SUM(win)
		,	[Game Income]	= SUM(income)
		,	[Game Payout]	= SUM(win) / SUM(stake)
		,	[Total Refund]	= SUM(refund)
	FROM	@Result
	GROUP BY gameId, game, currency
	ORDER BY gameId, game, currency;
END;
GO
DECLARE	@Today		DATE	= GETUTCDATE()
	,	@Yesterday	DATE	= GETUTCDATE() - 1
EXECUTE	rpt.GameStatistics__Game @L = '%7B1%2C2%7D', @TimeFrom = @Yesterday, @TimeTo = @Today;
GO
DECLARE	@Today		DATE		= GETUTCDATE()
	,	@Now		DATETIME	= GETUTCDATE()
EXECUTE	rpt.GameStatistics__Game @L = '%7B1%2C2%7D', @TimeFrom = @Today, @TimeTo = @Now;
GO
