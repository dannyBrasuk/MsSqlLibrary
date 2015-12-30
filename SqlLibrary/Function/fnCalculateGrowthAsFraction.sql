CREATE FUNCTION [App].[fnCalculateGrowthAsFraction]
(
	@Previous FLOAT,
	@Current FLOAT

)
RETURNS decimal(5,4)
AS
BEGIN
		RETURN
			(
			CASE
				WHEN COALESCE(@Previous,0) > 0
					THEN CONVERT(decimal(8,4), ROUND( ((ISNULL(@Current,0)-@Previous) / @Previous),4))
				ELSE 0
			END
			)
END

/*
--Example

SELECT [App].[fnCalculateGrowthAsFraction] (100,101);

*/