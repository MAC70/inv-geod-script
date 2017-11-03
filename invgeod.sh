#!/usr/bin/env bash

# File name: invgeod.sh
# Author: Miguel (dot) Cabeza (at) iese (dot) net
# Date: 20141101
# License: this program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 2 of the License,
# or any later version.

# The INPUT argument is a text file with a decimal "lat,lon" location per line.
# The OUTPUT includes: one file with distances from one location to the next
# one, a second file with the bearings from one location to the next one, and
# finally two additional files, in gpx and kml formats, to let the locations be
# displayed as waypoints in any GIS, like Google Earth, Baidu Maps, etc.

# BASH security flags
	set -o errexit	# exit on command error
	set -o pipefail	# exit on pipe failure
	set -o nounset	# exit if an unset variable is found
	# set -o xtrace	# uncomment to enable debug

# Checking syntax and input file existance
if [ ! $# == 1 ] || [ ! -f $1 ]
 then
  echo "Usage: $0 input_file"
  echo "Input file should contain a decimal 'lat,lon' pair per line."
  exit 1
fi

# Removing any left temporal file
rm   --force 	INVERSE_GEOD_INPUT_FILE	BUFFER_FILE 			\
		DISTANCE_BEARING_OUTPUT_FILE $1.csv $1.gpx $1.kml 	\
		$1.distances $1.bearings >/dev/null 2>&1

# Checking whether we need to install any dependencies
function verify_install()
{
 command -v $1 >/dev/null 2>&1 \
  || sudo sh -c "yum install -y $1 || apt-get -y install $1"
}
verify_install proj && verify_install gpsbabel \
 || { echo "Error."; exit 1; }

# Creating the INVERSE_GEOD_BUFFER_FILE with TWO 'lat lon' pairs per line
function get_line() { echo $(head -$1 $2 | tail -1); }
NUMBER_OF_GEOLOCATIONS=$(grep -c '' $1)
for GEOLOCATION in $(seq 1 $NUMBER_OF_GEOLOCATIONS)
 do
  case $GEOLOCATION in
   1)
    FIRST_GEOLOCATION=$(get_line $GEOLOCATION $1)
    FORMER_GEOLOCATION=$FIRST_GEOLOCATION
    LATTER_GEOLOCATION=$(get_line $((GEOLOCATION + 1)) $1);;
   $NUMBER_OF_GEOLOCATIONS)
    FORMER_GEOLOCATION=$(get_line $GEOLOCATION $1)
    LATTER_GEOLOCATION=$FIRST_GEOLOCATION;;
   *)
    FORMER_GEOLOCATION=$(get_line $GEOLOCATION $1)
    LATTER_GEOLOCATION=$(get_line $((GEOLOCATION + 1)) $1);;
  esac
  echo "$FORMER_GEOLOCATION"" ""$LATTER_GEOLOCATION" >> BUFFER_FILE
 done
sed 's/,/ /g' BUFFER_FILE > INVERSE_GEOD_INPUT_FILE # removing commas

# Getting distances and bearings (the inverse geodetic
# problem) from proj4's geod with the inverse "-I" flag
geod -I +datum=WGS84 +ellps=WGS84 +units=m 			\
	INVERSE_GEOD_INPUT_FILE > DISTANCE_BEARING_OUTPUT_FILE	\
	&& {
	    cat DISTANCE_BEARING_OUTPUT_FILE | cut -f1 > $1.bearings
	    cat DISTANCE_BEARING_OUTPUT_FILE | cut -f3 > $1.distances
	   }
rm   --force 	BUFFER_FILE INVERSE_GEOD_INPUT_FILE	\
		DISTANCE_BEARING_OUTPUT_FILE  >/dev/null 2>&1

# Generating gpx and kml files to allow for displaying the
# locations in a GIS, like Google Earth, Baidu Maps, etc.
for GEOLOCATION in $(seq 1 $NUMBER_OF_GEOLOCATIONS)
 do echo $(get_line $GEOLOCATION $1)",\""$GEOLOCATION"\"" >> $1.csv; done
function output_format() { gpsbabel -i csv -f $1.csv -o $2 -F $1.$2; }
output_format $1 kml && output_format $1 gpx && rm --force $1.csv \
 && echo "OK. Done." || { echo "Error."; exit 1; }
exit

