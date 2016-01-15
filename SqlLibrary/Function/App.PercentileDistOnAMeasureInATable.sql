CREATE FUNCTION [App].[PercentileDistOnAMeasureInATable]
(
		@SourceTable [App].[StatisticsInput] READONLY,
		@EqualBinsIndicator BIT = 0

)
RETURNS @Output TABLE
(
	[Category] SQL_Variant,
	[BinID] INT,
    [BinPercentile] DECIMAL(11,4),
	[DiscreteMeasureAtTopOfBin] FLOAT,
	[CumulativeBinCount] INT
)
AS
BEGIN

/*
	Histogram
	
	Two flavor of binss: 1) Equal size bins (05 % each); 2) Unequal size bins, starting at 1 %.

	Two flavors of output:  pivor or unpivot (depending on what you want to do in Excel)

	(Need to work on optimization. )

*/

DECLARE  @BinID INT,
		 @BinPercentile DECIMAL(5,2);

DECLARE @Bins TABLE
(
	Category [SQL_Variant],
	BinID INT,
	BinPercentile DECIMAL(5,2),
	DiscreteMeasureAtTopOfBin FLOAT
);

/*
	Bin the measure data.

	Stuck with a cursor because PercenBin_Dist can take only a constant as the parameter.
*/
IF @EqualBinsIndicator = 0 

	DECLARE Bin_Cursor CURSOR FOR
			SELECT BinID, BinPercentile	FROM (VALUES	
				    (1 , 0.01),
					(2 , 0.05),
					(3 , 0.10),
					(4 , 0.25),
					(5 , 0.50),
					(6 , 0.75),
					(7 , 0.90),
					(8 , 0.95),
					(9 , 0.99),
					(10, 1.0)
			)  AS t(BinID, BinPercentile)
ELSE
	DECLARE Bin_Cursor CURSOR FOR
			SELECT BinID, BinPercentile FROM (VALUES	
					(1 , 0.05),
					(2 , 0.10),
					(3 , 0.15),
					(4 , 0.20),
					(5 , 0.25),
					(6 , 0.30),
					(7 , 0.35),
					(8 , 0.40),
					(9 , 0.45),
					(10, 0.50),
					(11, 0.55),
					(12, 0.60),
					(13, 0.65),
					(14, 0.70),
					(15, 0.75),
					(16, 0.80),
					(17, 0.85),
					(18, 0.90),
					(19, 0.95),
					(20, 1.0)
			)  AS t(BinID, BinPercentile)
;
OPEN Bin_Cursor;
FETCH NEXT FROM Bin_Cursor INTO @BinID, @BinPercentile
WHILE @@FETCH_STATUS = 0
   BEGIN 

		INSERT INTO @Bins ([Category], BinID, BinPercentile, DiscreteMeasureAtTopOfBin)
			SELECT 
				DISTINCT 
				[Category], 
				@BinID as BinID,
				@BinPercentile AS BinPercentile,
				PERCENTILE_DISC(@BinPercentile) WITHIN GROUP (ORDER BY [Measure]) OVER (PARTITION BY [Category]) AS DiscreteMeasureAtTopOfBin		--Median as specific value in the table
			FROM @SourceTable s;

      FETCH NEXT FROM Bin_Cursor INTO @BinID, @BinPercentile;
   END;
CLOSE Bin_Cursor;
DEALLOCATE Bin_Cursor

/*
	Transform the bins into ranges, in order to get counts within bin
*/
;WITH BinRanges ([Category] , [BinID], [BinPercentile], [LeftDiscreteMeasureAtTopOfBin], [RightDiscreteMeasureAtTopOfBin] )
AS
(
	SELECT  
		[Category] , 
		[BinID], 
		[BinPercentile],
		LAG (DiscreteMeasureAtTopOfBin ,1 , 0 ) OVER (PARTITION BY [Category] ORDER BY [BinID] ) AS [LeftDiscreteMeasureAtTopOfBin],
		DiscreteMeasureAtTopOfBin AS [RightDiscreteMeasureAtTopOfBin]
	FROM   @Bins
)
,BinCounts ([Category], [BinID], [BinCount])
AS
(
	SELECT  
		r.[Category], 
		r.[BinID], 
		COUNT([UniqueSourceKey]) AS [BinCount]
	FROM @SourceTable s JOIN BinRanges r ON s.[Category] = r.[Category] 
	WHERE  s.[Measure] >= r.[LeftDiscreteMeasureAtTopOfBin]   AND  s.[Measure] < r.[RightDiscreteMeasureAtTopOfBin] --- BETWEEN results in double counting
	GROUP BY r.[Category], r.[BinID]
)
INSERT INTO @Output ([Category], [BinID], [BinPercentile], [DiscreteMeasureAtTopOfBin], [CumulativeBinCount])
	SELECT 
		r.[Category] , 
		r.[BinID],	
		r.[BinPercentile],
		r.[RightDiscreteMeasureAtTopOfBin] AS [DiscreteMeasureAtTopOfBin], 
		SUM(c.[BinCount]) OVER (PARTITION BY c.[Category] ORDER BY c.[BinID] ) AS CumulativeBinCount
	FROM BinRanges r JOIN BinCounts c ON r.[Category]=c.[Category] AND r.[BinID]=c.[BinID]
	ORDER BY r.[Category],r.[BinID]
;

RETURN

END

/*
SET NOCOUNT ON;

DECLARE  @SourceTable [App].[StatisticsInput] ;

INSERT INTO @SourceTable
 SELECT [EconCensus_ZIPCode_MultiYears_pk] as UniqueSourceKey,[Survey_Year] as Category, [Paid_employees_for_pay_period] AS Measure
    FROM [EconCensus].[pl].[EconCensus_ZIPCode_MultiYears] 
	WHERE  [Paid_employees_for_pay_period] IS NOT NULL
	ORDER BY [Category], [Measure];

SELECT * FROM  [App].[HistogramInputsOnAMeasureInATable](@SourceTable, DEFAULT);
*/

