CREATE FUNCTION [App].[fnGreatCircleDistanceInMeters]
(
		@a_Latitude		decimal(11,6),
        @a_Longitude	decimal(11,6),
		@b_Latitude		decimal(11,6),
        @b_Longitude	decimal(11,6)
)
RETURNS decimal(19,6)
AS
BEGIN

--Returns Meters 
--WGS-84 ellipsoid model;
--http://publicvoidlife.blogspot.com/2011/02/shortest-distance-between-two-points-is.html--


declare
	--average equatorial radius is 6377 km
	@equatorial_radius decimal(11,6) = 6378.136 , --kilometers (3963.190 miles)
	@polar_radius decimal(11,6) = 6356.751, --kilometers (3949.902 miles)
	@PI decimal(11,6) = cast(pi() as decimal(11,6)),
	@One80 decimal(11,6) = 180.0,
	@Distance as decimal(19,6);


set @Distance =
		 ACOS(
			  COS(@a_Latitude * (@PI/@One80)) *
			  COS(@a_Longitude * (@PI/@One80)) *
			  COS(@b_Latitude * (@PI/@One80)) *
			  COS(@b_Longitude * (@PI/@One80)) +
			  COS(@a_Latitude * (@PI/@One80)) *
			  SIN(@a_Longitude * (@PI/@One80)) *
			  COS(@b_Latitude * (@PI/@One80)) *
			  SIN(@b_Longitude * (@PI/@One80)) +
			  SIN(@a_Latitude * (@PI/@One80)) *
			  SIN(@b_Latitude * (@PI/@One80))
			) 
			*
			(
			  (@equatorial_radius * @polar_radius) /
			  (
				SQRT(
				  (@equatorial_radius * @equatorial_radius) -
				  (
					(
					  (@equatorial_radius * @equatorial_radius) -
					  (@polar_radius * @polar_radius)
					) *
					(
					  COS(@a_Latitude) *
					  COS(@a_Latitude)
					)
				  )
				)
			  )
			) * 1000.000000 ;

	RETURN (@Distance)
END

/*

SELECT [utl].[fnGreatCircleDistanceInMeters](33.96,-84.65, 40.41792, -3.705769)/1000 AS GC_Distance_in_kilometers;

*/
