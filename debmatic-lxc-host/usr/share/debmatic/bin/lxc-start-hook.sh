#!/bin/bash

CGROUP="$LXC_NAME`find /sys/fs/cgroup/devices/lxc/ -maxdepth 1 -type d -name $LXC_NAME-* -exec basename {} \; | cut -d- -f2 | sort -n -r | head -1 | xargs -r printf '-%s\n'`"

allow_device () {
  for file in $(find /sys/fs/cgroup/devices/lxc/$CGROUP/ -name devices.allow); do
    echo "c $1 rwm" > $file
  done
}

modprobe -q eq3_char_loop || true
modprobe -q rpi_rf_mod_led || true
modprobe -q ledtrig-default-on || true
modprobe -q ledtrig-timer || modprobe -q led_trigger_timer || true
sysctl -w kernel.sched_rt_runtime_us=-1 || true

if [ -e /etc/default/hb_rf_eth ]; then
  . /etc/default/hb_rf_eth
fi
if [ ! -z "$HB_RF_ETH_ADDRESS" ]; then
  if [ ! -e /sys/module/hb_rf_eth/parameters/connect ]; then
    modprobe -q hb_rf_eth

    for try in {0..30}; do
      if [ -e /sys/module/hb_rf_eth/parameters/connect ]; then
        break
      fi
      sleep 1
    done
  fi

  for try in {0..30}; do
    if [ -e /sys/class/hb-rf-eth/hb-rf-eth/connect ]; then
      echo "$HB_RF_ETH_ADDRESS" > /sys/class/hb-rf-eth/hb-rf-eth/connect && break
    else
      echo "$HB_RF_ETH_ADDRESS" > /sys/module/hb_rf_eth/parameters/connect && break
    fi
    sleep 1
  done
fi

for syspath in $(find /sys/bus/usb/devices/); do
  if [ ! -e $syspath/idVendor ]; then
    continue

  USBID="`cat $syspath/idVendor`:`cat $syspath/idProduct`"

  case "$USBID" in
    "0403:6f70")
      KMOD="hb_rf_usb"
      ;;
    "10c4:8c07" | "1b1f:c020")
      KMOD="hb_rf_usb-2"
      ;;
    *)
      continue
      ;;
  esac

  if [ $(lsmod | grep -w $KMOD | wc -l) -eq 0 ]; then
    modprobe -q $KMOD

    for try in {0..30}; do
        lsmod | grep -q -w $KMOD && RC=$? || RC=$?
        if [ $RC -eq 0 ]; then
          break
        fi
        sleep 1
      done
    fi
  fi

  for try in {0..30}; do
      if [ $(find $syspath/ -mindepth 2 -name driver | wc -l) -ne 0 ]; then
        break
      fi
      sleep 1
  done
done

for dev_no in {0..5}
do
  if [ $dev_no -eq 0 ]; then
    UART_DEV="raw-uart"
  else
    UART_DEV="raw-uart$dev_no"
  fi

  if [ -e "/sys/devices/virtual/raw-uart/$UART_DEV" ]; then
    allow_device `cat /sys/devices/virtual/raw-uart/$UART_DEV/dev`
  fi
done

for syspath in $(find /sys/bus/usb/devices/); do
  if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "1b1f" ] && [ "`cat $syspath/idProduct`" == "c00f" ]; then
    allow_device `cat $syspath/dev`
  fi
done

if [ -e /sys/devices/virtual/eq3loop/eq3loop/dev ]; then
  allow_device "`cat /sys/devices/virtual/eq3loop/eq3loop/dev | cut -d: -f1`:*"
fi
