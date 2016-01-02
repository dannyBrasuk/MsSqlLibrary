CREATE TABLE [appdata].[PostalCodeUsaHistoricalMaster]
(
[PostalCodeUsaHistoricalMaster_pk] INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PostalCodeUsaHistoricalMaster PRIMARY KEY,
[CurrentProductionSetFlag]	BIT NOT NULL,				--Indicates the records for a specific year, month, and manufacturer are the current production set
[ZIPCode] NVARCHAR(5) NOT NULL,
[EnclosingZIPCode] NVARCHAR(5) NULL,					--if ZIPCode is a point ZIP
[PostOfficeNamePrimary] NVARCHAR(128) NOT NULL,			--e.g., Vinings, GA
[PostOfficeNameSecondary] NVARCHAR(128) NULL,		--e.g, Atlanta, GA, (aka, Vanity zip)

--Provenance.  (Table will contain history of ZIP Codes, because things change. Therefore,subscription view always need to filter on year.)
[YearManufactured] [NCHAR](4) NOT NULL,						
[MonthManufactured] [NCHAR](2)	NOT NULL CONSTRAINT CHK_PostalCodeUsaHistoricalMaster_MonthManuf CHECK ( [MonthManufactured] LIKE '[0,1][0,1,2,3,4,5,6,7,8,9]'),
[YearMonthManufactured] AS CAST( [YearManufactured] + [MonthManufactured] AS NCHAR(6)),
[ManufacturersName]	NVARCHAR(40) NOT NULL,				--e.g., tom tom, mapinfo, etc.  Substitute foreign key if model supports it
 
--Useful filters
[StatePostalCode] NCHAR(2) NOT NULL,							 
[StateFIPSCode] [NCHAR](2) NOT NULL,
[CountryCodeISO3] [NCHAR](3) NOT NULL CONSTRAINT DF_ZIPCode_Country DEFAULT ('USA'),      --useful in Excel's Power Map
[SCFprefix] AS (CASE WHEN LEFT(ZIPCode,2) <> '00' THEN left(ZIPCode,3) ELSE '' END),		--useful for rolling up to the Sectional Center Facillity

[ZipCodeTypeCode] NCHAR(1) NOT NULL,					--if model does not support code, then substitute the description column
[ZIPCodeTypeDescription]  NVARCHAR(128) NOT NULL,       --e.g., "Regular," PO Box, APO, "Alias ZIP Code for unpopulated area"
[RPOFlag] BIT NULL,
[PointLocationFlag] BIT NULL,

--Quality audit 
[MultiStateLineFlag] BIT NULL,									--Crosses state lines (e.g., Texohma)
[IntendedDisplayMapScale_fk] INT NOT NULL,						--e.g., do not display at scales larger than 1:24,000 (fk =2)
[GeogSRID] AS ([GeogBoundary].[STSrid]),
[GeogAreaInSqrMeters]  AS ([GeogBoundary].[STArea]()) PERSISTED,
[GeogPoints]  AS ([GeogBoundary].[STNumPoints]()),
[GeogType]  AS ([GeogBoundary].[STGeometryType]()),
[GeogWellFormedIndicator]  AS ([GeogBoundary].[STNumGeometries]()),
[GeogIsValid]  AS ([GeogBoundary].[STIsValid]()),

--spatial visualization and filters
[CentroidLongitude]  AS (CONVERT([decimal](14,6),round([GEOGRAPHY]::STGeomFromText([GEOMETRY]::STGeomFromText([GeogBoundary].[STAsText](),(4326)).STCentroid().STAsText(),(4326)).Long,(6)))),
[CentroidLatitude]  AS (CONVERT([decimal](14,6),round([GEOGRAPHY]::STGeomFromText([GEOMETRY]::STGeomFromText([GeogBoundary].[STAsText](),(4326)).STCentroid().STAsText(),(4326)).Lat,(6)))),
[GeogCentroid]  AS ([GEOGRAPHY]::STGeomFromText([GEOMETRY]::STGeomFromText([GeogBoundary].[STAsText](),(4326)).STCentroid().STAsText(),(4326))) PERSISTED,
[GeogBoundary] [geography] NOT NULL

)
ON Secondary;

GO

CREATE NONCLUSTERED INDEX idxPostalCodeUsaHistoricalMaster_subscriptionview 
ON appData.PostalCodeUsaHistoricalMaster
	([YearMonthManufactured])
INCLUDE ([CurrentProductionSetFlag], [ManufacturersName]) 
WITH 
(
	 FILLFACTOR=90
	,PAD_INDEX=ON
	--,DROP_EXISTING=ON
)
ON IndexFileGroup;
GO
CREATE NONCLUSTERED INDEX idxPostalCodeUsaHistoricalMaster_ZIPCodeReference 
ON appData.PostalCodeUsaHistoricalMaster
	([ZIPCode], [CurrentProductionSetFlag])
INCLUDE ([EnclosingZIPCode],[PostOfficeNamePrimary], [ZipCodeTypeCode], [PointLocationFlag],[GeogAreaInSqrMeters], [GeogCentroid], [GeogBoundary]) 
WITH 
(
	 FILLFACTOR=90
	,PAD_INDEX=ON
	--,DROP_EXISTING=ON
)
ON IndexFileGroup;

GO

CREATE SPATIAL INDEX sidx_PostalCodeUsaHistoricalMaster_GeogBoundary
   ON appData.PostalCodeUsaHistoricalMaster([GeogBoundary])
   USING GEOGRAPHY_AUTO_GRID 
   WITH (	
			 FILLFACTOR=90
			,PAD_INDEX = ON
			--,DROP_EXISTING = ON 
		)
	ON IndexFileGroup;
 GO
--spatial centroid, to support nearest neighbor for example

CREATE SPATIAL INDEX sidx_PostalCodeUsaHistoricalMaster_GeogCentroid
   ON appData.PostalCodeUsaHistoricalMaster([GeogCentroid])
   USING GEOGRAPHY_AUTO_GRID 
   WITH (	
			FILLFACTOR=90
			,PAD_INDEX = ON
			--DROP_EXISTING = ON 
		)
	ON IndexFileGroup;
 
 GO
