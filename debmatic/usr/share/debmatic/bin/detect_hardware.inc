#!/bin/bash

if [ -e /etc/default/debmatic ]; then
  . /etc/default/debmatic
fi

systemd-detect-virt -c -q && RC=$? || RC=$?
if [ $RC -eq 0 ]; then
  mount /sys -o remount,rw
fi

if [ -z "$DEBMATIC_SERIAL" ]; then
  DEBMATIC_SERIAL=`shuf -i 1-9999999 -n 1`
  DEBMATIC_SERIAL=`printf "DEB%07d" $DEBMATIC_SERIAL`
  echo "DEBMATIC_SERIAL=\"$DEBMATIC_SERIAL\"" >> /etc/default/debmatic
fi

if [ -z "$DEBMATIC_ADDRESS" ]; then
  DEBMATIC_ADDRESS=`shuf -i 1-16777215 -n 1`
  DEBMATIC_ADDRESS=`printf "0x%06x" $DEBMATIC_ADDRESS`
  echo "DEBMATIC_ADDRESS=\"$DEBMATIC_ADDRESS\"" >> /etc/default/debmatic
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
  if [ ! -e $syspath/idVendor ]; then
    continue
  fi

  USBID="`cat $syspath/idVendor`:`cat $syspath/idProduct`"

  case "$USBID" in
    "0403:6f70")
      KMOD="hb_rf_usb"
      ;;
    "10c4:8c07" | "1b1f:c020")
      KMOD="hb_rf_usb_2"
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

  if [ -e "/sys/class/raw-uart/$UART_DEV" ]; then
    if [ ! -e "/dev/$UART_DEV" ]; then
      mknod "/dev/$UART_DEV" c `cat /sys/class/raw-uart/$UART_DEV/dev | tr ':' ' '`
    fi

    echo 1 > /sys/class/raw-uart/$UART_DEV/reset_radio_module

    MODULE_INFO=`detect_radio_module /dev/$UART_DEV` && RC=$? || RC=$?
    if [ $RC -eq 0 ]; then
      DEV_TYPE=`echo $MODULE_INFO | cut -d' ' -f1`
      DEV_SERIAL=`echo $MODULE_INFO | cut -d' ' -f2`

      HM_HOST_GPIO_UART="/dev/$UART_DEV"

      HM_HMIP_DEV="$DEV_TYPE"
      HM_HMIP_DEVNODE="/dev/$UART_DEV"
      HM_HMIP_SERIAL="$DEV_SERIAL"
      HM_HMIP_VERSION=`echo $MODULE_INFO | cut -d' ' -f6`
      HM_HMIP_SGTIN=`echo $MODULE_INFO | cut -d' ' -f3`
      HM_HMIP_ADDRESS=`echo $MODULE_INFO | cut -d' ' -f5`

      if [ -e "/sys/class/raw-uart/$UART_DEV/device_type" ]; then
        HM_HOST_UART_DEVICE_TYPE=`cat /sys/class/raw-uart/$UART_DEV/device_type`
        HM_HMIP_DEVTYPE="$HM_HOST_UART_DEVICE_TYPE"
      fi

      if [ "$DEV_TYPE" != "HMIP-RFUSB-TK" ]; then
        HM_HMRF_DEV="$HM_HMIP_DEV"
        HM_HMRF_DEVNODE="$HM_HMIP_DEVNODE"
        HM_HMRF_SERIAL="$HM_HMIP_SERIAL"
        HM_HMRF_VERSION="$HM_HMIP_VERSION"
        HM_HMRF_ADDRESS=`echo $MODULE_INFO | cut -d' ' -f4`
        HM_HMRF_DEVTYPE="$HM_HMIP_DEVTYPE"
      fi

      if [ "$HM_HMRF_ADDRESS" == "0x000000" ]; then
        HM_HMRF_ADDRESS="$DEBMATIC_ADDRESS"
      fi

      break
    fi
  fi
done

if [ -z "$AVOID_HM_CFG_USB_2" ] || [  "$AVOID_HM_CFG_USB_2" != "1" ]; then
  for syspath in $(find /sys/bus/usb/devices/); do
    if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "1b1f" ] && [ "`cat $syspath/idProduct`" == "c00f" ]; then
      HM_HMRF_DEV="HM-CFG-USB-2"
      HM_HMRF_DEVNODE="/dev/$(udevadm info -q name -p $syspath)"

      if [ ! -e "$HM_HMRF_DEVNODE" ]; then
        mkdir -p `dirname $HM_HMRF_DEVNODE`
        mknod "$HM_HMRF_DEVNODE" c `cat $syspath/dev | tr ':' ' '`
      fi

      HM_HMRF_SERIAL=`cat $syspath/serial | tr '[:lower:]' '[:upper:]'`
      HM_HMRF_VERSION=""
      HM_HMRF_ADDRESS="$DEBMATIC_ADDRESS"
      HM_HMRF_DEVTYPE="USB"
      break
    fi 
  done
fi

