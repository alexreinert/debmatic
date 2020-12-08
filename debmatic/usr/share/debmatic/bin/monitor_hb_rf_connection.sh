#!/bin/sh

/usr/share/debmatic/bin/wait_sysvar_creation.tcl || true

STATE=`cat /sys/class/hb-rf-eth/hb-rf-eth/is_connected`

while true; do
  if [ "$STATE" -eq "1" ]; then
    echo "HB-RF-ETH has reconnected"
    /usr/share/debmatic/bin/set_hb_rf_eth_connection_dp.tcl false
  else
    echo "HB-RF-ETH is not connected anymore"
    /usr/share/debmatic/bin/set_hb_rf_eth_connection_dp.tcl true
  fi

  STATE=`wait_sysfs_notify /sys/class/hb-rf-eth/hb-rf-eth/is_connected`
  if [ $? != 0 ]; then
    exit
  fi
done

