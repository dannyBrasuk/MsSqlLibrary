CREATE FUNCTION [App].[fnTokenReassemblyWithoutExcludedTokens]
(
	@TokenCollection App.TokenizerOutput  READONLY
)
RETURNS @ReassembledStrings TABLE 
( 
SourceKey SQL_VARIANT NOT NULL,
ReassembledString NVARCHAR(128) NOT NULL
)
WITH SCHEMABINDING
AS
BEGIN

	/*
		Important assumptions:  
			* Data sets are small enough to allow for non-indexing.  
				(For huge data sets, convert to a proc and substitute indexed tables.)
			* Unneeded tokens have already been flagged via TokensToExclude.
	*/

	;WITH ValidTokens (SourceKey, Token, TokenOrdinal)
	AS
	(
		--This cte is here only to simplify. doesn't help the optimizer or engine
		SELECT SourceKey, Token, TokenOrdinal
		FROM @TokenCollection
		WHERE TokenExcludeFlag=0 
	)
	,rAssemble (SourceKey, ScrubbedString, WordCount, CurrentTokenOrdinal)
	AS
	(
		--anchor to the number 1 position token
		SELECT SourceKey, Token as ScrubbedString, TokenOrdinal, 1
		FROM ValidTokens WHERE TokenOrdinal=1

		UNION ALL

		--recursively stack the valid tokens
		SELECT i.SourceKey, CAST( r.ScrubbedString + ' ' + i.Token AS NVARCHAR(128)), r.WordCount+ 1, i.TokenOrdinal
		FROM ValidTokens i JOIN rAssemble r ON i.SourceKey=r.SourceKey
		WHERE i.TokenOrdinal = r.CurrentTokenOrdinal+1
	)
	,
	ReassembledStrings (SourceKey, ScrubbedString, CompletedStringFlag)
	AS
	(
		--figure out which record has the final and complete stack of all records.
		SELECT 
		SourceKey,
		ScrubbedString,
		ROW_NUMBER() OVER (PARTITION BY SourceKey ORDER BY WordCount DESC) AS CompletedStringFlag
		FROM rAssemble
	)
	INSERT INTO @ReassembledStrings (SourceKey, ReassembledString)
		SELECT SourceKey, ScrubbedString
		FROM ReassembledStrings
		WHERE CompletedStringFlag=1;

	RETURN

END;
/*
--Example

DECLARE @TokenizerOutput AS [App].[TokenizerOutput];

DECLARE  @InputStringsToShred App.TokenizerInput ;

INSERT INTO @InputStringsToShred (SourceKey, SourceString)
    VALUES    (2070794, 'Providence Park'),
              (1119167,'Columbia Heights School (historical)')
                    ;

DECLARE @TokensToExclude TABLE (BadToken NVARCHAR(128) );

INSERT INTO @TokensToExclude(BadToken)
VALUES 	('(HISTORICAL)')
;


INSERT INTO @TokenizerOutput(SourceKey, TokenOrdinal, Token, TokenExcludeFlag )
		SELECT i.SourceKey, o.TokenOrdinal, o.Token , COALESCE((SELECT 1 FROM @TokensToExclude ex WHERE o.Token= ex.BadToken),0)
		FROM @InputStringsToShred i
		JOIN App.fnTokenizeTableOfStrings(@InputStringsToShred) o ON i.Tokenizer_pk = o.Tokenizer_sfk;

SELECT * FROM [App].[fnTokenReassemblyWithoutExcludedTokens](@TokenizerOutput);

*/