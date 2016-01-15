CREATE TYPE [App].[StatisticsInput] AS TABLE
(
	[StatisticsInput_pk] [INT] IDENTITY(1,1) NOT NULL,
	[UniqueSourceKey] [SQL_VARIANT] NOT NULL UNIQUE NONCLUSTERED ,
	[Category] [SQL_VARIANT] NOT NULL DEFAULT (1),
	[Measure] [FLOAT] NOT NULL,
	PRIMARY KEY CLUSTERED ([Category], [UniqueSourceKey])
);
