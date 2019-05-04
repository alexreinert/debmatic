#!/bin/bash

if [ ${IFACE} = "lo" ] || [ ${IFACE} = "lxcbr0" ]; then
  exit 0
fi

mkdir -p /var/status

if [[ ! -L "/sys/class/net/${IFACE}" ]]; then
  exit 0
fi

for i in {1..6}
do
  if [ "$(cat /sys/class/net/${IFACE}/carrier)" == "0" ]; then
    sleep 2
  fi
done

if [ "$(cat /sys/class/net/${IFACE}/carrier)" == "0" ]; then
  exit 0
fi

touch /var/status/hasLink

for i in {1..6}
do
  if [ "$(ip -o -4 addr show ${IFACE} | wc -l)" == "0" ]; then
    sleep 2
  fi
done

if [ "$(ip -o -4 addr show ${IFACE} | wc -l)" == "0" ]; then
  exit 0
fi

touch /var/status/hasIP

wget -q --spider http://google.com/
if [[ $? -eq 0 ]]; then
  touch /var/status/hasInternet
elif ping -q -W 5 -c 1 google.com >/dev/null 2>/dev/null; then
  touch /var/status/hasInternet
fi

if [ `route -4 -n | grep -E "^0.0.0.0" | head -1 | awk '{print $8}'` == $IFACE ]; then
  ADDR=`ip -o -4 addr show $IFACE | awk '{print $4}'`
  IP=`ipcalc -n -b $ADDR | grep "Address:" | awk '{print $2}'`
  NETMASK=`ipcalc -n -b $ADDR | grep "Netmask:" | awk '{print $2}'`
  GATEWAY=`route -4 -n | grep -E "^0.0.0.0" | head -1 | awk '{print $2}'`

  eq3configcmd netconfigcmd -i "$IP" -g "$GATEWAY" -n "$NETMASK" -d1 "" -d2 ""
fi

