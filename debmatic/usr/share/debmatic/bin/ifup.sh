#!/bin/bash

if [ ${IFACE} = "lo" ] || [ ${IFACE} = "lxcbr0" ]; then
  exit 0
fi

mkdir -p /var/status

if [[ ! -L "/sys/class/net/${IFACE}" ]]; then
  exit 0
fi

if [ "$(cat /sys/class/net/${IFACE}/carrier)" != "1" ]; then
  exit 0
fi

touch /var/status/hasLink

if [ "$(ip -o -4 addr show ${IFACE} | wc -l)" == "0" ]; then
  exit 0
fi

touch /var/status/hasIP

if [ `route -4 -n | grep -E "^0.0.0.0" | head -1 | awk '{print $8}'` == $IFACE ]; then
  wget -q --spider http://google.com/
  if [[ $? -eq 0 ]]; then
    touch /var/status/hasInternet
  elif ping -q -W 5 -c 1 google.com >/dev/null 2>/dev/null; then
    touch /var/status/hasInternet
  else
    exit 0
  fi

  ADDR=`ip -o -4 addr show $IFACE | awk '{print $4}'`
  IP=`ipcalc -n -b $ADDR | grep "Address:" | awk '{print $2}'`
  NETMASK=`ipcalc -n -b $ADDR | grep "Netmask:" | awk '{print $2}'`
  GATEWAY=`route -4 -n | grep -E "^0.0.0.0" | head -1 | awk '{print $2}'`

  eq3configcmd netconfigcmd -i "$IP" -g "$GATEWAY" -n "$NETMASK" -d1 "" -d2 ""
fi

