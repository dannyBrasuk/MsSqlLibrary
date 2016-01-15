Use EconCensus;
GO
SET STATISTICS IO ON;
SET ROWCOUNT 0;
GO

/* 

	Second test insert for ZIP Code History table, using 2012 12 file

	Notes:
	
	1. The seed data set seems to be missing enclosed (point) ZIP Codes.
	2. Also, the alias name needs to be built. 
	3. County overlap disgarded.  Recreate with bridge table (and include percent overlap).
	4. Point ZIP code flags not here

*/

INSERT INTO [appData].[PostalCodeUsaHistoricalMaster]
           ([CurrentProductionSetFlag]
           ,[ZIPCode]
           ,[EnclosingZIPCode]
           ,[PostOfficeNamePrimary]
           ,[PostOfficeNameSecondary]
           ,[YearManufactured]
           ,[MonthManufactured]
           ,[ManufacturersName]
           ,[StatePostalCode]
           ,[StateFIPSCode]
           ,[CountryCodeISO3]
           ,[ZipCodeTypeCode]
		   ,[ZIPCodeTypeDescription]
     --      ,[RPOFlag]
     --      ,[PointLocationFlag]
		   --,[MultiStateLineFlag]
           ,[IntendedDisplayMapScale_fk]
           ,[GeogBoundary])

SELECT 
	0 AS [CurrentProductionSetFlag]			--reset as new editions accumulated
	,[ZIP]
    ,CASE WHEN [Enclosing_ZIP] = '' THEN NULL ELSE [Enclosing_ZIP] END
	,[Name] + ', ' + [State], NULL
	,'2012', '12', 'Tom Tom'
	,[State], [State_FIPS], 'USA'
	,'' AS [ZipType], 'Undefined'	
	--,CASE WHEN [RPO_Flag] = '' THEN 0 ELSE 1 END 		--did my data load correctly?
	--,CASE WHEN [Pt_loc] ='' THEN 0 ELSE 1 END
	--,0 AS [MultiStateLineFlag]							--Assume false on initial load
	,2 AS [IntendedDisplayMapScale_fk]					--1:24000 (I think)
    ,[SP_GEOMETRY]
FROM [stage].[USZIPREG201212NAD83]
GO
SELECT TOP (600) *
FROM [appData].[PostalCodeUsaHistoricalMaster]
WHERE [YearManufactured]='2012'
ORDER BY NEWID();