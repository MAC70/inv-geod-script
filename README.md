inv-geod-script
This is a Linux bash script to get distances and bearing between different
geolocations, and kml and gpx files.
This script is compatible with Red-Hat&Debian linux flavours.

The INPUT argument is a text file with a decimal "lat,lon" location per line.
The OUTPUT includes: one file with distances from one location to the next
one, a second file with the bearings from one location to the next one, and
finally two additional files, in gpx and kml formats, to let the locations be
displayed as waypoints in any GIS, like Google Earth, Baidu Maps, etc.
