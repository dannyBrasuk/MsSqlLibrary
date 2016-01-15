/*

Extended properties on columns of ZIP Code History Master table.  More needed.

--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

exec sp_addextendedproperty 'MS_Description', 'Unique, point ZIP Codes always are enclosed by a non-unique, boundary ZIPCode','schema', 'appData', 'table', 'PostalCodeUsaHistoricalMaster', 'column', 'EnclosingZIPCode';
exec sp_addextendedproperty 'MS_Description', 'This record belongs to the current product set.','schema', 'appData', 'table', 'PostalCodeUsaHistoricalMaster', 'column', 'CurrentProductionSetFlag';
exec sp_addextendedproperty 'MS_Description', 'Spatial object not intended for display above this scale.','schema', 'appData', 'table', 'PostalCodeUsaHistoricalMaster', 'column', 'IntendedDisplayMapScale_fk';

exec sp_addextendedproperty 'MS_Description', 'A handful of ZIP Codes server two states.','schema', 'appData', 'table', 'PostalCodeUsaHistoricalMaster', 'column', 'MultiStateLineFlag';

--continue with more ext prop

