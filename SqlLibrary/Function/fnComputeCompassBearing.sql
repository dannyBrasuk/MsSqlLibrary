CREATE FUNCTION [App].[fnComputeBearingBetweenCoordinates]
(
	@p_dE1 Float, @p_dN1 Float, @p_dE2 Float, @p_dN2 Float
)
RETURNS Float
AS
BEGIN

	/*

	This function does (B)

	Per Wikipedia:

	Per Wikipedia:

	"Bearing" is a term used in navigation to refer, depending on the context, to either 
	(A) the direction of motion, 
	or, 
	(B) the direction of a distant object relative to the current course (or the "change" in course that would be needed to get to that distant object), 
	or 
	(C), the degrees away from North of a distant point relative to the current point.


	In navigation, absolute bearing refers to the angle between the magnetic North (magnetic bearing) or true North (true bearing) and an object. 
	For example, an object to the East would have an absolute bearing of 90 degrees. Relative bearing refers to the angle between the craft's forward direction, 
	and the location of another object. For example, an object relative bearing of 0 degrees would be dead ahead; an object relative bearing 180 degrees would be behind.
	
	Bearings can be measured in mils or degrees.


	*/

    DECLARE
        @dBearing Float,
        @dEast    Float,
        @dNorth   Float;

    BEGIN

        If (@p_dE1 IS NULL OR
            @p_dN1 IS NULL OR
            @p_dE2 IS NULL OR
            @p_dE1 IS NULL ) 
           Return NULL;
 
        If ( (@p_dE1 = @p_dE2) AND 
             (@p_dN1 = @p_dN2) ) 
           Return NULL;
 
        SET @dEast  = @p_dE2 - @p_dE1;
        SET @dNorth = @p_dN2 - @p_dN1;

        If ( @dEast = 0 ) 
			Begin
				If ( @dNorth < 0 ) 
					SET @dBearing = PI();
				Else
					SET @dBearing = 0;
			End
        Else
            SET @dBearing = -aTan(@dNorth / @dEast) + PI() / 2.0;
             
        If ( @dEast < 0 ) 
            SET @dBearing = @dBearing + PI();
 
        RETURN @dBearing;
    END
END;
/*
--Here are some examples.

--*** Test invalid input.

SELECT App.fnComputeBearingBetweenCoordinates(0,0,0,0) as Bearing;
----Expected output
--Bearing
--NULL 

--*** To convert result to degrees use built-in DEGREES ( ) function

SELECT DEGREES(App.fnComputeBearingBetweenCoordinates(0,0,45,45)) as Bearing;
----Expected output
--Bearing
--45 

--***Or, more relevantly to Spatial users:

DECLARE
   @pt1 geometry = geometry::STGeomFromText('POINT(0 0)',0),
   @pt2 geometry = geometry::STGeomFromText('POINT(-45 45)',0); 

BEGIN

SELECT DEGREES(App.fnComputeBearingBetweenCoordinates(  
									 @pt1.STX, @pt1.STY, 
									 @pt2.STX, @pt2.STY)) as Bearing;
END
----Expected output
--Bearing
--315 

DECLARE
   @Roswell geometry = geometry::STGeomFromText('POINT(-84.361549 34.022003)',0),
   @Marietta geometry = geometry::STGeomFromText('POINT(-84.55 33.9525)',0); 

BEGIN
SELECT App.fnComputeBearingBetweenCoordinates(@Marietta.STX, @Marietta.STY, @Roswell.STX, @Roswell.STY ) AS BEARING, 'Unconverted' as Converted
UNION ALL
SELECT DEGREES(App.fnComputeBearingBetweenCoordinates(@Marietta.STX, @Marietta.STY, @Roswell.STX, @Roswell.STY)), 'compass bearing in degrees';
END
----Expected output
--1.21746171251992, Unconverted
--69.7554178461612, compass bearing in degrees
*/

/**
* @function   : Bearing
* @precis     : Returns a bearing between two point coordinates
* @version    : 1.0
* @usage      : FUNCTION Bearing(@p_dE1  float,
*                                @p_dN1 float,
*                                @p_dE2 float,
*                                @p_dN2 float )
*                RETURNS GEOMETRY
*               eg select dbo.Bearing(0,0,45,45) * (180/PI()) as Bearing;
* @param      : p_dE1     : X Ordinate of start point of bearing
* @paramtype  : p_dE1     : FLOAT
* @param      : p_dN1     : Y Ordinate of start point of bearing
* @paramtype  : p_dN1     : FLOAT
* @param      : p_dE2     : X Ordinate of end point of bearing
* @paramtype  : p_dE2     : FLOAT
* @param      : p_dN2     : Y Ordinate of end point of bearing
* @paramtype  : p_dN2     : FLOAT
* @return     : bearing   : Bearing between point 1 and 2 from 0-360 (in radians)
* @rtnType    : bearing   : Float
* @note       : Does not throw exceptions
* @note       : Assumes planar projection eg UTM.
* @history    : Simon Greener  - Feb 2005 - Original coding.
* @history    : Simon Greener  - May 2011 - Converted to SQL Server
* @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)

* Source URL: http://www.spatialdbadvisor.com/sql_server_blog/184/cogo-calculating-the-bearing-between-two-points-sql-server-2008-spatial
*/
