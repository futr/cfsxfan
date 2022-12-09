#!/bin/bash
TEMPPATH=/sys/devices/platform/coretemp.0/hwmon/hwmon3/temp1_input
SLEEPTIME=3
LOWTEMP=50.0
HIGHTEMP=70.0
LOWSPEED=$((16#00))
HIGHSPEED=$((16#70))

TEMPDIV=$(echo | awk "{print ($HIGHSPEED-$LOWSPEED)/($HIGHTEMP-$LOWTEMP)}")

while true
do
  PACKAGETEMP=$(echo "$(cat ${TEMPPATH}) / 1000" | bc)
  FANSPD=$(echo $PACKAGETEMP | awk "{if(\$1<$LOWTEMP){printf \"0x%02X\",$LOWSPEED}else if(\$1>$HIGHTEMP){printf \"0x%02X\",$HIGHSPEED}else{printf \"0x%02X\n\", ($LOWSPEED + $TEMPDIV * ($PACKAGETEMP-$LOWTEMP))}}")
  echo "\_SB.PCI0.LPCB.TFN1.SSPD $FANSPD" > /proc/acpi/call
  sleep $SLEEPTIME
  # echo $FANSPD
done
