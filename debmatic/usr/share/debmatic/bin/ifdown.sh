#!/bin/bash

if [ ${IFACE} = "lo" ] || [ ${IFACE} = "lxcbr0" ]; then
  exit 0
fi

mkdir -p /var/status

rm -f /var/status/hasLink
rm -f /var/status/hasIP
rm -f /var/status/hasInternet
rm -f /var/status/hasNTP

for IF in `ls /sys/class/net/`; do
  if [ "$IF" != "$IFACE" ]; then
    IFACE=$IF /usr/share/debmatic/bin/ifup.sh
    if [ -e /var/status/hasInternet ]; then
      break
    fi
  fi
done

exit 0
