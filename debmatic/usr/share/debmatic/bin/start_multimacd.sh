#!/bin/bash
sed "s|^Coprocessor Device Path = .*$|Coprocessor Device Path = ${HM_HOST_GPIO_UART}|" /etc/multimacd.conf > /var/run/multimacd.conf
/bin/multimacd -l 5 -f /var/run/multimacd.conf -d
/usr/share/debmatic/bin/create_pid_file /var/run/multimacd.pid /bin/multimacd

for i in {1..10}; do
  sleep 2

  if [ -e /var/status/multimacd.status ] && [ "`cat /var/status/multimacd.status`" == "`pidof /bin/multimacd`" ]; then
    break
  fi
done

