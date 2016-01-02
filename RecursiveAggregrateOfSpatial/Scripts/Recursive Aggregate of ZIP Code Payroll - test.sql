Use EconCensus
GO
SET STATISTICS IO ON;
 
GO
--Spatial table is the raw one, straight from easy loader. fine for this purpose 
--just do default, to activate nearest neigbor
--CREATE SPATIAL INDEX SIndx_uszipreg_geography
--   ON [stage].[uszipreg] ([SP_GEOMETRY]);

--oops ZIP Codes are in NAD 83!  SRID 4269

DECLARE @MyLocation geography = geography::Point(33.96, -84.45, 4269);  

--Make a buffer for a refernce point
DECLARE @ReferenceObject geography = @MyLocation.STBuffer(750);

DECLARE @PayrollTarget INT = 15000000,		--minimim payroll needed
		@TopN INT = 1000,
		@MaximiumDistance FLOAT = 100000,	--in meters
		@SurveyYear NCHAR(4) = '2011'
;
----No longer needed.  just use candidate number 1 to anchor the recursive call 
DECLARE @AnchorZIPCode VARCHAR(5) =		/* type matches the ZIP table */
		(SELECT  z.ZIP
		FROM    [EconCensus].[stage].[uszipreg] z
		WHERE	z.[SP_GEOMETRY].STContains(@MyLocation)=1
				AND z.ZipType='N'
		);

--Candidates ZIPCodes, by distance from target point. Limit the set.
;WITH CandidateZIPCodes (PointID, ZIPCode, DistanceInMeters, CandidateRowNumber, ZIPCodePayroll, ZIPCentroidLat, ZIPCentroidLong)
AS
(
	SELECT  TOP (@TopN) 1 AS PointID,		--required with orderby
			CAST(z.ZIP AS NVARCHAR(5)), 

			--elements needed for recursion
			CAST(ROUND(z.SP_GEOMETRY.STDistance(@MyLocation),1) AS INT),
			ROW_NUMBER() OVER( ORDER BY z.SP_GEOMETRY.STDistance(@MyLocation)) as CandidateRowNumber,
			d.Annual_payroll_1000,

			--for spokes
			geometry::STGeomFromWKB(z.SP_GEOMETRY.STAsBinary(),4269).STCentroid().STY AS ZIPCentroidLat,
			geometry::STGeomFromWKB(z.SP_GEOMETRY.STAsBinary(),4269).STCentroid().STX AS ZIPCentroidLong

	FROM    [EconCensus].[stage].[uszipreg] z 
				WITH (INDEX ( SIndx_uszipreg_geography ))
	JOIN [EconCensus].[pl].[EconCensus_ZIPCode_MultiYears] d ON z.ZIP = d.ZIPCode  AND d.Survey_Year=@SurveyYear
	WHERE	SP_GEOMETRY.STDistance(@MyLocation) IS NOT NULL
			AND SP_GEOMETRY.STDistance(@MyLocation) < @MaximiumDistance
	ORDER BY SP_GEOMETRY.STDistance(@MyLocation)
)
-- hub and spoke map, to illustrate the results (alternaive to zip boundaries)
, Spokes (PointID, ZIPCode, CandidateRowNumber, Spoke)
AS
(
	SELECT  
		PointID,
		ZIPCode,
		CandidateRowNumber,
		geography::STLineFromText('LINESTRING(' 
								+ CAST(@MyLocation.Long AS VARCHAR) + ' ' + CAST(@MyLocation.Lat AS VARCHAR) + ', '
								+ CAST(ZIPCentroidLong AS VARCHAR) + ' ' + CAST(ZIPCentroidLat AS VARCHAR) +')'
							, 4269) As Spoke				
	FROM CandidateZIPCodes
)
--recursive call to aggregate ZIP payroll, walking zip codes by distance from target point
, recursiveAggregate (PointID, ZIPCode, DistanceInMeters, ZIPCodePayroll, AggPayroll, MaxCandidateRowNumber)
AS
(
	--anchor to the nearest ZIP Code (which likely is the enclosing ZIP Code.
	SELECT PointID, ZIPCode, DistanceInMeters, ZIPCodePayroll, ZIPCodePayroll as AggPayroll, CandidateRowNumber as MaxCandidateRowNumber
	FROM    CandidateZIPCodes 
	WHERE CandidateRowNumber=1

	UNION ALL

	--step through ZIP Codes in order of proximity, aggregating as we go
	SELECT  c.PointID, c.ZIPCode, c.DistanceInMeters, c.ZIPCodePayroll, r.AggPayroll+c.ZIPCodePayroll, c.CandidateRowNumber
	FROM    CandidateZIPCodes c 
			JOIN recursiveAggregate r ON r.PointID=c.PointID
	WHERE	c.CandidateRowNumber=r.MaxCandidateRowNumber+1 
			AND
			r.AggPayroll+c.ZIPCodePayroll < @PayrollTarget
)
--choice of maps to review
,Report
AS
(
	SELECT 1 as PointID, @AnchorZIPCode AS ZIPCode, NULL as POName, 0 as DistanceInMeters, NULL as ZIPCodePayroll, NULL as AggPayroll, 1 AS CandidateRowNumber, @ReferenceObject AS MapObject, 1 as MapChoice
		UNION ALL
	SELECT r.PointID, r.ZIPCode, z.ST + ' ' + z.Name AS POName, DistanceInMeters, r.ZIPCodePayroll, r.AggPayroll, MaxCandidateRowNumber, z.SP_GEOMETRY, 2
	FROM recursiveAggregate r
	JOIN [EconCensus].[stage].[uszipreg] z ON r.ZIPCode=z.ZIP
		UNION ALL
	SELECT 1 as PointID, s.ZIPCode AS ZIPCode, NULL as POName, r.DistanceInMeters, r.ZIPCodePayroll, r.AggPayroll, CandidateRowNumber, Spoke.STBuffer(100), 3
	FROM Spokes s JOIN recursiveAggregate r ON r.ZIPCode = s.ZIPCode
)
SELECT *
FROM Report
WHERE MapChoice in (1,3)
ORDER BY DistanceInMeters
;