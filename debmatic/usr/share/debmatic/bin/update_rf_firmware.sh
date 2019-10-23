#!/bin/bash

if [[ -e /etc/config/no-coprocessor-update ]]; then
  exit 0
fi

if [ -e /usr/share/debmatic/lib ]; then
  LIBSERIAL=`find /usr/share/debmatic/lib -name "libNRJavaSerial*.so"`
  if [ -n "$LIBSERIAL" ]; then
    JAVA_ARGS="-DlibNRJavaSerial.userlib=$LIBSERIAL"
  fi
fi

if [ "$HM_HMRF_DEV" == "HM-MOD-RPI-PCB" ]; then
  NEW_VERSION=`grep 'dualcopro_si1002_update_blhm.eq3' /firmware/HM-MOD-UART/fwmap | awk '{print $3}'`

  if [ -n "$NEW_VERSION" ] && [ "$NEW_VERSION" != "$HM_HMRF_VERSION" ]; then
    echo "Starting update of HM-MOD-RPI-PCB to version $NEW_VERSION..."

    /bin/eq3configcmd update-coprocessor -p $HM_HOST_GPIO_UART -t HM-MOD-UART -u -d /firmware/HM-MOD-UART

    HM_HMRF_VERSION=`/bin/eq3configcmd update-coprocessor -p $HM_HOST_GPIO_UART -t HM-MOD-UART -c -v 2>&1 | grep "Version:" | cut -d' ' -f5`

    echo "$HM_HMRF_VERSION" > /var/rf_firmware_version

    if [ "$HM_HMIP_DEV" == "$HM_HMRF_DEV" ]; then
      HM_HMIP_VERSION=$HM_HMRF_VERSION
      echo "$HM_HMRF_VERSION" > /var/hmip_firmware_version
    fi

    set | grep '^HM_' >/var/hm_mode

    if [ "$NEW_VERSION" != "$HM_HMRF_VERSION" ]; then
      echo "Failed to update HM-MOD-RPI-PCB to version $NEW_VERSION."
      exit 1
    fi

    echo "Successfully updated HM-MOD-RPI-PCB to version $NEW_VERSION."
  elif [ -n "$NEW_VERSION" ]; then
    echo "HM-MOD-RPI-PCB has already desired version $NEW_VERSION..."
  fi
fi

if [ "$HM_HMRF_DEV" == "RPI-RF-MOD" ]; then
  NEW_VERSION=`ls /firmware/RPI-RF-MOD/dualcopro_update_blhmip-*.eq3 | sed 's/.*-\(.*\)\.eq3/\1/' | sort | tail -1`

  if [ -n "$NEW_VERSION" ] && [ "$NEW_VERSION" != "$HM_HMRF_VERSION" ]; then
    echo "Starting update of RPI-RF-MOD to version $NEW_VERSION..."

    HM_HMRF_VERSION=`java $JAVA_ARGS -Dgnu.io.rxtx.SerialPorts=$HM_HOST_GPIO_UART -jar /opt/HmIP/hmip-copro-update.jar -p $HM_HOST_GPIO_UART -o -f /firmware/RPI-RF-MOD/dualcopro_update_blhmip-$NEW_VERSION.eq3 2>/dev/null | grep "Version:" | cut -d' ' -f5`

    echo "$HM_HMRF_VERSION" > /var/rf_firmware_version

    if [ "$HM_HMIP_DEV" == "$HM_HMRF_DEV" ]; then
      HM_HMIP_VERSION=$HM_HMRF_VERSION
      echo "$HM_HMRF_VERSION" > /var/hmip_firmware_version
    fi

    set | grep '^HM_' >/var/hm_mode

    if [ "$NEW_VERSION" != "$HM_HMRF_VERSION" ]; then
      echo "Failed to update RPI-RF-MOD to version $NEW_VERSION."
      exit 1
    fi

    echo "Successfully updated RPI-RF-MOD to version $NEW_VERSION."
  elif [ -n "$NEW_VERSION" ]; then
    echo "RPI-RF-MOD has already desired version $NEW_VERSION..."
  fi
fi

if [ "$HM_HMIP_DEV" == "HMIP-RFUSB" ]; then
  NEW_VERSION=`ls /firmware/HmIP-RFUSB/hmip_coprocessor_update-*.eq3 | sed 's/.*-\(.*\)\.eq3/\1/' | sort | tail -1`

  if [ -n "$NEW_VERSION" ] && [ "$NEW_VERSION" != "$HM_HMIP_VERSION" ]; then
    echo "Starting update of HMIP-RFUSB to version $NEW_VERSION..."

    HM_HMIP_VERSION=`java $JAVA_ARGS -Dgnu.io.rxtx.SerialPorts=$HM_HMIP_DEVNODE -jar /opt/HmIP/hmip-copro-update.jar -p $HM_HMIP_DEVNODE -o -f /firmware/HmIP-RFUSB/hmip_coprocessor_update-$NEW_VERSION.eq3 2>/dev/null | grep "Version:" | cut -d' ' -f5`

    echo "$HM_HMRF_VERSION" > /var/hmip_firmware_version

    set | grep '^HM_' >/var/hm_mode

    if [ "$NEW_VERSION" != "$HM_HMIP_VERSION" ]; then
      echo "Failed to update HMIP-RFUSB to version $NEW_VERSION."
      exit 1
    fi

    echo "Successfully updated HMIP-RFUSB to version $NEW_VERSION."
  elif [ -n "$NEW_VERSION" ]; then
    echo "HMIP-RFUSB has already desired version $NEW_VERSION..."
  fi
fi

