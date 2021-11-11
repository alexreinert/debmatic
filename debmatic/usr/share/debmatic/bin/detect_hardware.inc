#!/bin/bash

if [ -e /etc/default/debmatic ]; then
  . /etc/default/debmatic
fi

systemd-detect-virt -c -q && RC=$? || RC=$?
if [ $RC -eq 0 ]; then
  mount /sys -o remount,rw
fi

if [ -e /usr/share/debmatic/lib ]; then
  LIBSERIAL=`find /usr/share/debmatic/lib -name "libNRJavaSerial*.so"`
  if [ -n "$LIBSERIAL" ]; then
    JAVA_ARGS="-DlibNRJavaSerial.userlib=$LIBSERIAL"
  fi
fi

if [ -e /etc/default/hb_rf_eth ]; then
  . /etc/default/hb_rf_eth
fi
if [ ! -z "$HB_RF_ETH_ADDRESS" ]; then
  if [ ! -e /sys/module/hb_rf_eth/parameters/connect ]; then
    modprobe -q hb_rf_eth

    /usr/share/debmatic/bin/wait_network_up.sh

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
    sleep 2
  done
fi

for syspath in $(find /sys/bus/usb/devices/); do
  if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "0403" ] && [ "`cat $syspath/idProduct`" == "6f70" ]; then
    if [ $(lsmod | grep hb_rf_usb | wc -l) -eq 0 ]; then
      modprobe -q hb_rf_usb

      for try in {0..30}; do
        lsmod | grep -q hb_rf_usb && RC=$? || RC=$?
        if [ $RC -eq 0 ]; then
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

  if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "10c4" ] && [ "`cat $syspath/idProduct`" == "8c07" ]; then
    if [ $(lsmod | grep hb_rf_usb-2 | wc -l) -eq 0 ]; then
      modprobe -q hb_rf_usb-2

      for try in {0..30}; do
        lsmod | grep -q hb_rf_usb-2 && RC=$? || RC=$?
        if [ $RC -eq 0 ]; then
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
    if [ ! -e "/dev/$UART_DEV" ]; then
      mknod "/dev/$UART_DEV" c `cat /sys/devices/virtual/raw-uart/$UART_DEV/dev | tr ':' ' '`
    fi

    echo 1 > /sys/class/raw-uart/$UART_DEV/reset_radio_module

    MODULE_INFO=`detect_radio_module /dev/$UART_DEV` && RC=$? || RC=$?
    if [ $RC -eq 0 ]; then
      HM_HOST_RAW_UART="$UART_DEV"
      HM_HOST_GPIO_UART="/dev/$UART_DEV"
      if [ -e "/sys/class/raw-uart/$UART_DEV/device_type" ]; then
        HM_HOST_UART_DEVICE_TYPE=`cat /sys/class/raw-uart/$UART_DEV/device_type`
      fi

      HM_HMRF_DEVNODE="/dev/mmd_bidcos"
      HM_HMRF_DEV=`echo $MODULE_INFO | cut -d' ' -f1`
      HM_HMRF_SERIAL=`echo $MODULE_INFO | cut -d' ' -f2`
      HM_HMRF_ADDRESS=`echo $MODULE_INFO | cut -d' ' -f4`
      HM_HMRF_VERSION=`echo $MODULE_INFO | cut -d' ' -f6`

      HM_HMIP_DEV="$HM_HMRF_DEV"
      HM_HMIP_DEVNODE="/dev/mmd_hmip"
      HM_HMIP_SERIAL="$HM_HMRF_SERIAL"
      HM_HMIP_ADDRESS=`echo $MODULE_INFO | cut -d' ' -f5`
      HM_HMIP_SGTIN=`echo $MODULE_INFO | cut -d' ' -f3`
      HM_HMIP_VERSION="$HM_HMRF_VERSION"

      break
    fi
  fi
done

if [ -z "$AVOID_HM_CFG_USB_2" ] || [  "$AVOID_HM_CFG_USB_2" != "1" ]; then
  for syspath in $(find /sys/bus/usb/devices/); do
    if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "1b1f" ] && [ "`cat $syspath/idProduct`" == "c00f" ]; then
      HM_HMRF_DEVNODE="/dev/$(udevadm info -q name -p $syspath)"

      if [ ! -e "$HM_HMRF_DEVNODE" ]; then
        mkdir -p `dirname $HM_HMRF_DEVNODE`
        mknod "$HM_HMRF_DEVNODE" c `cat $syspath/dev | tr ':' ' '`
      fi

      HM_HMRF_DEV="HM-CFG-USB-2"
      HM_HMRF_SERIAL=`cat $syspath/serial | tr '[:lower:]' '[:upper:]'`
      break
    fi 
  done
fi

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
        HM_HMIP_DEVNODE="/dev/$(udevadm info -q name -p $syspath)"

        if [ ! -e "$HM_HMIP_DEVNODE" ]; then
          mknod "$HM_HMIP_DEVNODE" c `cat $syspath/dev | tr ':' ' '`
        fi

        MODULE_INFO=`detect_radio_module $HM_HMIP_DEVNODE`

        HM_HMIP_DEV="HMIP-RFUSB"
        HM_HMIP_ADDRESS=`echo $MODULE_INFO | cut -d' ' -f5`
        HM_HMIP_SGTIN=`echo $MODULE_INFO | cut -d' ' -f3`
        HM_HMIP_SERIAL=`echo $MODULE_INFO | cut -d' ' -f2`
        HM_HMIP_VERSION=`echo $MODULE_INFO | cut -d' ' -f6`
        if [[ "$HM_HMIP_SGTIN" =~ "3014F5AC94" ]]; then
          HM_HMIP_DEV="HMIP-RFUSB-TK"
        fi
        break
      fi
    done
  fi
done

