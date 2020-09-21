#!/bin/sh

/usr/share/debmatic/bin/set_hb_rf_eth_connection_dp.tcl false

while true; do
  STATE=`wait_sysfs_notify /sys/class/hb-rf-eth/hb-rf-eth/is_connected`
  if [ $? != 0 ]; then
    exit
  fi

  if [ "$STATE" -eq "1" ]; then
    echo "HB-RF-ETH has reconnected"
    /usr/share/debmatic/bin/set_hb_rf_eth_connection_dp.tcl false
  else
    echo "HB-RF-ETH is not connected anymore"
    /usr/share/debmatic/bin/set_hb_rf_eth_connection_dp.tcl true
  fi
done

