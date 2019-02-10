#!/bin/bash
/bin/rfd -l $LOGLEVEL_RFD -f /etc/config/rfd.conf -d
/usr/share/debmatic/bin/create_pid_file /var/run/rfd.pid /bin/rfd

for i in {1..60}; do
  sleep 2

  if [ -e /var/status/rfd.status ] && [ "`cat /var/status/rfd.status`" == "`pidof /bin/rfd`" ]; then
    break
  fi
done

