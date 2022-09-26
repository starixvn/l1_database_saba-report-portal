/** Create tyoe */
BEGIN TRY;
	IF	TYPE_ID('rpt.GameMetadata') IS NOT NULL
		DROP TYPE rpt.GameMetadata;

	CREATE TYPE	rpt.GameMetadata AS TABLE (
		game		NVARCHAR(128)
	,	gameId		INT
	,	gameTypeId	INT
	,	baseName	NVARCHAR(128)
	,	PRIMARY KEY NONCLUSTERED (gameId)
	) WITH (MEMORY_OPTIMIZED = ON);

END TRY BEGIN CATCH;
	EXECUTE	logger.Error N'Type'
END CATCH;
