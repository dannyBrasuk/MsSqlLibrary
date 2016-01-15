CREATE FUNCTION [App].[StatisticsOnAMeasureInATable]
(
    @SourceTable [App].[StatisticsInput] READONLY
)
RETURNS TABLE AS RETURN
(
/*
	Data Profiling

	Older versions of SQL lacked basic statistical functions such as Std Dev. Median still is missing.
	Use this function to return statisitcs on a "measure" (e.g., numeric) column in a table.
	Optionally supply a category (e.g., group by) for breaking down the statistics.

	The biggest "cost" is loading the source table type. Could probably restructure the whole thing as 
	an Execute_SQL, with the parameters being the table and column names.


*/

	WITH [Median] ([Category], [MedianValue])
	AS
	(
		SELECT  
			[Category],
			AVG([Measure]) AS [MedianValue]
		FROM
		(
		   SELECT
				[Category],
				[Measure],
				ROW_NUMBER() OVER (PARTITION BY [Category] ORDER BY [Measure]) AS RowNum,
				COUNT(*) OVER (PARTITION BY [Category]) AS RowCnt
		   FROM  @SourceTable
		) x
		WHERE RowNum IN ((RowCnt + 1) / 2, (RowCnt + 2) / 2)
		GROUP BY [Category]
	)
	, [Mean] ([Category], [CountOf], [MinimumMeasure], [MaximumMeasure], [MeanValue])
	AS 
	(
		SELECT	[Category], 
				COUNT([UniqueSourceKey]) AS CountOf,
				MIN([Measure]) AS MinimumMeasure,
				MAX([Measure]) AS MaximumMeasure,
				SUM([Measure]) / COUNT([UniqueSourceKey]) AS [MeanValue]
		FROM  @SourceTable
		GROUP BY [Category]
	)
	,[Variance] ([Category], [CountOf], [MinimumMeasure], [MaximumMeasure], [MeanValue], [Variance])
	AS 
	(
		SELECT	m.[Category], 
				m.[CountOf], m.[MinimumMeasure], m.[MaximumMeasure],
				--squared deviations from the mean
				m.[MeanValue], POWER([Measure] - [MeanValue], 2) AS [Variance] 
		FROM @SourceTable x CROSS JOIN [Mean] m
		WHERE x.[Category] = m.[Category]
	)
	,
	StdDev ([Category],[StdDev])
	AS
	(
	SELECT	v.[Category],
			--square root of expected value of variance
			SQRT(SUM(v.[Variance]) / COUNT(v.[Variance])) AS [StdDev]		
	FROM [Variance] v
	GROUP BY v.[Category], v.[MeanValue]

	)
	SELECT	a.[Category],
			a.[CountOf],
			a.[MinimumMeasure] AS [Minimum], 
 			b.MedianValue AS [Median],
			a.[MaximumMeasure] AS [Maximum],
			a.[MeanValue] as [Mean],
			c.[StdDev]		
	FROM [Mean] a JOIN [Median] b ON a.[Category]=b.[Category] JOIN [StdDev] c ON b.[Category]=c.[Category]
);

/*

DECLARE  @SourceTable [App].[StatisticsInput] ;

DECLARE @MaxKey INT = (SELECT MAX([EconCensus_ZIPCode_MultiYears_pk]) FROM [EconCensus].[pl].[EconCensus_ZIPCode_MultiYears] );

INSERT INTO @SourceTable
 SELECT [EconCensus_ZIPCode_MultiYears_pk] as UniqueSourceKey,[Survey_Year] as Category, [Paid_employees_for_pay_period] AS Measure
    FROM [EconCensus].[pl].[EconCensus_ZIPCode_MultiYears] 
	WHERE  [Paid_employees_for_pay_period] IS NOT NULL
UNION ALL
 SELECT @MaxKey+ [EconCensus_ZIPCode_MultiYears_pk] as UniqueSourceKey, 'All Years' as Category, [Paid_employees_for_pay_period] AS Measure
    FROM [EconCensus].[pl].[EconCensus_ZIPCode_MultiYears] 
	WHERE  [Paid_employees_for_pay_period] IS NOT NULL;

SELECT [Category],  [CountOf], [Minimum], [Maximum], CAST(ROUND( [Median],0) AS INT) AS Median, CAST(ROUND([Mean],0) AS INT) AS [Mean], CAST(ROUND([StdDev],0) AS INT) AS StdDev_pop
FROM [App].StatisticsOnAMeasureInATable(@SourceTable)
ORDER BY [Category];


--Yields

Category	CountOf	Minimum	Maximum	Median	Mean	StdDev_pop
2007		30359	1		158580	636		3787	7610
2008		30106	1		151403	649		3827	7669
2009		29968	1		146911	619		3639	7276
2010		29934	1		142950	612		3556	7082
2011		29747	1		145364	617		3617	7224
All Years	150114	1		158580	626		3686	7378


*/