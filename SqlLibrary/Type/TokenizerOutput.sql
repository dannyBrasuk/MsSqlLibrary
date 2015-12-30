CREATE TYPE [App].[TokenizerOutput] AS TABLE
(
    TokenizerOutput_pk INT NOT NULL IDENTITY(1,1) PRIMARY KEY,                
	SourceKey SQL_VARIANT NULL,
	TokenOrdinal INT NOT NULL,
	Token  NVARCHAR(128)  NOT NULL,
	TokenExcludeFlag BIT DEFAULT (0)
);
