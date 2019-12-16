#!/bin/bash

if [ -e /etc/config/rfd.conf ] && [ `egrep -c '^Type = HMLGW2' /etc/config/rfd.conf` != 0 ]; then
  /bin/eq3configcmd update-coprocessor -lgw -u -rfdconf /etc/config/rfd.conf -l 1
  /bin/eq3configcmd update-lgw-firmware -m /firmware/fwmap -c /etc/config/rfd.conf -l 1
fi

if [ -e /etc/config/hs485d.conf ] && [ `egrep -c '^Type = HMWLGW' /etc/config/hs485d.conf` != 0 ]; then
  /bin/eq3configcmd update-lgw-firmware -m /firmware/fwmap -c /etc/config/hs485d.conf -l 1
fi
