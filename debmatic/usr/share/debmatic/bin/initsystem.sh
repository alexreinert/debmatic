#!/bin/bash

if [ -e /etc/default/debmatic ]; then
  . /etc/default/debmatic
fi

mkdir -p /var/status

rm -f /var/status/startupFinished
rm -f /var/status/debmatic_*
rm -f /var/rf_*
rm -f /var/hm_*
rm -f /var/hmip_*
rm -f /var/board_*
rm -f /var/status/hasInternet
rm -f /var/status/hasIP
rm -f /var/status/hasLink
rm -f /var/*.handlers
rm -f /var/status/*.connstat
rm -f /var/SESSIONS.dat

. /usr/share/debmatic/bin/detect_hardware.inc

if [ -e /usr/local/.doFactoryReset ]; then
  rm -rf /etc/config/*
  rm -f /usr/local/.doFactoryReset
fi

if [ -d /usr/local/eQ-3-Backup/restore ]; then
  rm -rf /etc/config/*
  rsync -av /usr/local/eQ-3-Backup/restore/etc/config/ /etc/config
  rm -rf /usr/local/eQ-3-Backup/restore
fi

for file in `ls /etc/config_templates`; do
  if [ ! -e /etc/config/$file ]; then
    \cp /etc/config_templates/$file /etc/config/
  fi
done
mkdir -p /etc/config/addons/www

\cp -f /etc/config_templates/InterfacesList.xml /etc/config/
if [ -z "$HM_HOST_RAW_UART" ]; then
  touch /var/status/debmatic_avoid_multimacd
fi

if [ -z "$HM_HMRF_DEV" ] && [ `egrep -c '^Type = (HMLGW2|Lan Interface)' /etc/config/rfd.conf` == 0 ]; then
  touch /var/status/debmatic_avoid_rfd
fi

if [ ! -e /etc/config/hs485d.conf ] || [ `egrep -c '^Type = HMWLGW' /etc/config/hs485d.conf` == 0 ]; then
  touch /var/status/debmatic_avoid_hs485d
fi

cat > /var/hm_mode << EOF
HM_HOST='DEBMATIC'
HM_HOST_RAW_UART='$HM_HOST_RAW_UART'
HM_HOST_GPIO_UART='$HM_HOST_GPIO_UART'
HM_HOST_GPIO_RESET=''
HM_LED_GREEN=''
HM_LED_RED=''
HM_LED_YELLOW=''
HM_RTC=''
HM_MODE='NORMAL'
HM_HMRF_DEVNODE='$HM_HMRF_DEVNODE'
HM_HMIP_DEVNODE='$HM_HMIP_DEVNODE'
HM_HMRF_DEV='$HM_HMRF_DEV'
HM_HMIP_DEV='$HM_HMIP_DEV'
HM_HMRF_SERIAL='$HM_HMRF_SERIAL'
HM_HMRF_VERSION='$HM_HMRF_VERSION'
HM_HMRF_ADDRESS='$HM_HMRF_ADDRESS'
HM_HMIP_SGTIN='$HM_HMIP_SGTIN'
HM_HMIP_SERIAL='$HM_HMIP_SERIAL'
HM_HMIP_VERSION='$HM_HMIP_VERSION'
HM_HMIP_ADDRESS='$HM_HMIP_ADDRESS'
EOF

if [ -n "${HM_HMRF_SERIAL}" ]; then
  BOARD_SERIAL=${HM_HMRF_SERIAL}
  FIRMWARE_VERSION=${HM_HMRF_VERSION}
  RF_ADDRESS=${HM_HMRF_ADDRESS}
elif [ -n "${HM_HMIP_SERIAL}" ]; then
  BOARD_SERIAL=${HM_HMIP_SERIAL}
  FIRMWARE_VERSION=${HM_HMIP_VERSION}
  RF_ADDRESS=${HM_HMIP_ADDRESS}
else
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

  BOARD_SERIAL=$DEBMATIC_SERIAL
  RF_ADDRESS=$DEBMATIC_ADDRESS
fi

echo "${BOARD_SERIAL}" > /var/board_serial
echo "${FIRMWARE_VERSION}" > /var/rf_firmware_version
echo "${RF_ADDRESS}" > /var/rf_address

if [ -n ${HM_HMIP_SERIAL} ]; then
  echo "${HM_HMIP_SERIAL}" > /var/hmip_board_serial
  echo "${HM_HMIP_VERSION}" > /var/hmip_firmware_version
  echo "${HM_HMIP_ADDRESS}" > /var/hmip_address
  if [ -n "${HM_HMIP_SGTIN}" ]; then
    echo "${HM_HMIP_SGTIN}" > /var/board_sgtin
    echo "${HM_HMIP_SGTIN}" > /var/hmip_board_sgtin
  fi
fi

cat > /var/ids << EOF
BidCoS-Address=${RF_ADDRESS}
SerialNumber=${BOARD_SERIAL}
EOF

if [ ! -e /etc/config/ids ]; then
  cp /var/ids /etc/config/ids
else
  if [ `grep -c "BidCoS-Address \?= \?[a-zA-Z0-9]\+" /etc/config/ids` -eq 0 ]; then
    cp /var/ids /etc/config/ids
  fi
fi

if [ ! -e /etc/config/crypttool.cfg ]; then
  touch /etc/config/crypttool.cfg
fi

mkdir -p /etc/config/hs485d

# MigrateSecuritySettings 3.41.x
sed -i -e 's/\s*Listen\s*Port\s*=\s*2001/Listen Port = 32001/' /etc/config/rfd.conf
if [ -e /etc/config/hs485d.conf ]; then
  sed -i -e 's/\s*Listen\s*Port\s*=\s*2000/Listen Port = 32000/' /etc/config/hs485d.conf
fi
sed -i -e 's/:2001/:32001/' -e 's/:9292/:39292/' -e 's/:2010/:32010/' /etc/config/InterfacesList.xml

for i in {1..10}; do
  for IFACE in `ls /sys/class/net/`; do
    IFACE=$IFACE /usr/share/debmatic/bin/ifup.sh
    if [ -e /var/status/hasInternet ]; then
      break 2
    fi
  done
  sleep 1
done

mkdir -p /media/usb0/measurement
touch /var/status/hasUSB
touch /var/status/hasSD
touch /var/status/USBinitialised
touch /var/status/SDinitialised

