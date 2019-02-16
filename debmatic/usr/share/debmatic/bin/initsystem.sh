#!/bin/bash

if [ -e /etc/default/debmatic ]; then
  . /etc/default/debmatic
fi

mkdir -p /var/status

rm -f /var/status/startupFinished

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

rm -f /var/status/debmatic_*

\cp -f /etc/config_templates/InterfacesList.xml /etc/config/
if [ -z "$HM_HMRF_DEV" ]; then
  touch /var/status/debmatic_avoid_multimacd

  if [ `egrep -c '^Type = (HMLGW2|Lan Interface)' /etc/config/rfd.conf` == 0 ]; then
    touch /var/status/debmatic_avoid_rfd
  fi
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

echo "${HM_HMRF_SERIAL}" > /var/board_serial
echo "${HM_HMRF_VERSION}" > /var/rf_firmware_version
echo "${HM_HMRF_ADDRESS}" > /var/rf_address
echo "${HM_HMIP_SERIAL}" > /var/hmip_board_serial
echo "${HM_HMIP_VERSION}" > /var/hmip_firmware_version
echo "${HM_HMIP_ADDRESS}" > /var/hmip_address
echo "${HM_HMIP_SGTIN}" > /var/board_sgtin
echo "${HM_HMIP_SGTIN}" > /var/hmip_board_sgtin
cat > /var/ids << EOF
BidCoS-Address=$HM_HMRF_ADDRESS
SerialNumber=$HM_HMRF_SERIAL
EOF

if [ ! -e /etc/config/ids ]; then
  cp /var/ids /etc/config/ids
fi

if [ ! -e /etc/config/crypttool.cfg ]; then
  touch /etc/config/crypttool.cfg
fi

sed -i 's/^AccessFile/#AccessFile/' /etc/config/rfd.conf || true
sed -i 's/^ResetFile/#ResetFile/' /etc/config/rfd.conf || true

mkdir -p /etc/config/hs485d

# MigrateSecuritySettings 3.41.x
sed -i -e 's/\s*Listen\s*Port\s*=\s*2001/Listen Port = 32001/' /etc/config/rfd.conf
if [ -e /etc/config/hs485d.conf ]; then
  sed -i -e 's/\s*Listen\s*Port\s*=\s*2000/Listen Port = 32000/' /etc/config/hs485d.conf
fi
sed -i -e 's/:2001/:32001/' -e 's/:9292/:39292/' -e 's/:2010/:32010/' /etc/config/InterfacesList.xml

rm -f /var/hasInternet
rm -f /var/hasIP
rm -f /var/hasLink

IFACE=`route -4 -n | grep -E "^0.0.0.0" | head -1 | awk '{print $8}'`
for i in {1..6}
do
  if [ "$(cat /sys/class/net/${IFACE}/carrier)" == "1" ]; then
    touch /var/hasLink
    break
  else
    sleep 2
  fi
done

for i in {1..6}
do
  if [ "$(ip -o -4 addr show ${IFACE} | wc -l)" == "0" ]; then
    sleep 2
  else
    touch /var/hasIP
    break
  fi
done

wget -q --spider http://google.com/
if [[ $? -eq 0 ]]; then
  touch /var/status/hasInternet
elif ping -q -W 5 -c 1 google.com >/dev/null 2>/dev/null; then
  touch /var/status/hasInternet
fi

ADDR=`ip -o -4 addr show $IFACE | awk '{print $4}'`
IP=`ipcalc -n -b $ADDR | grep "Address:" | awk '{print $2}'`
NETMASK=`ipcalc -n -b $ADDR | grep "Netmask:" | awk '{print $2}'`
GATEWAY=`route -4 -n | grep -E "^0.0.0.0" | head -1 | awk '{print $2}'`

eq3configcmd netconfigcmd -i "$IP" -g "$GATEWAY" -n "$NETMASK" -d1 "" -d2 ""

mkdir -p /media/usb0/measurement
touch /var/status/hasUSB
touch /var/status/hasSD
touch /var/status/USBinitialised
touch /var/status/SDinitialised

