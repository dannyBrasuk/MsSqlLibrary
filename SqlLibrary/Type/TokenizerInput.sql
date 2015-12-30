CREATE TYPE [App].[TokenizerInput] AS TABLE 
( 
Tokenizer_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,                
SourceKey SQL_VARIANT NULL UNIQUE,
SourceString  NVARCHAR(128)  NOT NULL
);
