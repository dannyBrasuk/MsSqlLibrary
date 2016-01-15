CREATE FUNCTION [App].[fnRemoveNonASCII]
(
    @nString NVARCHAR(255)
)
RETURNS NVARCHAR(255)
AS
BEGIN

    DECLARE @Result NVARCHAR(255) = '',
			@nchar NVARCHAR(1),
			@position INT = 1;

    WHILE @position <= LEN(@nString)
    BEGIN

        SET @nchar = SUBSTRING(@nString, @position, 1);

        --Unicode & ASCII are the same from 1 to 255.
        --Only Unicode goes beyond 255
        --0 to 31 are non-printable characters

        IF UNICODE(@nchar) BETWEEN 32 AND 127
            SET @Result = @Result + @nchar;

        SET @position = @position + 1
    END

    RETURN @Result

END

/*
--Example
 
SELECT  [App].[fnRemoveNonASCII] ('¡aæã!');

*/
 
