#!/bin/bash

if [ -e /etc/default/debmatic ]; then
  . /etc/default/debmatic
fi

for file in `ls /usr/share/debmatic/lib/ld`; do
  if [ ! -e /lib/$file ]; then
    ln -s /usr/share/debmatic/lib/ld/$file /lib/$file
  fi
done

mkdir -p /var/status

rm -f /var/status/startupFinished
rm -f /var/status/debmatic_*
rm -f /var/status/HMServerStarted
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
if [ "$HM_HMIP_DEV" != "HM-MOD-RPI-PCB" ] && [ "$HM_HMIP_DEV" != "RPI-RF-MOD" ] && [ "$HM_HMIP_DEV" != "HMIP-RFUSB" ]; then
  touch /var/status/debmatic_avoid_multimacd
fi

if [ -z "$HM_HMRF_DEV" ] && [ `egrep -c '^Type = (HMLGW2|Lan Interface)' /etc/config/rfd.conf` == 0 ]; then
  touch /var/status/debmatic_avoid_rfd
fi

if [ ! -e /etc/config/hs485d.conf ] || [ `egrep -c '^Type = HMWLGW' /etc/config/hs485d.conf` == 0 ]; then
  touch /var/status/debmatic_avoid_hs485d
fi

if [[ -n "${HM_HMRF_DEV}" ]]; then
  BOARD_SERIAL=${HM_HMIP_SERIAL}
  BOARD_ADDRESS=${HM_HMRF_ADDRESS}
elif [[ -n "${HM_HMIP_DEV}" ]]; then
  BOARD_SERIAL=${HM_HMIP_SERIAL}
  BOARD_ADDRESS=${HM_HMIP_ADDRESS}
else
  BOARD_SERIAL=${DEBMATIC_SERIAL}
  BOARD_ADDRESS=${DEBMATIC_ADDRESS}
fi

echo -n "${BOARD_SERIAL}" > /var/board_serial

if [[ -n "${HM_HMIP_SGTIN}" ]]; then
  echo -n "${HM_HMIP_SGTIN}" > /var/board_sgtin
fi

echo -n "${HM_HMRF_SERIAL}" > /var/rf_board_serial
echo -n "${HM_HMRF_ADDRESS}" > /var/rf_address
echo -n "${HM_HMRF_VERSION}" > /var/rf_firmware_version
echo -n "${HM_HMIP_SERIAL}" > /var/hmip_board_serial
echo -n "${HM_HMIP_VERSION}" > /var/hmip_firmware_version
echo -n "${HM_HMIP_ADDRESS}" > /var/hmip_address
echo -n "${HM_HMIP_SGTIN}" > /var/hmip_board_sgtin

cat > /var/ids << EOF
BidCoS-Address=${DEBMATIC_ADDRESS}
SerialNumber=${DEBMATIC_SERIAL}
EOF

if [ ! -e /etc/config/ids ]; then
  cp /var/ids /etc/config/ids
else
  if [ `grep -c "BidCoS-Address \?= \?[a-zA-Z0-9]\+" /etc/config/ids` -eq 0 ]; then
    cp /var/ids /etc/config/ids
  fi
fi

cat > /var/hm_mode << EOF
HM_HOST='debmatic'
HM_MODE='NORMAL'
HM_LED_GREEN=''
HM_LED_GREEN_MODE1='none'
HM_LED_GREEN_MODE2='none'
HM_LED_RED=''
HM_LED_RED_MODE1='none'
HM_LED_RED_MODE2='none'
HM_LED_YELLOW=''
HM_LED_YELLOW_MODE1='none'
HM_LED_YELLOW_MODE2='none'
HM_HOST_GPIO_UART='$HM_HOST_GPIO_UART'
HM_HOST_GPIO_RESET=''
HM_RTC=''
HM_HMIP_DEV='$HM_HMIP_DEV'
HM_HMIP_DEVNODE='$HM_HMIP_DEVNODE'
HM_HMIP_SERIAL='$HM_HMIP_SERIAL'
HM_HMIP_VERSION='$HM_HMIP_VERSION'
HM_HMIP_SGTIN='$HM_HMIP_SGTIN'
HM_HMIP_ADDRESS='$HM_HMIP_ADDRESS'
HM_HMIP_ADDRESS_ACTIVE='$HM_HMIP_ADDRESS'
HM_HMIP_DEVTYPE='$HM_HMIP_DEVTYPE'
HM_HMRF_DEV='$HM_HMRF_DEV'
HM_HMRF_DEVNODE='$HM_HMRF_DEVNODE'
HM_HMRF_SERIAL='$HM_HMRF_SERIAL'
HM_HMRF_VERSION='$HM_HMRF_VERSION'
HM_HMRF_ADDRESS='$HM_HMRF_ADDRESS'
HM_HMRF_ADDRESS_ACTIVE='$HM_HMRF_ADDRESS'
HM_HMRF_DEVTYPE='$HM_HMRF_DEVTYPE'
EOF

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

if [ -e /proc/sys/abi/cp15_barrier ]; then
  echo 2 > /proc/sys/abi/cp15_barrier
fi
if [ -e /proc/sys/abi/setend ]; then
  echo 2 > /proc/sys/abi/setend
fi

DEBMATIC_VERSION=$(dpkg -s debmatic | grep '^Version: ' | cut -d' ' -f2)

if [ -e /etc/os-release ]; then
  OS_ID=$(grep '^ID=' /etc/os-release | cut -d '=' -f2)
  VERSION_CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d '=' -f2)
  if [ -z "$VERSION_CODENAME" ]; then
    VERSION_CODENAME=$(grep '^VERSION_ID=' /etc/os-release | cut -d '=' -f2)
  fi
else
  OS_ID=unknown
  VERSION_CODENAME=unknown
fi

OS_ARCH=$(uname -m)

if [ -e /etc/armbian-release ]; then
  BOARD_TYPE=$(grep '^BOARD=' /etc/armbian-release | cut -d '=' -f2)
  ARMBIAN_CODENAME=$(grep '^DISTRIBUTION_CODENAME=' /etc/armbian-release | cut -d '=' -f2)
  if [ -n "$ARMBIAN_CODENAME" ]; then
    VERSION_CODENAME=$ARMBIAN_CODENAME
  fi
  OS_ID=armbian
elif [ -e /sys/firmware/devicetree/base/compatible ]; then
  BOARD_TYPE=$(strings /sys/firmware/devicetree/base/compatible | tr '\n' ':' | tr ',' '_')
else
  BOARD_TYPE=unknown
fi

OS_RELEASE=${OS_ID}_${VERSION_CODENAME}

wget -O /dev/null -q --timeout=5 "https://www.debmatic.de/latestVersion?version=$DEBMATIC_VERSION&serial=$BOARD_SERIAL&os=$OS_RELEASE&arch=$OS_ARCH&board=$BOARD_TYPE" || true
