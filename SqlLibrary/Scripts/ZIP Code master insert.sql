Use EconCensus;
GO
SET STATISTICS IO ON;
SET ROWCOUNT 0;
GO

/* 

	IDL for ZIP Code History table.

	Notes:
	
	1. The seed data set seems to be missing enclosed (point) ZIP Codes.
	2. Also, the alias name needs to be built. 
	3. County overlap disgarded.  Recreate with bridge table (and include percent overlap).

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
           ,[RPOFlag]
           ,[PointLocationFlag]
		   ,[MultiStateLineFlag]
           ,[IntendedDisplayMapScale_fk]
           ,[GeogBoundary])

SELECT
	1 AS [CurrentProductionSetFlag]			--reset as new editions accumulated
	,[ZIP]
    ,CASE WHEN [Enc_ZIP] = '' THEN NULL ELSE [Enc_ZIP] END
	,[Name] + ', ' + [St], NULL
	,'2004', '11', 'GDT (Tom Tom)'
	,[St], [St_FIPS], 'USA'
	,[ZipType]
	,CASE 
			WHEN [ZipType] = 'N' THEN 'Non-unique (regular boundary)'
			WHEN [ZipType] = 'U' THEN 'Unique'
			WHEN [ZipType] = 'P' THEN 'PO (no boundary'
			WHEN [ZipType] = 'G' THEN 'Alias ZIP Code for area with no delivery service (unpopulated)'
	END		
	,CASE WHEN [RPO_Flag] = '' THEN 0 ELSE 1 END 		--did my data load correctly?
	,CASE WHEN [Pt_loc] ='' THEN 0 ELSE 1 END
	,0 AS [MultiStateLineFlag]							--Assume false on initial load
	,2 AS [IntendedDisplayMapScale_fk]					--1:24000 (I think)
    ,[SP_GEOMETRY]
FROM [stage].[uszipreg]		--nov 2004

GO
SELECT TOP (600) *
FROM [appData].[PostalCodeUsaHistoricalMaster]
ORDER BY NEWID();

GO

--SELECT RPO_Flag, Count(*) from [stage].[uszipreg] GROUP BY RPO_Flag;
--SELECT [Pt_loc], Count(*)  from [stage].[uszipreg] GROUP BY [Pt_loc];
--SELECT [ZipType],[Pt_loc],  Count(*)  from [stage].[uszipreg] GROUP BY [ZipType], [Pt_loc];



EXEC sp_rename '[stage].[uszipreg]', '[uszipreg200411]';
