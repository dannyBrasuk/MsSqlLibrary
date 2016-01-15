CREATE FUNCTION [App].[fnCalculateProportionalChange]
(
	@Top FLOAT,
	@Bottom FLOAT
)
RETURNS decimal(5,4)
AS
BEGIN
		RETURN
			(
			CASE
				WHEN COALESCE(@Bottom,0) > 0
					THEN CONVERT(decimal(5,4),ROUND(ISNULL(@Top,0)/@Bottom,4))
				ELSE 0
			END
			)
END
/*
--Example

SELECT [App].[fnCalculateProportionalChange] (100,101) AS Proportion;

*/