﻿CREATE FUNCTION [App].[fnChangeLocalTimeToUTC]
(
	@LocalDateTime AS DATETIME2
)
RETURNS DATETIME2
AS
BEGIN

    DECLARE @UTCTime DATETIME2 = GETUTCDATE();

    DECLARE @OffsetInHours INT = DATEDIFF(HOUR,@LocalDateTime,@UTCTime);

    DECLARE @ConvertedToUTCTime DATETIME2 = DATEADD(HOUR,@OffsetInHours,@LocalDateTime);

    RETURN @ConvertedToUTCTime 
END;
GO
/*
--Example

SELECT CURRENT_TIMESTAMP as CurrentTime, App.[fnChangeLocalTimeToUTC](CURRENT_TIMESTAMP);


SELECT 'CURRENT_TIMESTAMP', CURRENT_TIMESTAMP
UNION ALL
SELECT 'SYSDATETIME()', SYSDATETIME()
UNION ALL
SELECT 'SYSDATETIMEOFFSET()', SYSDATETIMEOFFSET()
UNION ALL
SELECT 'SYSUTCDATETIME()', SYSUTCDATETIME()
UNION ALL
SELECT 'GETUTCDATE()', GETUTCDATE()

SELECT 'OFFSET', CAST(DATEDIFF(HOUR,CURRENT_TIMESTAMP,GETUTCDATE()) AS VARCHAR(40)) + ' HOURS';


*/