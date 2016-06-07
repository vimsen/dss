#!/usr/bin/awk -f
BEGIN {
  FS = "\t"
}
NR > 1 {
  split($2,x,",")
  printf "{name: \"Prosumer %d\", cluster: clusters.first, edms_id: %d, building_type: %s, connection_type: %s, location_x: %f, location_y: %f},\n", $1, $1, $3, $5,x[1],x[2]
}

