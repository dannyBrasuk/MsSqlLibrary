Use EconCensus;
GO
SET STATISTICS IO ON;
SET ROWCOUNT 500;

GO
DECLARE @MyLocation geography = geography::Point(33.96, -84.45, 4269);  

DECLARE	@TopN INT = 10,
		@MaximiumDistance FLOAT = 100000	--in meters
;

--Candidates ZIPCodes, by distance from target point. Limit the set.
;WITH CandidateZIPCodes (PointID, ZIPCode, DistanceInMeters, ZIPGeog)
AS
(
	SELECT  TOP (@TopN) 1 AS PointID,		--required with orderby
			CAST(z.ZIP AS NVARCHAR(5)), 
			CAST(ROUND(z.SP_GEOMETRY.STDistance(@MyLocation),1) AS INT),
			z.SP_GEOMETRY
	FROM    [EconCensus].[stage].[uszipreg] z 
				 WITH (INDEX ( SIndx_uszipreg_geography ))
	WHERE	SP_GEOMETRY.STDistance(@MyLocation) IS NOT NULL
			AND SP_GEOMETRY.STDistance(@MyLocation) < @MaximiumDistance
	ORDER BY SP_GEOMETRY.STDistance(@MyLocation)
)
--Compute shared border
, SharedEdges (ZIPCode_a, ZIPCode_b, DistanceInMeters, SharedEdge, SharedLengthInMeters, SharedEdgeRank)
AS
(
	SELECT  
		a.ZIPCode as ZIPCode_a, 
		b.ZIPCode as ZIPCode_b,
		a.DistanceInMeters,
	    a.ZIPGeog.STIntersection(b.ZIPGeog) AS SharedEdge,
		a.ZIPGeog.STIntersection(b.ZIPGeog).STLength() as SharedLengthInMeters,
		ROW_NUMBER() OVER (PARTITION BY a.ZIPCode ORDER BY a.ZIPGeog.STIntersection(b.ZIPGeog).STLength() DESC ) AS SharedEdgeRank
	FROM CandidateZIPCodes a CROSS JOIN CandidateZIPCodes b
	WHERE a.ZIPCode <> b.ZIPCode
			AND a.ZIPGeog.STIntersects(b.ZIPGeog)=1
)
SELECT	Zipcode_a, ZIPCode_b,
		DistanceInMeters,
		CAST(ROUND(SharedLengthInMeters,0) AS INT) AS SharedLengthInMeters,
		--SharedEdgeRank,
		NULL--SharedEdge
FROM SharedEdges
WHERE SharedEdgeRank=1
--UNION ALL
--SELECT ZIPCode, NULL, NULL, NULL
--			,geometry::STGeomFromWKB(ZIPGeog.STAsBinary(),4269).STCentroid().STBuffer(750)
--FROM CandidateZIPCodes
ORDER BY DistanceInMeters 
;





