#!/usr/bin/awk -f
BEGIN {
  OFS="\t"
}
$1 == 0 {
  $1 = ""
  $0 = $0
  split( $0, a)
  asort( a )
  for( i= 1; i <= length(a); i++ ) 
    $(NF-i+1) = a[i]
  $1 = ARGIND OFS $1
  print
}
