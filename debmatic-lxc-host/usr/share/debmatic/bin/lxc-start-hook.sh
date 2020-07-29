#!/bin/bash

CGROUP="$LXC_NAME`find /sys/fs/cgroup/devices/lxc/ -maxdepth 1 -type d -name $LXC_NAME-* -exec basename {} \; | cut -d- -f2 | sort -n -r | head -1 | xargs -r printf '-%s\n'`"

allow_device () {
  for file in $(find /sys/fs/cgroup/devices/lxc/$CGROUP/ -name devices.allow); do
    echo "c $1 rwm" > $file
  done
}

modprobe -q hb_rf_eth || true
modprobe -q eq3_char_loop || true
modprobe -q rpi_rf_mod_led || true
modprobe -q ledtrig-default-on || true
modprobe -q ledtrig-timer || modprobe -q led_trigger_timer || true
sysctl -w kernel.sched_rt_runtime_us=-1 || true

for syspath in $(find /sys/bus/usb/devices/); do
  if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "0403" ] && [ "`cat $syspath/idProduct`" == "6f70" ]; then
    if [ $(lsmod | grep hb_rf_usb | wc -l) -eq 0 ]; then
      modprobe -q hb_rf_usb

      for try in {0..30}; do
        lsmod | grep -q hb_rf_usb
        if [ $? -eq 0 ]; then
          break
        fi
        sleep 1
      done
    fi

    for try in {0..30}; do
      if [ $(find $syspath/ -name gpiochip* | wc -l) -ne 0 ]; then
        break
      fi
      sleep 1
    done
  fi
done

for syspath in $(find /sys/bus/usb/devices/); do
  if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "10c4" ] && [ "`cat $syspath/idProduct`" == "8c07" ]; then
    if [ $(lsmod | grep hb_rf_usb_2 | wc -l) -eq 0 ]; then
      modprobe -q hb_rf_usb_2

      for try in {0..30}; do
        lsmod | grep -q hb_rf_usb_2
        if [ $? -eq 0 ]; then
          break
        fi
        sleep 1
      done
    fi

    for try in {0..30}; do
      if [ $(find $syspath/ -name gpiochip* | wc -l) -ne 0 ]; then
        break
      fi
      sleep 1
    done
  fi
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

for syspath in $(find /sys/bus/usb/devices/); do
  if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "1b1f" ] && [ "`cat $syspath/idProduct`" == "c020" ]; then
    if [ $(find $syspath/ -name ttyUSB* | wc -l) -eq 0 ]; then
      if [ ! -e /sys/bus/usb-serial/drivers/cp210x ]; then
        modprobe -q cp210x

        for try in {0..30}; do
          if [ -e /sys/bus/usb-serial/drivers/cp210x ]; then
            break
          fi
          sleep 1
        done
      fi

      grep -q "1b1f c020" /sys/bus/usb-serial/drivers/cp210x/new_id || echo "1b1f c020" > /sys/bus/usb-serial/drivers/cp210x/new_id

      for try in {0..30}; do
        if [ $(find $syspath/ -name ttyUSB* | wc -l) -ne 0 ]; then
          break
        fi
        sleep 1
      done
    fi

    for syspath in $(find $syspath/ -name ttyUSB*); do
      if [ -e $syspath/dev ]; then
        allow_device `cat $syspath/dev`
        break
      fi
    done
  fi
done

if [ -e /sys/devices/virtual/eq3loop/eq3loop/dev ]; then
  allow_device "`cat /sys/devices/virtual/eq3loop/eq3loop/dev | cut -d: -f1`:*"
fi
