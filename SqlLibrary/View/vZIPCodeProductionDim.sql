CREATE VIEW [dbo].[vZIPCodeProductionDim]
AS 
SELECT ZIPCode FROM appData.PostalCodeUsaHistoricalMaster





--select latest version
--select next most recent version
--dedect changes
	--centroid of at least N meters
	--area growth/decrease of at least N percent
	--Primary PO name change?

--compute SCD