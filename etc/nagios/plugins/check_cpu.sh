#!/bin/bash
#
# evaluate CPU utilization % from Linux based systems
#
# Date: 2014-12-04
# Author: Thomas Borger - ESG (Edited by Mike Kim)
#
# the CPU util % check is done with following command line:
# vmstat | tail -1 | awk '{ print 100 - $15 }'
# It is auumed that the total CPU utilization % = 100 - idle %.

# get arguments

while getopts 'w:c:hp' OPT; do
  case $OPT in
    w)  int_warn=$OPTARG;;
    c)  int_crit=$OPTARG;;
    h)  hlp="yes";;
    p)  perform="yes";;
    *)  unknown="yes";;
  esac
done

# usage
HELP="
    usage: $0 [ -w value -c value -p -h ]

    syntax:

            -w --> Warning integer value
            -c --> Critical integer value
            -p --> print out performance data
            -h --> print this help screen
"

if [ "$hlp" = "yes" -o $# -lt 1 ]; then
  echo "$HELP"
  exit 0
fi

# Get the CPU utilization %
CPUUTIL=`vmstat | tail -1 | awk '{ print 100 - $15 }'`

# output with or without performance data
if [ "$perform" = "yes" ]; then
  OUTPUTP="CPU utilization: $CPUUTIL % | CPU utilization="$CPUUTIL"%;$int_warn;$int_crit;0"
else
  OUTPUT="CPU utilization: $CPUUTIL %"
fi

if [ -n "$int_warn" -a -n "$int_crit" ]; then

  err=0

  if (( $CPUUTIL >= $int_crit )); then
    err=2
elif (( $CPUUTIL >= $int_warn )); then
    err=1
  fi

  if (( $err == 0 )); then

    if [ "$perform" = "yes" ]; then
      echo "CPU OK - $OUTPUTP"
      exit "$err"
    else
      echo "CPU OK - $OUTPUT"
      exit "$err"
    fi

  elif (( $err == 1 )); then
    if [ "$perform" = "yes" ]; then
      echo "CPU WARNING - $OUTPUTP"
      exit "$err"
    else
      echo "CPU WARNING - $OUTOUT"
      exit "$err"
    fi

  elif (( $err == 2 )); then

    if [ "$perform" = "yes" ]; then
      echo "CPU CRITICAL - $OUTPUTP"
      exit "$err"
    else
      echo "CPU CRITICAL - $OUTPUT"
      exit "$err"
    fi

  fi

else

  echo "no output from plugin"
  exit 3

fi
exit
