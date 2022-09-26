/** Create tyoe */
BEGIN TRY;
	IF	TYPE_ID('rpt.OperatorCurrency_Summary') IS NOT NULL
		DROP TYPE rpt.OperatorCurrency_Summary;

	CREATE TYPE	rpt.OperatorCurrency_Summary AS TABLE (
		operatorId		NVARCHAR(128)
	,	currency		NVARCHAR(10)
	,	tickets			INT
	,	stake			MONEY
	,	payout			MONEY
	,	refund			MONEY
	,	PRIMARY KEY NONCLUSTERED (operatorId, currency)
	) WITH (MEMORY_OPTIMIZED = ON);

END TRY BEGIN CATCH;
	EXECUTE	logger.Error N'Type'
END CATCH;

BEGIN TRY;
	IF	TYPE_ID('rpt.OperatorCurrency_Players') IS NOT NULL
		DROP TYPE rpt.OperatorCurrency_Players;

	CREATE TYPE	rpt.OperatorCurrency_Players AS TABLE (
		operatorId		NVARCHAR(128)
	,	currency		NVARCHAR(10)
	,	players			INT
	,	PRIMARY KEY NONCLUSTERED (operatorId, currency)
	) WITH (MEMORY_OPTIMIZED = ON);
END TRY BEGIN CATCH;
	EXECUTE	logger.Error N'Type'
END CATCH;


/** Create tyoe */
BEGIN TRY;
	IF	TYPE_ID('rpt.TimeCurrency_Summary') IS NOT NULL
		DROP TYPE rpt.TimeCurrency_Summary;

	CREATE TYPE	rpt.TimeCurrency_Summary AS TABLE (
		time			DATETIME
	,	currency		NVARCHAR(10)
	,	tickets			INT
	,	stake			MONEY
	,	payout			MONEY
	,	refund			MONEY
	,	PRIMARY KEY NONCLUSTERED (time, currency)
	) WITH (MEMORY_OPTIMIZED = ON);
END TRY BEGIN CATCH;
	EXECUTE	logger.Error N'Type'
END CATCH;

BEGIN TRY;
	IF	TYPE_ID('rpt.TimeCurrency_Players') IS NOT NULL
		DROP TYPE rpt.TimeCurrency_Players;

	CREATE TYPE	rpt.TimeCurrency_Players AS TABLE (
		time			DATETIME
	,	currency		NVARCHAR(10)
	,	players			INT
	,	PRIMARY KEY NONCLUSTERED (time, currency)
	) WITH (MEMORY_OPTIMIZED = ON);
END TRY BEGIN CATCH;
	EXECUTE	logger.Error N'Type'
END CATCH;


/** Create tyoe */
BEGIN TRY;
	IF	TYPE_ID('rpt.GameCurrency_Summary') IS NOT NULL
		DROP TYPE rpt.GameCurrency_Summary;

	CREATE TYPE	rpt.GameCurrency_Summary AS TABLE (
		gameId			INT
	,	currency		NVARCHAR(10)
	,	tickets			INT
	,	stake			MONEY
	,	payout			MONEY
	,	refund			MONEY
	,	PRIMARY KEY NONCLUSTERED (gameId, currency)
	) WITH (MEMORY_OPTIMIZED = ON);
END TRY BEGIN CATCH;
	EXECUTE	logger.Error N'Type'
END CATCH;

BEGIN TRY;
	IF	TYPE_ID('rpt.GameCurrency_Players') IS NOT NULL
		DROP TYPE rpt.GameCurrency_Players;

	CREATE TYPE	rpt.GameCurrency_Players AS TABLE (
		gameId			INT
	,	currency		NVARCHAR(10)
	,	players			INT
	,	PRIMARY KEY NONCLUSTERED (gameId, currency)
	) WITH (MEMORY_OPTIMIZED = ON);
END TRY BEGIN CATCH;
	EXECUTE	logger.Error N'Type'
END CATCH;
