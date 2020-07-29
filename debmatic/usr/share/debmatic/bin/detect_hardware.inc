#!/bin/bash

if [ -e /etc/default/debmatic ]; then
  . /etc/default/debmatic
fi

systemd-detect-virt -c -q
if [ $? -eq 0 ]; then
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

    for try in {0..30}; do
      if [ -e /sys/module/hb_rf_eth/parameters/connect ]; then
        break
      fi
      sleep 1
    done
  fi

  for try in {0..30}; do
    ping -c1 $HB_RF_ETH_ADDRESS > /dev/null
    if [ $? -eq 0 ]; then
      break
    fi
    sleep 1
  done

  for try in {0..30}; do
    echo "$HB_RF_ETH_ADDRESS" > /sys/module/hb_rf_eth/parameters/connect && break
    sleep 1
  done
fi

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

  if [ -e $syspath/idVendor ] && [ "`cat $syspath/idVendor`" == "10c4" ] && [ "`cat $syspath/idProduct`" == "8c07" ]; then
    if [ $(lsmod | grep hb_rf_usb-2 | wc -l) -eq 0 ]; then
      modprobe -q hb_rf_usb

      for try in {0..30}; do
        lsmod | grep -q hb_rf_usb-2
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
    if [ ! -e "/dev/$UART_DEV" ]; then
      mknod "/dev/$UART_DEV" c `cat /sys/devices/virtual/raw-uart/$UART_DEV/dev | tr ':' ' '`
    fi

    echo 1 > /sys/class/raw-uart/$UART_DEV/reset_radio_module

    sleep 1
    /bin/eq3configcmd update-coprocessor -p /dev/$UART_DEV -t HM-MOD-UART -c -app &> /dev/null

    HM_HMRF_ADDRESS=`/bin/eq3configcmd read-default-rf-address -f /dev/$UART_DEV -h 2>&1 | grep "^0x"`

    if [ -z "$HM_HMRF_ADDRESS" ] || [[ "$HM_HMRF_ADDRESS" =~ ^0x..ffff$ ]]; then
      RF_RPI_MOD_INFO=`timeout 20 /usr/bin/java $JAVA_ARGS -Dgnu.io.rxtx.SerialPorts=/dev/$UART_DEV -jar /opt/HmIP/hmip-copro-update.jar -p /dev/$UART_DEV -v -a 2>&1`
      HM_HMRF_ADDRESS=`echo "$RF_RPI_MOD_INFO" | sed -n 's/.*Radio address = \([0-9A-Fa-f]\{6\}\).*/0x\1/p'`
      HM_HMIP_SGTIN=`echo "$RF_RPI_MOD_INFO" | sed -n 's/.*SGTIN = \([0-9A-Fa-f]\{24\}\).*/\1/p' | tr '[:lower:]' '[:upper:]'`

      if [ ! -z "$HM_HMRF_ADDRESS" ] || [ ! -z "$HM_HMIP_SGTIN" ]; then
        HM_HMRF_DEV='RPI-RF-MOD'
        HM_HMRF_SERIAL=`echo -n "$HM_HMIP_SGTIN" | tail -c 10`
        HM_HMRF_VERSION=`echo "$RF_RPI_MOD_INFO" | sed -n 's/.*Application version = \([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p'`
      fi
    else
      HM_HMRF_DEV='HM-MOD-RPI-PCB'
      HM_HMRF_SERIAL=`/bin/eq3configcmd update-coprocessor -p /dev/$UART_DEV -t HM-MOD-UART -c -se 2>&1 | grep "SerialNumber:" | cut -d' ' -f5 | tr '[:lower:]' '[:upper:]'`
      HM_HMRF_VERSION=`/bin/eq3configcmd update-coprocessor -p /dev/$UART_DEV -t HM-MOD-UART -c -v 2>&1 | grep "Version:" | cut -d' ' -f5`
      HM_HMIP_SGTIN=`/bin/eq3configcmd update-coprocessor -p /dev/$UART_DEV -t HM-MOD-UART -c -sg 2>&1 | grep "SGTIN:" | cut -d' ' -f5 | tr '[:lower:]' '[:upper:]'`
    fi

    if [ ! -z "$HM_HMRF_DEV" ]; then
      HM_HOST_RAW_UART="$UART_DEV"
      HM_HOST_GPIO_UART="/dev/$UART_DEV"
      HM_HMRF_DEVNODE="/dev/mmd_bidcos"
      HM_HMIP_DEV="$HM_HMRF_DEV"
      HM_HMIP_DEVNODE="/dev/mmd_hmip"
      HM_HMIP_ADDRESS="$HM_HMRF_ADDRESS"
      HM_HMIP_SERIAL="$HM_HMRF_SERIAL"
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

        HM_HMIP_DEV="HMIP-RFUSB"
        HMIP_RFUSB_INFO=`timeout 20 /usr/bin/java $JAVA_ARGS -Dgnu.io.rxtx.SerialPorts=$HM_HMIP_DEVNODE -jar /opt/HmIP/hmip-copro-update.jar -p $HM_HMIP_DEVNODE -v -a 2>&1`
        HM_HMIP_ADDRESS=`echo "$HMIP_RFUSB_INFO" | sed -n 's/.*Radio address = \([0-9A-Fa-f]\{6\}\).*/0x\1/p'`
        HM_HMIP_SGTIN=`echo "$HMIP_RFUSB_INFO" | sed -n 's/.*SGTIN = \([0-9A-Fa-f]\{24\}\).*/\1/p' | tr '[:lower:]' '[:upper:]'`
        HM_HMIP_SERIAL=`echo -n "$HM_HMIP_SGTIN" | tail -c 10`
        HM_HMIP_VERSION=`echo "$HMIP_RFUSB_INFO" | sed -n 's/.*Application version = \([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p'`
        if [[ "$HM_HMIP_SGTIN" =~ "3014F5AC94" ]]; then
          HM_HMIP_DEV="HMIP-RFUSB-TK"
        fi
        break
      fi
    done
  fi
done

