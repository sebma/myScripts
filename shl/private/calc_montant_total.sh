#!/bin/sh

[ $# -ne 1 ] && {
  echo "=> Usage: <$0> <Swift|CMI OrderFilename>"
  exit 1
}

egrep ":32B:" $1 | tr ',' '.' | gawk -F":32B:EUR" 'BEGIN{print"0.00"}/32B/{print".+"$2}' | bc -l
